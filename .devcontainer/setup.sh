#!/usr/bin/env bash
set -e

# اگه فلاتر قبلاً نصب نشده، کلونش کن
if [ ! -d "$HOME/flutter" ]; then
  echo "در حال نصب Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi

# مسیر رو دائمی به PATH اضافه کن (برای ترمینال‌های بعدی هم بمونه)
if ! grep -q 'flutter/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.bashrc"
fi
export PATH="$PATH:$HOME/flutter/bin"

flutter precache
flutter doctor

# اگه pubspec.yaml تو ریشه‌ی پروژه هست، پکیج‌ها رو هم نصب کن
if [ -f "pubspec.yaml" ]; then
  flutter pub get
fi

echo "آماده‌ست ✅"
