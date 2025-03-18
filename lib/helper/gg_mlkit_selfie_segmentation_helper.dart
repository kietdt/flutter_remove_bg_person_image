import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart';

class GgMlkitSelfieSegmentationHelper {
  GgMlkitSelfieSegmentationHelper._();

  // Google ML Kit Selfie Segmentation for Android and iOS
  static final SelfieSegmenter _segmenter = SelfieSegmenter(
    mode: SegmenterMode.single,
    enableRawSizeMask: false,
  );

  static Future<Uint8List?> removeBackground(Uint8List avatarBinary) async {
    try {
      var dir = Directory.systemTemp.createTempSync();
      var tempFile =
          File("${dir.path}/${DateTime.now().millisecondsSinceEpoch}");
      tempFile.createSync();
      tempFile.writeAsBytesSync(avatarBinary);

      Uint8List? result = await removeBackgroundWithPerson(tempFile);

      dir.deleteSync(recursive: true);

      return Future.value(result);
    } catch (e) {
      log("Error: $e");
      return null;
    }
  }

  static Future<Uint8List> _getBytes(File file) async {
    return await file.readAsBytes();
  }

  static Future<Uint8List> removeBackgroundWithPerson(File file) async {
    final inputImage = InputImage.fromFile(file);

    final Uint8List bytes = await compute(_getBytes, file);

    final size = await decodeImageFromList(bytes);
    final Uint8List image = bytes;

    if (Platform.isAndroid || Platform.isIOS) {
      return await _mobileRemoveBackground(
        inputImage,
        orgImage: image,
        width: size.width,
        height: size.height,
      );
    } else {
      throw UnimplementedError("Unsupported platform");
    }
  }

  static Future<Uint8List> _mobileRemoveBackground(
    InputImage inputImage, {
    required Uint8List orgImage,
    required int width,
    required int height,
  }) async {
    try {
      final mask = await _segmenter.processImage(inputImage);

      final decodedImage = await removeBackgroundFromImage(
        image: decodeImage(orgImage)!,
        segmentationMask: mask!,
        width: width,
        height: height,
      );

      return Uint8List.fromList(encodePng(decodedImage));
    } catch (e) {
      throw Exception("Image Cannot Remove Background, e: $e");
    }
  }

  static Future<Image> removeBackgroundFromImage({
    required Image image,
    required SegmentationMask segmentationMask,
    required int width,
    required int height,
  }) async {
    return await compute(_removeBackgroundFromImage, {
      'image': image,
      'segmentationMask': segmentationMask,
      'width': width,
      'height': height
    });
  }

  // Helper method to remove background from an image in a separate isolate
  static Future<Image> _removeBackgroundFromImage(
      Map<String, dynamic> input) async {
    final Image image = input['image'];
    final int height = input['height'];
    final int width = input['width'];
    final SegmentationMask segmentationMask = input['segmentationMask'];

    double threshold =
        calculateOtsuThreshold(segmentationMask.confidences.toList());

    log('_removeBackgroundFromImage -> calculateOtsuThreshold: $threshold');

    var newImage = Image(
      width: width,
      height: height,
      backgroundColor: ColorRgba8(255, 255, 255, 0),
      numChannels: 4, // channel rgba
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int maskX = (x * segmentationMask.width ~/ image.width);
        int maskY = (y * segmentationMask.height ~/ image.height);
        int index = maskY * segmentationMask.width + maskX;
        double bgConfidence = segmentationMask.confidences[index];

        if (bgConfidence > threshold) {
          var pixel = image.getPixel(x, y);

          newImage.setPixel(x, y, pixel);
        }
      }
    }
    cutEdgesWithPadding(newImage);

    return gaussianBlur(newImage, radius: 1);
    // return newImage;
  }

  static void cutEdgesWithPadding(Image image, {int padding = 1}) {
    List<Offset> edges = [];
    int minCorners = 1;

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        var pixel = image.getPixel(x, y);
        if (pixel.a > 0) {
          int cornerCount = 0;

          if (image.getPixel(x - 1, y).a <= 0) {
            cornerCount++;
          }
          if (image.getPixel(x + 1, y).a <= 0) {
            cornerCount++;
          }
          if (image.getPixel(x, y - 1).a <= 0) {
            cornerCount++;
          }
          if (image.getPixel(x, y + 1).a <= 0) {
            cornerCount++;
          }

          if (cornerCount >= minCorners) {
            edges.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }
    }

    for (var edge in edges) {
      for (int i = 0; i < padding; i++) {
        double dx = edge.dx;
        double dy = edge.dy;

        Offset left = Offset(dx - i, dy);
        Offset right = Offset(dx + i, dy);
        Offset top = Offset(dx, dy - 1);
        Offset bottom = Offset(dx, dy + 1);

        List<Offset> list = [left, right, top, bottom];

        image.setPixel(dx.toInt(), dy.toInt(), ColorRgba8(255, 255, 255, 0));

        for (var item in list) {
          var x = item.dx.toInt();
          var y = item.dy.toInt();
          var pixel = image.getPixel(x, y);
          if (pixel.a > 0) {
            image.setPixel(x, y, ColorRgba8(255, 255, 255, 0));
          }
        }
      }
    }
  }

  static double calculateOtsuThreshold(List<double> confidences) {
    if (confidences.isEmpty) return 0.0;

    confidences.sort();
    int total = confidences.length;

    double sum = confidences.reduce((a, b) => a + b);
    double sumB = 0.0;
    int weightB = 0;
    int weightF = 0;

    double maxVariance = 0.0;
    double threshold = 0.0;

    for (int i = 0; i < total; i++) {
      weightB += 1;
      weightF = total - weightB;

      if (weightF == 0) break;

      sumB += confidences[i];
      double meanB = sumB / weightB;
      double meanF = (sum - sumB) / weightF;

      double varianceBetween =
          weightB * weightF * (meanB - meanF) * (meanB - meanF);

      if (varianceBetween > maxVariance) {
        maxVariance = varianceBetween;
        threshold = confidences[i];
      }
    }

    return threshold;
  }
}
