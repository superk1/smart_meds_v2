import 'package:smart_meds_v2/features/intake/domain/entities/intake_capture_result.dart';

abstract class BarcodeCaptureService {
  Future<IntakeCaptureResult> scanBarcode();
}

abstract class ImageOcrCaptureService {
  Future<IntakeCaptureResult> captureFromImage();
}

abstract class ManualSearchService {
  Future<IntakeCaptureResult> searchByText(String query);
}
