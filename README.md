# Sound of Safety / صوت الأمان

تطبيق **iOS أصلي (SwiftUI)** داخل المجلد **`SoundOfSafety/`** — فحص الروابط، تنبيه صوتي بالعربية، مشاركة من النظام، ومراقبة الحافظة (ضمن حدود iOS).

## التشغيل على الماك

1. تثبيت [XcodeGen](https://github.com/yonaskolb/XcodeGen) ثم من مجلد `SoundOfSafety/` تشغيل: `xcodegen generate`
2. فتح `SoundOfSafety.xcodeproj` في Xcode واختيار فريق التوقيع، وتفعيل **App Group**: `group.com.soundofsafety.shared` للتطبيق وللميزة المشتركة.

تفاصيل إضافية في **`SoundOfSafety/SETUP.txt`**.

تمت إزالة مشروع **Flutter** السابق من هذا المستودع.

## الويب (عرض للعميل) — فحص حقيقي على الخادم

- الواجهة في **`preview/`**؛ الاستدعاء يذهب إلى **`POST /api/check-url`** (يُعاد توجيهها إلى دالة Netlify في **`netlify/functions/check-url.mjs`**).
- الدالة تنفّذ **طلب HTTP فعلي** إلى الوجهة (مع تتبع التحويلات وحدّ أقصى)، **وتمنّع هجمات SSRF** على شبكة الخادم (تجاهل IPs خاصة ونطاقات داخلية)، وتُرجع **`is_safe` / `confidence` / `reasons`** حسب تحليل مبني على الاستجابة الفعلية (مثلاً HTTP غير مشفّر مقابل HTTPS، أخطاء الشبكة، تغيّر النطاق بعد التحويل).

- المصادقة (تسجيل / OTP) في الواجهة ما تزال **محلياً للعرض** فقط؛ **التحقّق من الرابط وحده حقيقياً على الخادم.**

- **اختياري (موصى به):** أضف في Netlify → **Site settings → Environment variables** المفتاح **`GOOGLE_SAFE_BROWSING_API_KEY`** لدمج [Google Safe Browsing v4](https://developers.google.com/safe-browsing/reference/rest). بدون المفتاح لا يزال الفحص يعمل مع التحليل المباشر فقط.

محلياً لتجربة الواجهة مع الدالة معاً: من **جذر المستودع** نفّذ `npx netlify dev` (يثبّت المعاينة ويشغّل الدوال عادة على **http://localhost:8888**). فتح الملف مباشرة `file://` لن يجد خادماً.

### Netlify

المستودع يتضمّن **`netlify.toml`**: نشر `preview` + مجلد **`netlify/functions`**. بعد الربط لا حاجة إلى أمر بناء.

التطبيق على **iOS**: في الإعدادات عيّن **عنوان الخادم** إلى `https://<موقعك>.netlify.app/api` (دون شرطة مائلة في النهاية) ليطابق نفس الـ API.

