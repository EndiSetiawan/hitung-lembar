# Hitung Kas — Flutter

Aplikasi Flutter offline untuk menghitung uang kertas dan logam, dengan tampilan mobile-first yang mengikuti versi HTML.

## Fitur
- 7 nominal uang kertas.
- 4 nominal uang logam.
- Pemilihan nominal aktif.
- Keypad angka dan backspace.
- Perhitungan subtotal per nominal.
- Total kas otomatis.
- Reset semua hitungan.
- Preview struk.
- Render struk resolusi tinggi.
- Simpan/berbagi gambar melalui native share Android.
- Bisa dikirim ke WhatsApp melalui menu share Android.
- Tidak membutuhkan server/database online untuk fungsi utama.

## Build lokal
```bash
flutter pub get
flutter run
flutter build apk --release
```

## GitHub Actions
Push repository ke GitHub lalu buka:
Actions → Build Hitung Kas → Run workflow.

APK tersedia di artifact `hitung-kas-apk`.

Catatan: implementasi native menghasilkan PNG untuk menjaga kualitas dan kompatibilitas Android. Tombol "Simpan Gambar" tetap menggunakan native share agar file dapat disimpan/dikirim. Jika Anda benar-benar membutuhkan JPG, konversi PNG→JPG dapat ditambahkan dengan package image.
