import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
// Web download
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../../core/config/env.dart';
import '../../../core/services/export_service.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../theme/dashboard_theme.dart';
import '../models/export_models.dart';

class ExportsScreen extends ConsumerStatefulWidget {
  const ExportsScreen({super.key});

  @override
  ConsumerState<ExportsScreen> createState() =>
      _ExportsScreenState();
}

class _ExportsScreenState extends ConsumerState<ExportsScreen> {
  ExportDateRange _range = ExportDateRange.last30Days();
  final List<ExportHistoryItem> _history = [];
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTheme.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Export Center',
            subtitle: 'Ekspor data untuk analisis, arsip, atau pelaporan.',
          ),
          const SizedBox(height: 24),

          // Date range picker
          SectionCard(
            title: 'Rentang Waktu',
            child: Row(children: [
              ...[
                ('today', 'Hari Ini', ExportDateRange.today),
                ('yesterday', 'Kemarin', ExportDateRange.yesterday),
                ('7d', '7 Hari', ExportDateRange.last7Days),
                ('30d', '30 Hari', ExportDateRange.last30Days),
                ('all', 'Semua', ExportDateRange.allTime),
              ].map((p) {
                final isActive = _range.label == p.$2;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _range = p.$3()),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? DashboardTheme.primary : DashboardTheme.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isActive ? DashboardTheme.primary : DashboardTheme.border),
                      ),
                      child: Text(p.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? Colors.white : DashboardTheme.textSecondary)),
                    ),
                  ),
                );
              }),
            ]),
          ),
          const SizedBox(height: 16),

          // Export cards grid
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 1000 ? 4 : c.maxWidth > 600 ? 2 : 1;
            final w = (c.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ExportModule.values.map((module) {
                return SizedBox(width: w, child: _ExportCard(
                  module: module,
                  range: _range,
                  isLoading: _loading[module.name] == true,
                  error: _errors[module.name],
                  onExport: (format) => _runExport(module, format),
                ));
              }).toList(),
            );
          }),
          const SizedBox(height: 24),

          // Export history
          if (_history.isNotEmpty) ...[
            SectionCard(
              title: 'Riwayat Export',
              child: Column(children: [
                Row(children: const [
                  Expanded(child: _H('Nama File')),
                  SizedBox(width: 120, child: _H('Modul')),
                  SizedBox(width: 80, child: _H('Format')),
                  SizedBox(width: 80, child: _H('Records')),
                  SizedBox(width: 150, child: _H('Tanggal')),
                  SizedBox(width: 100, child: _H('Status')),
                ]),
                Divider(height: 1, color: DashboardTheme.border),
                ..._history.reversed.take(20).map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Expanded(child: Text(h.fileName, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                    SizedBox(width: 120, child: Text(h.module.label, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                    SizedBox(width: 80, child: Text(h.formatLabel, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                    SizedBox(width: 80, child: Text('${h.recordCount}', style: const TextStyle(fontSize: 12))),
                    SizedBox(width: 150, child: Text(h.formattedDate, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                    SizedBox(width: 100, child: StatusChip(
                      label: h.status == ExportStatus.completed ? 'Selesai' : 'Gagal',
                      color: h.status == ExportStatus.completed ? DashboardTheme.success : DashboardTheme.danger,
                    )),
                  ]),
                )),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runExport(ExportModule module, ExportFormat format) async {
    if (_loading[module.name] == true) return;

    setState(() {
      _loading[module.name] = true;
      _errors[module.name] = null;
    });

    try {
      final repo = ExportRepository(
        Supabase.instance.client,
        AppEnv.organizationId,
      );

      final rows = await repo.fetchData(module, _range);
      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(now);
      final ext = format == ExportFormat.excel ? 'xlsx' : 'csv';
      final fileName = '${module.name}_$dateStr.$ext';

      List<int> bytes;
      String mimeType;

      if (format == ExportFormat.csv) {
        final csv = CsvExporter.export(rows);
        bytes = utf8.encode(csv);
        mimeType = 'text/csv;charset=utf-8';
      } else {
        bytes = ExcelExporter.export(rows, module.label);
        mimeType = 'text/csv;charset=utf-8';
      }

      // Web download
      _downloadFile(bytes, fileName, mimeType);

      final historyItem = ExportHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        module: module,
        format: format,
        exportedAt: now,
        status: ExportStatus.completed,
        recordCount: rows.length,
      );

      setState(() {
        _history.add(historyItem);
        _loading[module.name] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export berhasil dibuat: $fileName (${rows.length} records)'),
            backgroundColor: DashboardTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading[module.name] = false;
        _errors[module.name] = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export gagal: $e'),
            backgroundColor: DashboardTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _downloadFile(List<int> bytes, String fileName, String mimeType) {
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}

// ---------------------------------------------------------------------------
// Export card
// ---------------------------------------------------------------------------

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.module,
    required this.range,
    required this.isLoading,
    required this.onExport,
    this.error,
  });

  final ExportModule module;
  final ExportDateRange range;
  final bool isLoading;
  final String? error;
  final void Function(ExportFormat) onExport;

  IconData get _icon => switch (module) {
        ExportModule.sales => Icons.receipt_long_rounded,
        ExportModule.products => Icons.inventory_2_rounded,
        ExportModule.restocks => Icons.shopping_bag_rounded,
        ExportModule.customers => Icons.people_rounded,
        ExportModule.kasbon => Icons.account_balance_wallet_rounded,
        ExportModule.inventory => Icons.warehouse_rounded,
        ExportModule.analyticsSummary => Icons.analytics_rounded,
        ExportModule.businessHealth => Icons.monitor_heart_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: DashboardTheme.primary.withAlpha(15), borderRadius: BorderRadius.circular(8)), child: Icon(_icon, size: 18, color: DashboardTheme.primary)),
          const SizedBox(width: 10),
          Expanded(child: Text(module.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        Text(module.description, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(range.label, style: TextStyle(fontSize: 11, color: DashboardTheme.textTertiary)),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text('Error: $error', style: TextStyle(fontSize: 11, color: DashboardTheme.danger), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 12),
        if (isLoading)
          const Center(child: SizedBox(height: 32, child: CircularProgressIndicator(strokeWidth: 2)))
        else
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => onExport(ExportFormat.csv),
              icon: const Icon(Icons.table_chart_rounded, size: 13),
              label: const Text('CSV'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
              ),
            )),
            const SizedBox(width: 6),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => onExport(ExportFormat.excel),
              icon: const Icon(Icons.grid_on_rounded, size: 13),
              label: const Text('Excel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
              ),
            )),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Coming Soon',
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 13),
                label: const Text('PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ]),
      ]),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DashboardTheme.textSecondary));
}
