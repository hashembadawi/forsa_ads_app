import 'dart:convert';
import 'package:image_picker/image_picker.dart';

/// Minimal helper that returns a base64-encoded string for the provided file.
///
/// This intentionally does NOT perform compression or watermarking. It keeps
/// behavior simple and avoids bringing plugin dependencies into the project.
Future<String> compressXFileToBase64(
  XFile file, {
  int quality = 80,
  int maxWidth = 1280,
  String? watermarkText,
}) async {
  final bytes = await file.readAsBytes();
  return base64Encode(bytes);
}
