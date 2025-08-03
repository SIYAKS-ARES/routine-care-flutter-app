import 'package:flutter/material.dart';

/// Uygulama için renk sabitlerini tanımlayan sınıf
/// "Serene Dawn" renk paleti kullanılmaktadır
class AppColors {
  // Ana renkler
  static const Color primary = Color(0xFFFADADD); // Pudra Pembesi
  static const Color secondary = Color(0xFFE6E0F8); // Açık Lavanta
  static const Color accent = Color(0xFFD1F2EB); // Nane Yeşili

  // Arka plan renkleri
  static const Color background = Color(0xFFFEFCF3); // Krem Rengi
  static const Color lightGrey = Color(0xFFF5F5F5); // Açık Gri - Kartlar için

  // Metin renkleri
  static const Color text = Color(0xFF36454F); // Koyu Füme

  // Sistem renkleri
  static const Color error = Color(0xFFB00020); // Hata Rengi

  // Koyu tema için ek renkler
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFE0E0E0);

  // Constructor'ı private yap - static sınıf olarak kullanılacak
  AppColors._();
}
