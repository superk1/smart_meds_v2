import 'package:flutter/material.dart';
import 'package:smart_meds_v2/core/notifications/notification_navigation_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_meds_v2/app/router/app_router.dart';
import 'package:smart_meds_v2/app/theme/app_theme.dart';
import 'package:smart_meds_v2/core/constants/app_strings.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return NotificationNavigationHandler(
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
