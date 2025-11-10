import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Compress an [XFile] selected by the user and return a base64-encoded string.
///
/// - On mobile (Android/iOS) this uses native compression for speed and low UI jank.
/// - On web this falls back to returning the original bytes (no native compression).
Future<String> compressXFileToBase64(
  XFile file, {
  int quality = 80,
  int maxWidth = 1280,
  String? watermarkText,
}) async {
  // Web: plugin not available; return original bytes (caller may choose to do more).
  if (kIsWeb) {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  // If path is empty (rare), fallback to raw bytes.
  final inputPath = file.path;
  if (inputPath.isEmpty) {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  try {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      inputPath,
      targetPath,
      quality: quality,
      minWidth: maxWidth,
      keepExif: false,
      // Explicit format ensures consistent output
      format: CompressFormat.jpeg,
    );

    final usedFile = compressedFile ?? File(inputPath);
    var bytes = await usedFile.readAsBytes();

    // Apply watermark if requested (non-empty text)
    if (watermarkText != null && watermarkText.isNotEmpty) {
      try {
        // Apply watermark using Flutter's Canvas/TextPainter (works cross-platform)
        bytes = await _applyWatermarkUi(bytes, watermarkText,
            maxWidth: maxWidth, quality: quality, opacity: 0.25, margin: 12);
      } catch (_) {
        // fallback to un-watermarked bytes on failure
      }
    }

    return base64Encode(bytes);
  } catch (e) {
    // On any error, fallback to original bytes
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }
}

Future<Uint8List> _applyWatermarkUi(
  Uint8List imageBytes,
  String watermark, {
  int maxWidth = 1280,
  int quality = 80,
  double opacity = 0.25,
  int margin = 12,
}) async {
  // Decode image to ui.Image
  final codec = await ui.instantiateImageCodec(imageBytes);
  final frame = await codec.getNextFrame();
  final srcImage = frame.image;

  // Optionally resize by drawing to a smaller canvas if needed
  final int targetWidth = srcImage.width > maxWidth ? maxWidth : srcImage.width;
  final int targetHeight = ((srcImage.height * (targetWidth / srcImage.width))).round();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()));

  final paint = Paint();
  // Draw the source image scaled to target size
  final srcRect = Rect.fromLTWH(0, 0, srcImage.width.toDouble(), srcImage.height.toDouble());
  final dstRect = Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());
  canvas.drawImageRect(srcImage, srcRect, dstRect, paint);

  // Prepare text painter for watermark
  final fontSize = (targetWidth / 20).clamp(12, 72).toDouble();
  final textStyle = TextStyle(
    color: Colors.white,
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    shadows: [const Shadow(blurRadius: 2, color: Colors.black45, offset: Offset(0, 1))],
  );
  final textSpan = TextSpan(text: watermark, style: textStyle);
  final tp = TextPainter(text: textSpan, textDirection: TextDirection.rtl);
  tp.layout();

  final textWidth = tp.width;
  final textHeight = tp.height;
  final dx = dstRect.right - textWidth - margin;
  final dy = dstRect.bottom - textHeight - margin;

  // Draw semi-transparent background rectangle
  final bgPaint = Paint()..color = Colors.black.withOpacity(opacity);
  const double rectPad = 6.0;
  final rrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(dx - rectPad, dy - rectPad, textWidth + rectPad * 2, textHeight + rectPad * 2),
    const Radius.circular(6),
  );
  canvas.drawRRect(rrect, bgPaint);

  // Paint the text
  tp.paint(canvas, Offset(dx, dy));

  // End recording and convert to image bytes
  final picture = recorder.endRecording();
  final ui.Image finalImage = await picture.toImage(targetWidth, targetHeight);
  final pngByteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = pngByteData!.buffer.asUint8List();

  // Convert to JPEG bytes with flutter_image_compress to respect quality param
  try {
    final compressed = await FlutterImageCompress.compressWithList(
      pngBytes,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    return Uint8List.fromList(compressed);
  } catch (_) {
    return pngBytes;
  }
}
