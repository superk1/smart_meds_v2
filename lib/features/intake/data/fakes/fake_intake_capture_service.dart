import 'package:smart_meds_v2/features/intake/domain/entities/intake_capture_result.dart';

class FakeIntakeCaptureService {
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
      fallbackName: 'Medicamento Desconocido',
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
