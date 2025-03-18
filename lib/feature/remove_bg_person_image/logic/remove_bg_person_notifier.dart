import 'dart:async';

import 'package:flutter_remove_bg_person/helper/gg_mlkit_selfie_segmentation_helper.dart';
import 'package:flutter_remove_bg_person/helper/logger.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class RemoveBgPersonNotifier extends ChangeNotifier {
  Uint8List? orgImage;
  Uint8List? removedBgImage;

  bool isLoading = false;

  void onOrgImageChanged(Uint8List orgImage) {
    this.orgImage = orgImage;
    notifyListeners();
  }

  void onIsLoadingChanged(bool isLoading) {
    this.isLoading = isLoading;
    notifyListeners();
  }

  void onRemovedBgImageChanged(Uint8List removedBgImage) {
    this.removedBgImage = removedBgImage;
    notifyListeners();
  }

  Future<void> removeBackgroundFromUrl(Uri url) async {
    try {
      showLoading();

      Uint8List? orgImage = await downloadImageBinary(url);

      hideLoading();

      if (orgImage != null) {
        onOrgImageChanged(orgImage);

        showLoading();

        Uint8List? removedBgImage =
            await GgMlkitSelfieSegmentationHelper.removeBackground(orgImage);

        hideLoading();

        if (removedBgImage != null) {
          onRemovedBgImageChanged(removedBgImage);
        }
      }
    } catch (e) {
      logDebug("removeBackgroundFromUrl -> error: $e");
    }
  }

  Future<Uint8List?> downloadImageBinary(Uri url) async {
    try {
      final response = await http.get(url);
      return response.bodyBytes;
    } on TimeoutException {
      return null;
    } catch (e) {
      return null;
    }
  }

  void showLoading() {
    onIsLoadingChanged(true);
  }

  void hideLoading() {
    onIsLoadingChanged(false);
  }
}
