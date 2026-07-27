import 'package:flutter_test/flutter_test.dart';

import 'package:hidden_role_flutter/main.dart';

void main() {
  testWidgets('اپ بدون خطا بالا میاد و صفحه‌ی خانه رو نشون می‌ده', (WidgetTester tester) async {
    await tester.pumpWidget(const HiddenRoleApp());
    expect(find.text('سرکوب'), findsWidgets);
  });
}
