import 'dart:convert';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/data/secure_storage.dart';
import '../../../core/data/storage_keys.dart';
import '../../../core/providers/core_providers.dart';

class PrinterSelectionState {
  const PrinterSelectionState({
    this.printers = const <Printer>[],
    this.selectedPrinter,
    this.isSaving = false,
    this.isPrinting = false,
    this.isRefreshing = false,
    this.error,
  });

  final List<Printer> printers;
  final Printer? selectedPrinter;
  final bool isSaving;
  final bool isPrinting;
  final bool isRefreshing;
  final String? error;

  bool get hasPrinters => printers.isNotEmpty;

  PrinterSelectionState copyWith({
    List<Printer>? printers,
    Printer? selectedPrinter,
    bool? isSaving,
    bool? isPrinting,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return PrinterSelectionState(
      printers: printers ?? this.printers,
      selectedPrinter:
          clearSelected ? null : (selectedPrinter ?? this.selectedPrinter),
      isSaving: isSaving ?? this.isSaving,
      isPrinting: isPrinting ?? this.isPrinting,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PrinterController extends AsyncNotifier<PrinterSelectionState> {
  SecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  FutureOr<PrinterSelectionState> build() async {
    return _loadPrinters();
  }

  Future<PrinterSelectionState> _loadPrinters() async {
    final saved = await _readSavedPrinter();
    final printers = await Printing.listPrinters();
    final selected = _matchPrinter(printers, saved);
    return PrinterSelectionState(
      printers: printers,
      selectedPrinter: selected,
    );
  }

  Future<void> refreshPrinters() async {
    final current = state.valueOrNull;
    if (current == null) {
      state = const AsyncValue.loading();
    } else {
      _updateState(
        (value) => value.copyWith(isRefreshing: true, clearError: true),
      );
    }

    try {
      final next = await _loadPrinters();
      state = AsyncValue.data(next);
    } catch (error, stackTrace) {
      if (current == null) {
        state = AsyncValue.error(error, stackTrace);
      } else {
        _updateState(
          (value) => value.copyWith(
            isRefreshing: false,
            error: error.toString(),
          ),
        );
      }
    }
  }

  Future<void> selectPrinter(Printer? printer) async {
    final current = state.valueOrNull;
    if (current == null || printer == null) {
      return;
    }

    _updateState(
      (value) => value.copyWith(isSaving: true, clearError: true),
    );

    try {
      final payload = jsonEncode({
        'name': printer.name,
        'url': printer.url,
      });
      await _storage.write(StorageKeys.selectedPrinter, payload);
      _updateState(
        (value) => value.copyWith(
          isSaving: false,
          selectedPrinter: printer,
          clearError: true,
        ),
      );
    } catch (error) {
      _updateState(
        (value) => value.copyWith(
          isSaving: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<bool> printTestReceipt() async {
    final current = state.valueOrNull;
    if (current == null) {
      return false;
    }

    final printer = current.selectedPrinter;
    if (printer == null) {
      _updateState(
        (value) => value.copyWith(
          error: 'Please select a printer before printing.',
        ),
      );
      return false;
    }

    _updateState(
      (value) => value.copyWith(isPrinting: true, clearError: true),
    );

    try {
      final document = pw.Document();
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll57,
          build: (context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: List.generate(5, (_) {
                  return pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('Alhamdullilah Yah We got it'),
                  );
                }),
              ),
            );
          },
        ),
      );

      final bytes = await document.save();
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => bytes,
      );

      _updateState(
        (value) => value.copyWith(isPrinting: false, clearError: true),
      );
      return true;
    } catch (error) {
      _updateState(
        (value) => value.copyWith(
          isPrinting: false,
          error: error.toString(),
        ),
      );
      return false;
    }
  }

  Future<_SavedPrinter?> _readSavedPrinter() async {
    final raw = await _storage.read(StorageKeys.selectedPrinter);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        return null;
      }
      final name = map['name']?.toString();
      final url = map['url']?.toString();
      if (name == null || name.isEmpty) {
        return null;
      }
      return _SavedPrinter(name: name, url: url);
    } catch (_) {
      return null;
    }
  }

  Printer? _matchPrinter(List<Printer> printers, _SavedPrinter? saved) {
    if (printers.isEmpty) {
      return null;
    }

    if (saved != null) {
      final byUrl = saved.url;
      if (byUrl != null && byUrl.isNotEmpty) {
        try {
          return printers.firstWhere((printer) => printer.url == byUrl);
        } catch (_) {}
      }

      try {
        return printers.firstWhere(
          (printer) =>
              printer.name.toLowerCase() == saved.name.toLowerCase(),
        );
      } catch (_) {
        // Ignore if not found.
      }
    }

    final defaults =
        printers.where((printer) => printer.isDefault == true).toList();
    if (defaults.isNotEmpty) {
      return defaults.first;
    }

    return printers.first;
  }

  void _updateState(
    PrinterSelectionState Function(PrinterSelectionState) updater,
  ) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncValue.data(updater(current));
  }
}

final printerControllerProvider = AsyncNotifierProvider<PrinterController,
    PrinterSelectionState>(PrinterController.new);

class _SavedPrinter {
  const _SavedPrinter({
    required this.name,
    this.url,
  });

  final String name;
  final String? url;
}
