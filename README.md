
---

### 📚 Kutubxona Ilovasi (Flutter + Firebase)

Bu loyiha — **Flutter** yordamida ishlab chiqilgan va **Firebase Realtime Database** bilan to‘liq integratsiya qilingan **raqamli kutubxona boshqaruv tizimi** hisoblanadi. Ilova o‘quv muassasalari, tashkilotlar yoki jamoat kutubxonalari uchun mo‘ljallangan bo‘lib, foydalanuvchilarni boshqarish, kitoblarni ro‘yxatga olish, yuklab olish, o‘qish va ijaraga berish jarayonlarini raqamlashtirishni maqsad qiladi.

Ilova **zamonaviy, qulay va intuitiv foydalanuvchi interfeysi** bilan ishlab chiqilgan bo‘lib, administratorlar va foydalanuvchilar uchun o‘zaro aloqani soddalashtiradi.

---

## 🔑 Asosiy imkoniyatlar

### 🔐 Ro‘yxatdan o‘tish / Kirish (Authentication)

* Foydalanuvchilar email va parol orqali tizimga ro‘yxatdan o‘tadi yoki kiradi.
* Firebase Authentication orqali xavfsiz autentifikatsiya.

### 📖 Kitoblarni ko‘rish, o‘qish va yuklab olish

* Kitoblar toifalarga ajratilgan (masalan: Badiiy, Darslik, Ilmiy).
* Har bir kitob haqida ma’lumot: sarlavha, muallif, rasm, tavsif.
* Kitobni ilovada PDF tarzida o‘qish yoki telefon xotirasiga yuklab olish.
* Yuklab olish faqat ruxsat berilgan foydalanuvchilar uchun cheklanishi mumkin (xavfsizlik uchun).

### 👤 A’zolarni boshqarish (User Management)

* Adminlar barcha foydalanuvchilar ro‘yxatini ko‘ra oladi.
* Har bir a’zoning emaili, foydalanuvchi IDsi, yuklab olgan yoki ijaraga olgan kitoblar ro‘yxati va muddati ko‘rsatiladi.
* Kitoblarni qachon qaytarishi kerakligi belgilanishi mumkin.

### ⚙️ Sozlamalar (Settings)

* Ilovani interfeys rejimini tanlash: yengil (light) yoki qorong‘i (dark).
* Tilni o‘zgartirish (masalan: o‘zbekcha, inglizcha).
* Shriftsiz o‘qish rejimi (distraction-free reading mode).

### 🔍 Qidiruv funksiyasi (kitoblar, a’zolar)

* Kitoblar va foydalanuvchilar nomi, muallifi yoki email orqali izlanadi.
* Realtime Database’da jonli qidiruv (debounced search).

### 📦 Barcode ko‘rsatish (ijaraga berilgan kitoblar uchun)

* Har bir ijaraga olingan kitobga mos barcode generatsiya qilinadi.
* Kitoblar barcode orqali tezda skanerlanib aniqlanishi mumkin.

### ✅ Kitobni qaytarilgan deb belgilash

* Foydalanuvchi tomonidan qaytarilgan kitob "Qaytarilgan" deb belgilanishi mumkin.
* Bu holat Firebase bazasida yangilanadi va ijaraga olganlar ro‘yxatidan o‘chadi.

### ☁️ Firebase Realtime Database integratsiyasi

* Barcha ma’lumotlar (kitoblar, foydalanuvchilar, sozlamalar) real vaqtda Firebase’da saqlanadi.
* Foydalanuvchi interfeysi bazadagi o‘zgarishlarga mos ravishda darhol yangilanadi.

---
