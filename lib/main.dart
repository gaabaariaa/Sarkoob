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
        final baseTheme = AppTheme.forId(AppThemeId.darkGold);
        final filter = AppTheme.visualFilter(themeId);

        return MaterialApp(
          title: 'دست خدا',
          debugShowCheckedModeBanner: false,
          theme: baseTheme,
          builder: (context, child) {
            final content = Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );

            // بعضی از صفحات قدیمی پروژه هنوز رنگ‌های ثابت AppColors دارند.
            // فیلتر در ریشه باعث می‌شود انتخاب تم روی کل UI، از جمله همان
            // ویجت‌های قدیمی، یکدست اعمال شود.
            return filter == null
                ? content
                : ColorFiltered(colorFilter: filter, child: content);
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}
