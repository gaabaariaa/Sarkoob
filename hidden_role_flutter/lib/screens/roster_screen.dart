import 'package:flutter/material.dart';
import '../widgets/coming_soon.dart';

class RosterScreen extends StatelessWidget {
  const RosterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بازیکنان')),
      body: const ComingSoon(
        icon: Icons.groups,
        text: 'لیست دائمی بازیکن‌ها به‌زودی همینجا میاد.',
      ),
    );
  }
}
