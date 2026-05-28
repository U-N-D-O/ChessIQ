import 'package:flutter/foundation.dart';

const String kFirebaseRealtimeDatabaseUrl =
    'https://chessiq-89b45-default-rtdb.firebaseio.com';
const String kFirebaseCloudFunctionsBaseUrl =
    'https://us-central1-chessiq-89b45.cloudfunctions.net';
const String kFirebaseIosApiKey = 'AIzaSyAL5PbGAF9z-7C9DL01vTuz9ijEqMtyT60';
const String kFirebaseAndroidApiKey = 'AIzaSyCkMaBOX1Mdbc64OwFmlO_3wLZp4q9zyfE';

String get kFirebaseAuthApiKey {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return kFirebaseAndroidApiKey;
  }
  return kFirebaseIosApiKey;
}
