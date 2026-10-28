import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../core/formatters.dart';
import '../../core/models/operation.dart';
import '../history/history_providers.dart';
import '../market/market_providers.dart';

/// Écran Formulaire pour l'enregistrement ou la modification d'une opération financière
class OperationFormScreen extends ConsumerStatefulWidget {
  final String? operationId; // Si fourni -> mode modification
  final String? initialStockCode; // Pré-remplissage via fiche titre
  final String? initialType; // 'achat', 'vente', 'depot', 'retrait'

  const OperationFormScreen({
    super.key,
    this.operationId,
    this.initialStockCode,
    this.initialType,
  });

  @override
  ConsumerState<OperationFormScreen> createState() => _OperationFormScreenState();
}

class _OperationFormScreenState extends ConsumerState<OperationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late OperationType _selectedType;
  String? _selectedStockCode;
  late DateTime _selectedDate;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _feesController = TextEditingController(text: '0');
  final TextEditingController _cashAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedType = _parseInitialType(widget.initialType);
    _selectedStockCode = widget.initialStockCode;
  }

  OperationType _parseInitialType(String? typeStr) {
    if (typeStr == null) return OperationType.achat;
    switch (typeStr.toLowerCase()) {
      case 'vente':
        return OperationType.vente;
      case 'depot':
        return OperationType.depot;
      case 'retrait':
        return OperationType.retrait;
      case 'achat':
      default:
        return OperationType.achat;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _initFormData();
      _isInit = true;
    }
  }

  void _initFormData() {
    // Si modification d'une opération existante
    if (widget.operationId != null) {
      final op = ref.read(operationByIdProvider(widget.operationId!));
      if (op != null) {
        _selectedType = op.type;
        _selectedStockCode = op.stockCode;
        _selectedDate = op.date;
        if (op.quantity != null) _quantityController.text = op.quantity.toString();
        if (op.unitPrice != null) _unitPriceController.text = op.unitPrice.toString();
        _feesController.text = op.fees.toString();
        if (op.cashAmount != null) _cashAmountController.text = op.cashAmount.toString();
        if (op.notes != null) _notesController.text = op.notes!;
        return;
      }
    }

    // Si création avec titre pré-sélectionné
    if (_selectedStockCode != null) {
      _onStockChanged(_selectedStockCode);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _feesController.dispose();
    _cashAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onStockChanged(String? code) {
    if (code == null) return;
    setState(() {
      _selectedStockCode = code;
      final stock = ref.read(stockByCodeProvider(code));
      if (stock != null) {
        // Pré-remplir automatiquement le cours avec le dernier cours du marché
        _unitPriceController.text = stock.currentPrice.toString();
        _recalculateEstimatedFees();
      }
    });
  }

  void _recalculateEstimatedFees() {
    final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    final price = int.tryParse(_unitPriceController.text.trim()) ?? 0;
    if (qty > 0 && price > 0) {
      final gross = qty * price;
      // Frais SGI standards estimés à ~1.18%
      final estimatedFees = (gross * (AppConstants.defaultFeeRatePercent / 100)).round();
      _feesController.text = estimatedFees.toString();
    }
  }

  int get _calculatedGrossAmount {
    if (_selectedType.isStockOperation) {
      final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
      final price = int.tryParse(_unitPriceController.text.trim()) ?? 0;
      return qty * price;
    } else {
      return int.tryParse(_cashAmountController.text.trim()) ?? 0;
    }
  }

  int get _calculatedNetAmount {
    final gross = _calculatedGrossAmount;
    final fees = int.tryParse(_feesController.text.trim()) ?? 0;

    switch (_selectedType) {
      case OperationType.achat:
        return gross + fees;
      case OperationType.vente:
        return gross - fees;
      case OperationType.depot:
        return gross - fees;
      case OperationType.retrait:
        return gross + fees;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Date de l\'opération',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final fees = int.tryParse(_feesController.text.trim()) ?? 0;
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    if (_selectedType.isStockOperation) {
      if (_selectedStockCode == null) {
        context.showAppSnackBar('Veuillez sélectionner un titre BRVM', isError: true);
        return;
      }
      final qty = int.parse(_quantityController.text.trim());
      final price = int.parse(_unitPriceController.text.trim());
      final stock = ref.read(stockByCodeProvider(_selectedStockCode!));
      final stockName = stock?.name ?? _selectedStockCode!;

      final operation = Operation(
        id: widget.operationId ?? 'op-${DateTime.now().millisecondsSinceEpoch}',
        type: _selectedType,
        stockCode: _selectedStockCode,
        stockName: stockName,
        quantity: qty,
        unitPrice: price,
        fees: fees,
        date: _selectedDate,
        notes: notes,
      );

      if (widget.operationId != null) {
        ref.read(operationsProvider.notifier).updateOperation(operation);
        context.showAppSnackBar('Opération modifiée avec succès', isSuccess: true);
      } else {
        ref.read(operationsProvider.notifier).addOperation(operation);
        context.showAppSnackBar('Opération enregistrée avec succès', isSuccess: true);
      }
    } else {
      final cash = int.parse(_cashAmountController.text.trim());
      final operation = Operation(
        id: widget.operationId ?? 'op-${DateTime.now().millisecondsSinceEpoch}',
        type: _selectedType,
        cashAmount: cash,
        fees: fees,
        date: _selectedDate,
        notes: notes,
      );

      if (widget.operationId != null) {
        ref.read(operationsProvider.notifier).updateOperation(operation);
        context.showAppSnackBar('Opération d\'espèces modifiée avec succès', isSuccess: true);
      } else {
        ref.read(operationsProvider.notifier).addOperation(operation);
        context.showAppSnackBar('Opération d\'espèces enregistrée avec succès', isSuccess: true);
      }
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final stocks = ref.watch(marketStocksProvider);
    final isEditing = widget.operationId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'opération' : 'Nouvelle opération'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélecteur de type d'opération (Achat, Vente, Dépôt, Retrait)
              const Text(
                'Type d\'opération',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              SegmentedButton<OperationType>(
                segments: const [
                  ButtonSegment(
                    value: OperationType.achat,
                    label: Text('Achat'),
                    icon: Icon(Icons.add_shopping_cart, size: 18),
                  ),
                  ButtonSegment(
                    value: OperationType.vente,
                    label: Text('Vente'),
                    icon: Icon(Icons.sell_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: OperationType.depot,
                    label: Text('Dépôt'),
                    icon: Icon(Icons.arrow_downward, size: 18),
                  ),
                  ButtonSegment(
                    value: OperationType.retrait,
                    label: Text('Retrait'),
                    icon: Icon(Icons.arrow_upward, size: 18),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Si Achat ou Vente -> Sélecteur d'action BRVM
              if (_selectedType.isStockOperation) ...[
                const Text(
                  'Titre BRVM',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  initialValue: _selectedStockCode,
                  isExpanded: true,
                  hint: const Text('Choisir une action cotée...'),
                  items: stocks.map((stock) {
                    return DropdownMenuItem<String>(
                      value: stock.code,
                      child: Text(
                        '${stock.code} - ${stock.name} (${formatFCFA(stock.currentPrice)})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15),
                      ),
                    );
                  }).toList(),
                  onChanged: _onStockChanged,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Veuillez choisir une action';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Ligne Quantité & Prix unitaire
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quantité
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quantité',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              hintText: 'Ex: 100',
                              suffixText: 'titres',
                            ),
                            onChanged: (_) {
                              setState(() {
                                _recalculateEstimatedFees();
                              });
                            },
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Requis';
                              }
                              final q = int.tryParse(val.trim());
                              if (q == null || q <= 0) {
                                return '> 0';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Prix unitaire (cours)
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cours unitaire',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _unitPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              hintText: 'Prix',
                              suffixText: 'FCFA',
                            ),
                            onChanged: (_) {
                              setState(() {
                                _recalculateEstimatedFees();
                              });
                            },
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Requis';
                              }
                              final p = int.tryParse(val.trim());
                              if (p == null || p <= 0) {
                                return '> 0';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Si Dépôt ou Retrait -> Montant espèces
                const Text(
                  'Montant en espèces',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _cashAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ex: 1 000 000',
                    suffixText: 'FCFA',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Veuillez saisir un montant';
                    }
                    final a = int.tryParse(val.trim());
                    if (a == null || a <= 0) {
                      return 'Le montant doit être supérieur à 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Frais d'intermédiation / de courtage SGI
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Frais d\'opération',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_selectedType.isStockOperation)
                              InkWell(
                                onTap: () {
                                  _recalculateEstimatedFees();
                                  setState(() {});
                                },
                                child: const Text(
                                  'Taux SGI (~1.18%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _feesController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            hintText: '0',
                            suffixText: 'FCFA',
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Requis (0 si aucun)';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date de l'opération
              const Text(
                'Date d\'exécution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate.toLongDate(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes / Commentaire optionnel
              const Text(
                'Note ou référence (optionnel)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Achat SGI BOA Capital, avis d\'opé #4592',
                ),
              ),
              const SizedBox(height: 24),

              // Encadré Récapitulatif financier Net
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Montant brut',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        Text(
                          formatFCFA(_calculatedGrossAmount),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Frais & taxes SGI',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        Text(
                          formatFCFA(int.tryParse(_feesController.text.trim()) ?? 0),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedType == OperationType.achat || _selectedType == OperationType.retrait
                              ? 'Total Net Débité'
                              : 'Total Net Crédité',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          formatFCFA(_calculatedNetAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bouton Enregistrer
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(
                  isEditing ? 'Mettre à jour l\'opération' : 'Enregistrer l\'opération',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
