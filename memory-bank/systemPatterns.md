# Routine Care - Sistem Mimarisi ve Desenler

## Genel Mimari
Clean Architecture prensiplerine dayalı Flutter uygulaması. Katmanlı yapı ile modülerlik ve test edilebilirlik hedeflenmiştir.

## Proje Yapısı
```
lib/
├── core/                 # Temel altyapı katmanı
│   ├── auth/            # Authentication wrapper
│   ├── config/          # Firebase ve diğer konfigürasyonlar
│   ├── constants/       # Uygulama sabitleri
│   ├── di/              # Dependency Injection
│   ├── error/           # Hata yönetimi
│   ├── theme/           # Tema ve renkler
│   └── utils/           # Yardımcı fonksiyonlar
├── data/                # Veri katmanı
│   └── routine_database.dart  # Hive veritabanı yönetimi
├── features/            # Feature bazlı organizasyon
│   └── achievement_system/    # Başarı sistemi modülü
├── shared/              # Paylaşılan bileşenler
│   ├── models/          # Veri modelleri
│   ├── services/        # Servis katmanı
│   ├── widgets/         # Genel widget'lar
│   └── data/            # Paylaşılan veri yapıları
├── components/          # UI bileşenleri
├── pages/               # Sayfa seviyesi widget'lar
└── main.dart           # Uygulama giriş noktası
```

## Temel Tasarım Desenleri

### 1. Service Layer Pattern
- **AchievementService**: Başarı sistemi iş mantığı
- **AuthService**: Kimlik doğrulama işlemleri
- **NotificationService**: Bildirim yönetimi
- **RoutineReminderService**: Rutin hatırlatıcıları

### 2. Repository Pattern
- **FirestoreService**: Firebase veri erişimi
- **RoutineDatabase**: Yerel veritabanı işlemleri

### 3. Provider/State Management
- **Riverpod**: Modern state management
- **Notifier pattern**: State güncellemeleri

### 4. Dependency Injection
- **GetIt + Injectable**: Servis yönetimi
- **Singleton**: Servis yaşam döngüsü

## Temel Bileşen İlişkileri

### Achievement System
```
AchievementService -> AchievementDefinitions
                 -> UserProgress (Entity)
                 -> AchievementModel
```

### Notification System
```
NotificationService -> Local Notifications
                    -> Firebase Messaging
                    -> Smart Scheduler
```

### Data Flow
```
UI Layer -> Service Layer -> Repository -> Data Source
    ↑              ↓              ↓
 State      Business Logic   Storage/Network
```

## Kritik Implementasyon Yolları

### 1. Başarı Kontrolü
```dart
AchievementService.checkAndUnlockAchievements()
├── UserProgress analiz
├── Koşul kontrolü
├── Başarı kilidi açma
└── Bildirim gönderme
```

### 2. Rutin Tamamlama
```dart
Routine completion flow:
├── Rutin verisi kaydet
├── UserProgress güncelle
├── Başarı kontrolü tetikle
├── Streak hesapla
└── İstatistikleri güncelle
```

### 3. Bildirim Sistemi
```dart
Smart notification flow:
├── Zaman bazlı kontrol
├── Kullanıcı preference analizi
├── Optimal gönderim zamanı
└── Context-aware bildirim
```

## Veri Modeli Desenleri

### 1. Immutable Models
- Tüm modeller `@freezed` ile immutable
- `copyWith` metotları ile güncelleme

### 2. Entity vs Model
- **Entity**: Domain katmanında (UserProgress)
- **Model**: Veri transferi (AchievementModel)

### 3. JSON Serialization
- `json_annotation` ile otomatik serileştirme
- `build_runner` ile kod üretimi

## Hata Yönetimi Desenleri
- **Custom Exceptions**: Domain spesifik hatalar
- **Result Types**: Başarı/hata durumları
- **Global Error Handler**: Merkezi hata yönetimi

## Performans Optimizasyonları
- **Lazy Loading**: Veri ihtiyaç anında yüklenir
- **Caching**: Sık kullanılan veriler önbellekte
- **Async Operations**: Tüm ağ işlemleri asenkron
- **Memory Management**: Dispose pattern ve stream yönetimi
