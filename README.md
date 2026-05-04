# Sound of Safety / صوت الأمان

تطبيق **iOS أصلي (SwiftUI)** داخل المجلد **`SoundOfSafety/`** — فحص الروابط، تنبيه صوتي بالعربية، مشاركة من النظام، ومراقبة الحافظة (ضمن حدود iOS).

## التشغيل على الماك

1. تثبيت [XcodeGen](https://github.com/yonaskolb/XcodeGen) ثم من مجلد `SoundOfSafety/` تشغيل: `xcodegen generate`
2. فتح `SoundOfSafety.xcodeproj` في Xcode واختيار فريق التوقيع، وتفعيل **App Group**: `group.com.soundofsafety.shared` للتطبيق وللميزة المشتركة.

تفاصيل إضافية في **`SoundOfSafety/SETUP.txt`**.

تمت إزالة مشروع **Flutter** السابق من هذا المستودع.

## عرض الفكرة للعميل (ويب، بدون Xcode)

المجلد **`preview/`** يحاكي تدفّق التطبيق: شاشة بداية (~٢ ث)، تسجيل / دخول، **رمز OTP** (معروض للتجربة)، فحص رابط (**آمن / غير آمن**، ثقة، أسباب)، **ملاحظة المستخدم**، **السجل**، **إعدادات** (عنوان API اختياري، مراقبة حافظة، خروج)، وتنبيه صوتي عربي حيث يدعم المتصفح. للمعاينة محلياً افتح **`preview/index.html`** في المتصفح.

### النشر على Netlify

1. من GitHub: Netlify → **Import from Git** → **Publish directory:** `preview` (أو استخدم **`netlify.toml`** في جذر المستودع لضبط النشر تلقائياً).
2. يدوياً: اضغط مجلد **`preview`** في zip وارفعه عبر **Deploy manually**.

الرابط الناتج `https://…netlify.app` يصلح لإرساله للعميل. **localStorage** للتجربة فقط؛ خادم حقيقي يحتاج **CORS** على `POST /check-url` إن فُعّل في الإعدادات.

