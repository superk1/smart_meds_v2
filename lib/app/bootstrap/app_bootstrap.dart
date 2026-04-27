import 'package:flutter/material.dart';
import 'package:smart_meds_v2/app/app.dart';

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    // Here we can handle future initializations before returning the main App
    return const App();
  }
}
