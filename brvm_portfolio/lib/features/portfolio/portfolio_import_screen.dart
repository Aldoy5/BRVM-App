import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/operation.dart';
import '../../data/repositories/portfolio_statement_repository.dart';
import '../pdf_import/data/bici_portfolio_statement_parser.dart';
import '../pdf_import/data/pdf_line_builder.dart';
import '../pdf_import/data/pdf_text_extractor.dart';
import '../pdf_import/data/syncfusion_pdf_extractor.dart';
import '../market/market_providers.dart';
import 'portfolio_statement_providers.dart';
import '../history/history_providers.dart';
import 'portfolio_providers.dart';

class PortfolioImportScreen extends ConsumerStatefulWidget {
  const PortfolioImportScreen({super.key});
  @override
  ConsumerState<PortfolioImportScreen> createState() => _PortfolioImportScreenState();
}

class _EditableHolding {
  final BiciStatementHolding source;
  late final TextEditingController code = TextEditingController(text: source.code);
  late final TextEditingController quantity = TextEditingController(text: '${source.quantity}');
  late final TextEditingController cost = TextEditingController(text: '${source.costPrice}');
  _EditableHolding(this.source);
  void dispose() { code.dispose(); quantity.dispose(); cost.dispose(); }
}

class _PortfolioImportScreenState extends ConsumerState<PortfolioImportScreen> {
  List<_EditableHolding> _rows = [];
  DateTime? _statementDate;
  bool _merge = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() { for (final row in _rows) { row.dispose(); } super.dispose(); }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result.isEmpty) return;
      final bytes = await result.first.readAsBytes();
      final extractor = SyncfusionPdfTextExtractor();
      final words = await extractor.extractWords(bytes);
      final lines = words.isNotEmpty ? buildLines(words) : (await extractor.extractFullText(bytes))
          .split(RegExp(r'[\r\n]+')).where((s) => s.trim().isNotEmpty)
          .map((s) => PdfLine(s.trim(), 0, const [])).toList();
      final statement = BiciPortfolioStatementParser.parse(lines);
      if (statement == null) {
        setState(() => _error = 'Relevé de compte titres BICI Bourse non reconnu ou aucune ligne lisible.');
        return;
      }
      for (final row in _rows) { row.dispose(); }
      setState(() {
        _rows = statement.holdings.map(_EditableHolding.new).toList();
        _statementDate = statement.date;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Lecture du PDF impossible : $e');
    }
  }

  List<BiciStatementHolding>? _validatedRows() {
    final rows = <BiciStatementHolding>[];
    final known = ref.read(marketStocksProvider).map((s) => s.code.toUpperCase()).toSet();
    for (final row in _rows) {
      final code = row.code.text.trim().toUpperCase();
      final quantity = int.tryParse(row.quantity.text.trim());
      final cost = int.tryParse(row.cost.text.trim());
      if (!known.contains(code) || quantity == null || quantity <= 0 || cost == null || cost <= 0) return null;
      rows.add(row.source.copyWith(code: code, quantity: quantity, costPrice: cost));
    }
    return rows.isEmpty ? null : rows;
  }

  Future<void> _save() async {
    final rows = _validatedRows();
    if (rows == null || _statementDate == null) {
      setState(() => _error = 'Vérifiez les codes connus, les quantités et les prix de revient (valeurs positives).');
      return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirmer la mise à jour'),
      content: Text(_merge
          ? 'Les ${rows.length} ligne(s) du relevé remplaceront les titres de même code. Les autres positions seront conservées, ainsi que votre historique.'
          : 'Le portefeuille affichera exactement les ${rows.length} ligne(s) du relevé. L’historique des opérations restera consultable.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Revoir')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer'))],
    ));
    if (confirmed != true) return;
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(portfolioStatementProvider.notifier).save(SavedPortfolioStatement(
        date: _statementDate!, merge: _merge, holdings: rows));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Portefeuille mis à jour.')));
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Enregistrement impossible : $e');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final operations = ref.watch(operationsProvider);
    final hasExistingOperations = operations.any((op) => op.type.isStockOperation) ||
        ref.watch(portfolioPositionsProvider).isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Importer un relevé')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Import du relevé de compte titres BICI Bourse. Les données extraites restent à vérifier avant enregistrement.'),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: _busy ? null : _pickPdf, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Choisir un relevé PDF')),
        if (_statementDate != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text('Date du relevé : ${_statementDate!.day.toString().padLeft(2, '0')}/${_statementDate!.month.toString().padLeft(2, '0')}/${_statementDate!.year} • ${_rows.length} titres')),
        if (_rows.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final row in _rows) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text('${row.source.name} • ISIN ${row.source.isin}', style: const TextStyle(fontWeight: FontWeight.w600))), IconButton(tooltip: 'Retirer cette ligne', onPressed: () => setState(() { _rows.remove(row); row.dispose(); }), icon: const Icon(Icons.delete_outline))]),
            Row(children: [Expanded(child: TextField(controller: row.code, decoration: const InputDecoration(labelText: 'Code'))), const SizedBox(width: 8), Expanded(child: TextField(controller: row.quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantité'))), const SizedBox(width: 8), Expanded(child: TextField(controller: row.cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PRU FCFA')))]),
            Text('Cours relevé : ${row.source.marketPrice} FCFA'),
          ]))),
          if (hasExistingOperations) ...[
            const SizedBox(height: 8),
            const Text('Comment appliquer ce relevé ?', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<bool>(value: false, groupValue: _merge, onChanged: (v) => setState(() => _merge = v!), title: const Text('Remplacer les positions'), subtitle: const Text('Le portefeuille reprend exactement les titres du relevé. L’historique reste consultable.'), contentPadding: EdgeInsets.zero),
            RadioListTile<bool>(value: true, groupValue: _merge, onChanged: (v) => setState(() => _merge = v!), title: const Text('Ajuster les positions'), subtitle: const Text('Les titres du relevé sont actualisés ; les autres positions sont conservées.'), contentPadding: EdgeInsets.zero),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _busy ? null : _save, icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check), label: const Text('Valider et mettre à jour')),
        ],
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      ])),
    );
  }
}
