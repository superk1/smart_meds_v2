import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_meds_v2/core/notifications/notification_initializer.dart';

class NotificationNavigationHandler extends StatefulWidget {
  final Widget child;

  const NotificationNavigationHandler({
    super.key,
    required this.child,
  });

  @override
  State<NotificationNavigationHandler> createState() =>
      _NotificationNavigationHandlerState();
}

class _NotificationNavigationHandlerState
    extends State<NotificationNavigationHandler> {
  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el payload
    NotificationInitializer.lastPayload.addListener(_handlePayload);
    // Procesar si ya hay un payload al montar (lanzamiento desde notif)
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePayload());
  }

  @override
  void dispose() {
    NotificationInitializer.lastPayload.removeListener(_handlePayload);
    super.dispose();
  }

  void _handlePayload() {
    final payload = NotificationInitializer.lastPayload.value;
    if (payload == null || payload.isEmpty) return;

    if (!mounted) return;

    // Limpiar para evitar navegaciones repetidas
    NotificationInitializer.clearLastPayload();
    
    // Parse format: "type|itemId"
    final parts = payload.split('|');
    String itemId;
    String type = '';

    if (parts.length > 1) {
      type = parts[0];
      itemId = parts[1];
    } else {
      // Retrocompatibilidad
      itemId = payload;
    }

    final uri = Uri(
      path: '/inventory/$itemId',
      queryParameters: {
        'fromNotification': '1',
        if (type.isNotEmpty) 'type': type,
      },
    );

    // Evitar navegaciones redundantes exactas
    final currentUri = GoRouterState.of(context).uri;
    if (currentUri.path == uri.path && currentUri.queryParameters['fromNotification'] == '1') {
      return; 
    }

    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
