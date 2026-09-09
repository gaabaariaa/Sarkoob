/// یه رویدادِ امتیازیِ ثبت‌شده برای یه بازیکن، در طولِ یه بازی — پایه‌ی
/// سیستمِ امتیازدهیِ بهترین/بدترین بازیکن (طبقِ سندِ طراحی:
/// sarkoob-scoring-system-design.md). هر رویداد جدا ذخیره می‌شه (نه فقط
/// جمعِ نهایی) تا هم قابلِ‌مرور باشه هم قابلِ‌دیباگ.
class ScoreEvent {
  final String mechanism; // برچسبِ فارسیِ کوتاه، برای نمایش (مثلاً «شاتِ رهبر»)
  final int points; // می‌تونه منفی باشه؛ هیچ‌وقت صفر ذخیره نمی‌شه
  final int roundNumber;
  final String phaseLabel; // 'روز' یا 'شب' — فقط برای نمایش

  const ScoreEvent({
    required this.mechanism,
    required this.points,
    required this.roundNumber,
    required this.phaseLabel,
  });

  Map<String, dynamic> toJson() => {
        'mechanism': mechanism,
        'points': points,
        'roundNumber': roundNumber,
        'phaseLabel': phaseLabel,
      };

  factory ScoreEvent.fromJson(Map<String, dynamic> json) => ScoreEvent(
        mechanism: json['mechanism'] as String,
        points: json['points'] as int,
        roundNumber: json['roundNumber'] as int,
        phaseLabel: json['phaseLabel'] as String,
      );
}
