# OpenWrt-BDIX-Bypass-By-Jahid-Hasan-Shuvo

আপনার OpenWrt রাউটারের জন্য একটি প্রিমিয়াম এবং হাই-স্পিড **BDIX Bypass** সলিউশন। এটি Redsocks প্রোটোকল ব্যবহার করে আপনার ট্রাফিককে অপ্টিমাইজ করে এবং একটি অত্যাধুনিক, রেসপনসিভ LuCI ইন্টারফেসের মাধ্যমে সার্ভিস কন্ট্রোল করার সুবিধা দেয়।

## 🚀 Features (বৈশিষ্ট্যসমূহ)
* **One-Click Auto-Installer:** কোনো ঝামেলা ছাড়াই স্বয়ংক্রিয়ভাবে ব্যাকএন্ড এবং ফ্রন্টএন্ড সেটআপ।
* **Modern Premium UI:** ডার্ক মোড এবং সুন্দর ডিজাইনের সাথে প্রফেশনাল ড্যাশবোর্ড।
* **Live Dashboard:** ব্রাউজার থেকেই সহজেই Proxy IP, Port, Username এবং Password পরিবর্তন করার সুবিধা।
* **Service Control:** ইন্টারফেস থেকেই এক ক্লিকে **BOOST** (Start) এবং **STOP** করার বাটন।
* **Lightweight:** রাউটারের রিসোর্সের ওপর কোনো চাপ ফেলে না, অত্যন্ত দ্রুত কাজ করে।

## 🛠 Installation (ইন্সটলেশন)

আপনার রাউটারে **SSH** দিয়ে লগইন করুন এবং নিচের কমান্ডটি কপি করে পেস্ট করুন:

```bash
wget -O- https://raw.githubusercontent.com/jahid421/OpenWrt-BDIX-Bypass-By-Jahid-Hasan-Shuvo/refs/heads/main/install.sh | sh
```

## (দ্রষ্টব্য: কমান্ডটি চালানোর পর টার্মিনালে ইন্সটলেশন শেষ হওয়া পর্যন্ত অপেক্ষা করুন এবং শেষে আপনার ব্রাউজারে LuCI রিফ্রেশ দিন।)

## ⚙️ Manual Settings
ইন্সটলেশন শেষে, আপনি রাউটারের LuCI প্যানেলে লগইন করে Services মেনুর অধীনে BDIX_BYPASS ট্যাবে আপনার প্রক্সি সেটিংস আপডেট করতে পারবেন।

## 👨‍💻 Developer
এই প্রজেক্টটি ডেভেলপ করেছেন: Jahid Hasan Shuvo

Instagram: @crazy_boy_jahid
আপনার যদি এই টুলটি ভালো লেগে থাকে, তবে GitHub রিপোজিটরিতে একটি ⭐ দিতে ভুলবেন না!



🗑 Uninstall (কিভাবে ডিলিট করবেন)
যদি আপনি কোনো কারণে BDIX BYPASS সিস্টেমটি আপনার রাউটার থেকে পুরোপুরি সরিয়ে ফেলতে চান, তবে নিচের কমান্ডটি SSH টার্মিনালে রান করুন:

```bash
wget -O- https://raw.githubusercontent.com/jahid421/OpenWrt-BDIX-Bypass-By-Jahid-Hasan-Shuvo/refs/heads/main/uninstall.sh  | sh
```

এই আনইনস্টল স্ক্রিপ্টটি যা যা করবে:

Service Cleanup: চলমান প্রক্সি সার্ভিসটি (redsocks) সাথে সাথে স্টপ এবং ডিজেবল করে দিবে।

Remove Files: রাউটারে থাকা সব সার্ভিস ফাইল, কনফিগ এবং LuCI-এর UI ফাইলগুলো মুছে ফেলবে।

Menu Cleanup: মেনু থেকে BDIX_BYPASS অপশনটি সরিয়ে দিবে।

Cache Reset: সিস্টেম ক্যাশ ক্লিয়ার করে সবকিছু আগের মতো ক্লিন করে দিবে।
