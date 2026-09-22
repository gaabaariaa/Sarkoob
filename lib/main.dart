import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_language.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppThemeController.load();
  await AppLanguageController.load();
  runApp(const HiddenRoleApp());
}

class HiddenRoleApp extends StatelessWidget {
  const HiddenRoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppThemeController.current, AppLanguageController.current]),
      builder: (context, _) {
        final themeId = AppThemeController.current.value;
        return MaterialApp(
          title: 'دست خدا',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.forId(themeId),
          locale: AppLanguageController.locale,
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
