import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class Vision {
  Vision._privateConstructor();

  static final Vision instance = Vision._privateConstructor();

  FaceDetector faceDetector(FaceDetectorOptions options) {
    return FaceDetector(options: options);
  }
}
