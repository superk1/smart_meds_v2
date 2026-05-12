import 'package:smart_meds_v2/features/catalog/domain/constants/catalog_constants.dart';
import 'package:smart_meds_v2/features/intake/domain/entities/intake_capture_result.dart';
import 'package:smart_meds_v2/features/intake/domain/services/intake_capture_service.dart';

class FakeIntakeCaptureService implements BarcodeCaptureService, ImageOcrCaptureService, ManualSearchService {
  bool _forceNoMatch = false;

  void setForceNoMatch(bool value) => _forceNoMatch = value;

  @override
  Future<IntakeCaptureResult> scanBarcode() async {
    if (_forceNoMatch) return simulateBarcodeNoMatch();
    return simulateBarcodeMatch();
  }

  @override
  Future<IntakeCaptureResult> captureFromImage() async {
    // Simular OCR devolviendo algo conocido para pruebas
    return simulateManualSearchMatch('OCR Match');
  }

  @override
  Future<IntakeCaptureResult> searchByText(String query) async {
    return simulateManualSearchMatch(query);
  }

  /// Simula una captura por código de barras que resulta en una coincidencia exacta
  /// con un medicamento del catálogo fake.
  Future<IntakeCaptureResult> simulateBarcodeMatch() async {
    await Future.delayed(const Duration(seconds: 1)); // Simular latencia de cámara/red
    
    // Devolvemos cat_1 que en nuestro fake catalog es Paracetamol
    return const IntakeCaptureResult(
      source: IntakeSource.barcode,
      catalogId: 'cat_1',
      scannedCode: '7501234567891',
    );
  }

  /// Simula un escaneo que NO coincide con nada en el catálogo.
  Future<IntakeCaptureResult> simulateBarcodeNoMatch() async {
    await Future.delayed(const Duration(seconds: 1));
    
    return const IntakeCaptureResult(
      source: IntakeSource.barcode,
      fallbackName: CatalogConstants.unknownName,
      scannedCode: '9999999999999',
    );
  }

  /// Simula una búsqueda manual que coincide con el catálogo
  Future<IntakeCaptureResult> simulateManualSearchMatch(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Devolvemos cat_2 que en nuestro fake catalog es Ibuprofeno
    return const IntakeCaptureResult(
      source: IntakeSource.manualSearch,
      catalogId: 'cat_2', 
    );
  }
}
