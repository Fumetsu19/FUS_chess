import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[DeviceOrientation.portraitUp],
  );
  try {
    final services = await AppServices.bootstrap();
    runApp(ChessEnglishApp(services: services));
  } catch (error, stackTrace) {
    debugPrint('Ошибка запуска: $error\n$stackTrace');
    runApp(BootstrapErrorApp(error: error));
  }
}
