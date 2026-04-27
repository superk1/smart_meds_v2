enum IntakeSource {
  barcode,
  manualSearch,
  unknown
}

class IntakeCaptureResult {
  final IntakeSource source;
  final String? catalogId;
  final String? fallbackName;
  final String? scannedCode;

  const IntakeCaptureResult({
    required this.source,
    this.catalogId,
    this.fallbackName,
    this.scannedCode,
  });

  bool get hasCatalogMatch => catalogId != null && catalogId!.isNotEmpty;
}
