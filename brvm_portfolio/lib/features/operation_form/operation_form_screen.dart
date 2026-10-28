import 'package:file_picker/file_picker.dart';
import '../../core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  ConsumerState<OperationFormScreen> createState() =>
      _OperationFormScreenState();
}

class _OperationFormScreenState extends ConsumerState<OperationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late OperationType _selectedType;
  String? _selectedStockCode;
  late DateTime _selectedDate;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _feesController = TextEditingController(
    text: '0',
  );
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
    if (widget.operationId != null) {
      final op = ref.read(operationByIdProvider(widget.operationId!));
      if (op != null) {
        _selectedType = op.type;
        _selectedStockCode = op.stockCode;
        _selectedDate = op.date;
        if (op.quantity != null)
          _quantityController.text = op.quantity.toString();
        if (op.unitPrice != null)
          _unitPriceController.text = op.unitPrice.toString();
        _feesController.text = op.fees.toString();
        if (op.cashAmount != null)
          _cashAmountController.text = op.cashAmount.toString();
        if (op.notes != null) _notesController.text = op.notes!;
        return;
      }
    }

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
      final estimatedFees = (gross * (AppConstants.defaultFeeRatePercent / 100))
          .round();
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

  Future<void> _importPdf() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (files.isNotEmpty) {
        final file = files.first;
        if (!mounted) return;
        context.showAppSnackBar(
          'Avis d\'opéré importé : ${file.name}',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(
        'Erreur lors de la sélection du fichier PDF',
        isError: true,
      );
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final fees = int.tryParse(_feesController.text.trim()) ?? 0;
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    if (_selectedType.isStockOperation) {
      if (_selectedStockCode == null) {
        context.showAppSnackBar(
          'Veuillez sélectionner un titre BRVM',
          isError: true,
        );
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
        context.showAppSnackBar(
          'Opération modifiée avec succès',
          isSuccess: true,
        );
      } else {
        ref.read(operationsProvider.notifier).addOperation(operation);
        context.showAppSnackBar(
          'Opération enregistrée avec succès',
          isSuccess: true,
        );
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
        context.showAppSnackBar(
          'Opération d\'espèces modifiée avec succès',
          isSuccess: true,
        );
      } else {
        ref.read(operationsProvider.notifier).addOperation(operation);
        context.showAppSnackBar(
          'Opération d\'espèces enregistrée avec succès',
          isSuccess: true,
        );
      }
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final stocks = ref.watch(marketStocksProvider);
    final isEditing = widget.operationId != null;
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ResponsiveCenter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête : Titre + Bouton Fermer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? 'Modifier l\'opération'
                            : 'Nouvelle opération',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          child: Text(
                            'Fermer',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sélecteur de type d'opération (Achat, Vente, Dépôt, Retrait)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildTabItem(OperationType.achat, 'Achat'),
                        _buildTabItem(OperationType.vente, 'Vente'),
                        _buildTabItem(OperationType.depot, 'Dépôt'),
                        _buildTabItem(OperationType.retrait, 'Retrait'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Formulaire selon le type
                  if (_selectedType.isStockOperation) ...[
                    // Champ Titre
                    const Text(
                      'Titre',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedStockCode,
                      isExpanded: true,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      hint: const Text('Choisir un titre...'),
                      items: stocks.map((stock) {
                        return DropdownMenuItem<String>(
                          value: stock.code,
                          child: Text(
                            '${stock.code} · ${stock.name}',
                            overflow: TextOverflow.ellipsis,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quantité',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                                onChanged: (_) {
                                  setState(() {
                                    _recalculateEstimatedFees();
                                  });
                                },
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty)
                                    return 'Requis';
                                  final q = int.tryParse(val.trim());
                                  if (q == null || q <= 0) return '> 0';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Prix unitaire (FCFA)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _unitPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                                onChanged: (_) {
                                  setState(() {
                                    _recalculateEstimatedFees();
                                  });
                                },
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty)
                                    return 'Requis';
                                  final p = int.tryParse(val.trim());
                                  if (p == null || p <= 0) return '> 0';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ligne Frais & Date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Frais (FCFA)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _feesController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty)
                                    return 'Requis';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    dateFormatter.format(_selectedDate),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Si Dépôt ou Retrait -> Montant espèces
                    const Text(
                      'Montant en espèces (FCFA)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _cashAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Ex: 500 000',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Veuillez saisir un montant';
                        final a = int.tryParse(val.trim());
                        if (a == null || a <= 0) return '> 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ligne Frais & Date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Frais (FCFA)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _feesController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    dateFormatter.format(_selectedDate),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Encadré Total estimé
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total estimé',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          formatFCFA(_calculatedNetAmount),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Bouton Enregistrer (Vert plein)
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bouton Importer un PDF d'avis d'opéré
                  OutlinedButton(
                    onPressed: _importPdf,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(
                        color: AppColors.textPrimary,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Importer un PDF d’avis d’opéré',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(OperationType type, String label) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _recalculateEstimatedFees();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
