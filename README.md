# UDF Görüntüleyici + Hızlı Bakış (QuickLook)

UYAP `.udf` dosyaları için macOS uygulaması:
- Finder'da bir `.udf` dosyasına **boşluk (space)** tuşuna basınca **önizleme**.
- Finder'da dosya simgesinde **küçük resim (thumbnail)**.
- **Salt-okunur görüntüleyici** (metin seçilip kopyalanabilir) ve içinde **"UYAP Editöründe Aç"** düğmesi (Uyap Doküman Editörü kuruluysa).

> Not: Bu araç `.udf` dosyalarının **çift tıklama (varsayılan uygulama)** ilişkisini **değiştirmez**. Çift tıklama eskisi gibi resmî UYAP editörünü açmaya devam eder; bu uygulama yalnızca QuickLook önizleme + thumbnail ekler. Salt-okunur görüntüleyiciyi kullanmak için **UDF Görüntüleyici** uygulamasını açıp **Dosya → Aç… (⌘O)** ile `.udf` dosyasını seçin (veya dosyayı uygulama ikonuna sürükleyin).

## Ekran görüntüleri

| Hızlı Bakış önizleme (SPACE) | Finder küçük resmi |
|:---:|:---:|
| <img src="assets/onizleme.png" width="460"> | <img src="assets/kucukresim.png" width="170"> |

## Kurulum

Terminal'e yapıştırın:

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/saidsurucu/udf-quicklook-extension/main/kur.sh)"
```

Kaynak koddan, sizin makinenizde derlenir (ad-hoc imza → Gatekeeper uyarısı yok).
İlk kurulumda bir yükleme penceresi açılırsa **"Yükle"ye basıp bitmesini bekleyin**;
kurulum kendiliğinden devam eder.

## Önizleme görünmüyorsa

Sistem Ayarları → Genel → Giriş Öğeleri ve Uzantılar → **Hızlı Bakış** → **UDFViewer** işaretli olmalı.

## Geliştirici notları

Saf SwiftPM ile derlenir (tam Xcode gerekmez):
- `swift build -c release` + `scripts/build.sh` → `.app` ve iki `.appex` paketini elle
  monte edip ad-hoc imzalar (eklentiler `_NSExtensionMain` giriş noktasıyla kurulur).
- `kur.sh` bunu sarmalar: Command Line Tools'u kurar, derler, `/Applications`'a koyar,
  QuickLook eklentilerini kaydeder/etkinleştirir.
