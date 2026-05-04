# Sound of Safety / صوت الأمان

تطبيق **iOS أصلي (SwiftUI)** داخل المجلد **`SoundOfSafety/`** — فحص الروابط، تنبيه صوتي بالعربية، مشاركة من النظام، ومراقبة الحافظة (ضمن حدود iOS).

## التشغيل على الماك

1. تثبيت [XcodeGen](https://github.com/yonaskolb/XcodeGen) ثم من مجلد `SoundOfSafety/` تشغيل: `xcodegen generate`
2. فتح `SoundOfSafety.xcodeproj` في Xcode واختيار فريق التوقيع، وتفعيل **App Group**: `group.com.soundofsafety.shared` للتطبيق وللميزة المشتركة.

تفاصيل إضافية في **`SoundOfSafety/SETUP.txt`**.

تمت إزالة مشروع **Flutter** السابق من هذا المستودع.

## عرض الفكرة بدون Xcode

افتح الملف **`preview/index.html`** في أي متصفح (سحب الملف إلى Chrome أو Edge، أو من القائمة «فتح ملف»). صفحة تجريبية بالعربية: شاشة بداية ~٢ ثانية، حقل رابط، نتيجة آمن/غير آمن **وهمية**، ونطق عربي عبر **Web Speech API** إن كان المتصفح يدعمه.

