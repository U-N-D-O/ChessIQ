import 'package:chessiq/core/app/chess_iq_app.dart';
import 'package:chessiq/core/services/ad_service.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  runApp(const ChessIQApp());
}
