import 'package:flutter/material.dart';
import '../widgets/coming_soon.dart';

class StartGameScreen extends StatelessWidget {
  const StartGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شروع بازی')),
      body: const ComingSoon(
        icon: Icons.theater_comedy,
        text: 'جریان شروع بازی (انتخاب بازیکن‌ها و تقسیم نقش) بعد از '
            'اضافه شدنِ نقش‌های سناریوی سرکوب ساخته می‌شه.',
      ),
    );
  }
}
