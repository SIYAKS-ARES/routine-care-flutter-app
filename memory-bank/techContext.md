# Routine Care - Teknolojik Bağlam

## Kullanılan Teknolojiler

### Framework & Platform
- **Flutter**: Cross-platform mobil geliştirme
- **Dart**: Programlama dili (SDK >=3.0.0 <4.0.0)
- **Target Platforms**: iOS, Android, Web, Desktop

### State Management
- **flutter_riverpod**: Modern state management
- **riverpod_annotation**: Code generation desteği
- **riverpod_generator**: Otomatik provider oluşturma

### Dependency Injection
- **get_it**: Service locator pattern
- **injectable**: Otomatik dependency injection
- **injectable_generator**: Code generation

### Veri Depolama
- **hive**: Yerel NoSQL veritabanı
- **hive_flutter**: Flutter entegrasyonu
- **hive_generator**: Model code generation

### Firebase Backend
- **firebase_core**: Firebase temel entegrasyonu
- **firebase_auth**: Kimlik doğrulama
- **cloud_firestore**: Cloud veritabanı
- **google_sign_in**: Google ile giriş
- **firebase_messaging**: Push bildirimler

### Bildirim Sistemi
- **flutter_local_notifications**: Yerel bildirimler
- **timezone**: Zaman dilimi yönetimi

### UI & Görselleştirme
- **cupertino_icons**: iOS tarzı ikonlar
- **flutter_slidable**: Kaydırma işlemleri
- **flutter_heatmap_calendar**: Aktivite takvimi
- **fl_chart**: Grafik ve çizelgeler
- **lottie**: Animasyonlar
- **confetti**: Kutlama efektleri

### Code Generation & Serialization
- **freezed**: Immutable modeller
- **freezed_annotation**: Freezed annotation'ları
- **json_annotation**: JSON serileştirme
- **json_serializable**: Otomatik JSON kod üretimi
- **build_runner**: Code generation aracı

### Araçlar ve Utilities
- **intl**: Uluslararasılaştırma
- **logger**: Log yönetimi
- **csv**: CSV dosya işlemleri
- **path_provider**: Dosya yolu yönetimi
- **share_plus**: Paylaşım fonksiyonu
- **permission_handler**: İzin yönetimi

## Geliştirme Ortamı

### Development Tools
- **Flutter SDK**: Mobile development
- **Dart SDK**: Programming language
- **VS Code**: IDE (ayarlar .vscode/ dizininde)
- **Flutter Lints**: Code quality rules

### Build Configuration
- **analysis_options.yaml**: Kod analizi kuralları
- **pubspec.yaml**: Dependency yönetimi
- **dependency_overrides**: Sürüm çakışmaları çözümü

## Proje Yapılandırması

### Minimum Sistem Gereksinimleri
- Flutter SDK 3.0+
- Dart SDK 3.0+
- iOS 11.0+ / Android API 21+

### Build Komutları
```bash
# Development
flutter run

# Build
flutter build apk --release
flutter build ios --release

# Code Generation
flutter packages pub run build_runner build --delete-conflicting-outputs

# Dependency Management
flutter pub get
flutter pub upgrade
```

## Veritabanı Şeması

### Yerel Depolama (Hive)
- **routines**: Rutin verileri
- **achievements**: Başarı sistemi
- **user_progress**: Kullanıcı ilerlemesi
- **notifications**: Bildirim ayarları

### Cloud Firestore
- **users**: Kullanıcı profilleri
- **user_achievements**: Bulut başarıları
- **user_statistics**: İstatistik verileri

## Performans Optimizasyonları

### Memory Management
- **Dispose Pattern**: Resource temizliği
- **Stream Controllers**: Memory leak önleme
- **Image Caching**: Görsel önbellekleme

### Network Optimizations
- **Lazy Loading**: Veri ihtiyaç anında
- **Caching Strategies**: Sık kullanılan veriler
- **Batch Operations**: Toplu veri işlemleri

### UI Performance
- **Const Constructors**: Widget optimizasyonu
- **Repaint Boundaries**: Yeniden çizim optimizasyonu
- **ListView Builder**: Büyük listeler için

## Güvenlik Konfigürasyonu

### Firebase Security Rules
- Firestore güvenlik kuralları
- Authentication yetkilendirme
- Veri erişim kontrolü

### Local Security
- Hive şifreleme (opsiyonel)
- Sensitive data storage
- Permission management

## Testing Stratejisi

### Unit Tests
- Service layer testleri
- Model validation
- Business logic testleri

### Integration Tests
- Firebase entegrasyonu
- Local database işlemleri
- Notification sistemi

### Widget Tests
- UI component testleri
- User interaction testleri

## Deployment Konfigürasyonu

### App Store (iOS)
- **Bundle ID**: com.routinecare.app
- **Version**: 1.0.0+1
- **Signing**: Apple Developer hesabı

### Google Play (Android)
- **Package Name**: com.routinecare.app
- **Version**: 1.0.0 (1)
- **Signing**: Android App Bundle

## Monitoring & Analytics

### Crash Reporting
- Firebase Crashlytics entegrasyonu
- Custom error logging
- Performance monitoring

### User Analytics
- Firebase Analytics
- Custom event tracking
- User behavior analysis
