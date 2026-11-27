import 'package:material_ui/material_ui.dart';

import 'engine/engine.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/viet_theme.dart';

/// Root Flutter widget for the Vietnamese Folk Chess application.
class CoDanGianApp extends StatelessWidget {
  CoDanGianApp({
    super.key,
    FolkGameRegistry? registry,
  }) : registry = registry ?? FolkGameRegistry();

  final FolkGameRegistry registry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cờ Dân Gian',
      debugShowCheckedModeBanner: false,
      theme: VietTheme.buildTheme(),
      home: HomeScreen(registry: registry),
    );
  }
}

