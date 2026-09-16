import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppThemeController.load();
  runApp(const HiddenRoleApp());
}

class HiddenRoleApp extends StatelessWidget {
  const HiddenRoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeId>(
      valueListenable: AppThemeController.current,
      builder: (context, themeId, _) {
        return MaterialApp(
          title: 'دست خدا',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.forId(themeId),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}
