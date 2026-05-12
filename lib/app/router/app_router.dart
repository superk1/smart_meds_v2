import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/features/admin_review/presentation/screens/admin_review_screen.dart';
import 'package:smart_meds_v2/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_meds_v2/features/auth/presentation/screens/register_screen.dart';
import 'package:smart_meds_v2/features/barcode/presentation/screens/barcode_screen.dart';
import 'package:smart_meds_v2/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:smart_meds_v2/features/home/presentation/screens/home_screen.dart';
import 'package:smart_meds_v2/features/intake/presentation/screens/intake_screen.dart';
import 'package:smart_meds_v2/features/inventory/presentation/screens/inventory_item_detail_screen.dart';
import 'package:smart_meds_v2/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:smart_meds_v2/features/ocr/presentation/screens/ocr_screen.dart';
import 'package:smart_meds_v2/features/inventory/presentation/screens/alerts_screen.dart';
import 'package:smart_meds_v2/features/inventory/presentation/screens/export_import_screen.dart';
import 'package:smart_meds_v2/features/settings/presentation/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final fromNotification = state.uri.queryParameters['fromNotification'] == '1';
              final type = state.uri.queryParameters['type'];
              return InventoryItemDetailScreen(
                itemId: id,
                fromNotification: fromNotification,
                notificationType: type,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/export-import',
        builder: (context, state) => const ExportImportScreen(),
      ),
      GoRoute(
        path: '/intake',
        builder: (context, state) => const IntakeScreen(),
      ),
      GoRoute(
        path: '/barcode',
        builder: (context, state) => const BarcodeScreen(),
      ),
      GoRoute(
        path: '/ocr',
        builder: (context, state) => const OcrScreen(),
      ),
      GoRoute(
        path: '/admin_review',
        builder: (context, state) => const AdminReviewScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});