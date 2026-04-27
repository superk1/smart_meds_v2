import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/features/admin_review/presentation/screens/admin_review_screen.dart';
import 'package:smart_meds_v2/features/barcode/presentation/screens/barcode_screen.dart';
import 'package:smart_meds_v2/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:smart_meds_v2/features/home/presentation/screens/home_screen.dart';
import 'package:smart_meds_v2/features/intake/presentation/screens/intake_screen.dart';
import 'package:smart_meds_v2/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:smart_meds_v2/features/ocr/presentation/screens/ocr_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
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
    ],
  );
});