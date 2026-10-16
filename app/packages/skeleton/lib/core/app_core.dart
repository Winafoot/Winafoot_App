import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';

class AppCorePage extends StatefulHookConsumerWidget {
  const AppCorePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppCorePageState();
}

class _AppCorePageState extends ConsumerState<AppCorePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AutoRouter());
  }
}
