import 'dart:developer';

import 'package:flutter/foundation.dart';

void logDebug(String msg) {
  if (kDebugMode) {
    print(msg);
  } else {
    log(msg);
  }
}