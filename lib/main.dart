import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meds_v2/app/bootstrap/app_bootstrap.dart';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(LocalStorageService(prefs)),
      ],
      child: const AppBootstrap(),
    ),
  );
}
