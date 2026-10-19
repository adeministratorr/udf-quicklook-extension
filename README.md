# UDF Görüntüleyici + Hızlı Bakış (QuickLook) — macOS Apple Silicon (M1/M2/M3/M4) Kurulumu

UYAP'ın `.udf` belge dosyalarını **MacBook, MacBook Pro, MacBook Air, Mac mini ve iMac**'de görüntüleyin: Finder'da **boşluk tuşuyla önizleme**, simgede **küçük resim** ve çift tıklamayla açılan **salt-okunur görüntüleyici**. Apple Silicon (M serisi, ARM tabanlı işlemci) için native Swift — Rosetta yok, Java kurulumu gerekmez.

**Kimler için:** UYAP'tan `.udf` (dilekçe, tebligat, karar, bilirkişi raporu) indiren avukatlar, bilirkişiler ve arabulucular; arşiv tarayan hukuk büroları; UYAP evrakı işleyen idari birimler ve kamu çalışanları.

## Kimler için?

- **Avukatlar:** UYAP'tan indirdiği `.udf` (dilekçe, tebligat, karar) dosyalarını Finder'da hızlıca gözden geçirmek isteyenler.
- **Bilirkişiler ve arabulucular:** Rapor eklerini, tebliğ belgelerini hızlı önizlemek isteyenler.
- **Hukuk büroları:** Arşivdeki `.udf` dosyalarını UYAP Editör'ü açmadan taramak isteyenler.
- **İdari birimler ve kamu çalışanları:** UYAP evrakını görüntüleyip değerlendirenler.

## "UDF dosyası açılmıyor" arayanlar için kısa cevaplar

- **Çift tıklama davranışı değişir mi?** Hayır — çift tıklama eskisi gibi resmî UYAP Editörü'nü açar. Bu araç yalnızca **hızlı bakış önizlemesi + küçük resim** ekler.
- **MacBook / MacBook Pro / MacBook Air / iMac / Mac mini'de çalışır mı?** Evet — Apple Silicon (M1/M2/M3/M4) tüm modeller. Intel Mac desteklenmez.
- **Salt-okunur görüntüleyici nasıl açılır?** Uygulamayı açıp **Dosya → Aç… (⌘O)** ile `.udf` seçin veya dosyayı uygulama ikonuna sürükleyin.
- **Pencere boş mu açılıyor?** Güncel sürümde boş başlatmada "dosyayı sürükleyin / Aç…" diyen bir karşılama penceresi vardır (bu fork'te eklendi).
- **Önizleme görünmüyor mu?** Sistem Ayarları → Genel → Giriş Öğeleri ve Uzantılar → **Hızlı Bakış** → **UDFViewer** işaretli olmalı.
- **UDF belgeleri e-imzalı; görüntülemek için e-imza gerekir mi?** Hayır — görüntüleme ve önizleme e-imza/kart gerektirmez. Belgeyi düzenleyip imzalamak için [UYAP Doküman Editörü (arm64)](https://github.com/adeministratorr/ude-mac-arm64-1) ve arm64 AKİS sürücüsü gerekir.
- **UYAP Editör gerekir mi?** Önizleme için hayır. "UYAP Editöründe Aç" düğmesi, Uyap Doküman Editörü kuruluysa çalışır.

## Kurulum (3 yol)

1. **Tek satır (kaynaktan derler):**

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/adeministratorr/udf-quicklook-extension/main/kur.sh)"
```

2. **Homebrew cask (hazır DMG, en hızlı):**

```bash
brew install --cask adeministratorr/tap/udf-quicklook
```

3. **Hazır DMG:** [Releases](../../releases) → `UdfQuicklook-arm64-*.dmg`

> Bu fork'teki sürüm, orijinal projeye ek olarak **UYAP Editör ailesi stiliyle çizilmiş uygulama ikonu** ve **karşılama penceresi** (sürükle-bırak + ⌘O) içerir; çift tıklamayla açıldığında sessizce boş açılmaz.

Diğer araçlar (aynı tap): [e-Devlet E-İmza](https://github.com/adeministratorr/edevlet-eimza-mac-arm64) · [PTT KEP Webmail](https://github.com/adeministratorr/pttkep-eimza-mac-arm64) · [PTT UETS / e-Tebligat](https://github.com/adeministratorr/uets-eimza-mac-arm64) · [TNB Teknoloji İmza](https://github.com/adeministratorr/tnb-eimza-mac-arm64) · [UHAP İmzalama](https://github.com/adeministratorr/uhap-eimza-mac-arm64) · [UYAP Doküman Editörü](https://github.com/adeministratorr/ude-mac-arm64-1)

## Neden bozuktu? Ne düzelttik?

- **Sorun 1 — "uygulama açılmıyor":** Çift tıklanarak başlatıldığında hiçbir pencere görünmüyordu.
- **Neden:** Orijinal kod pencereyi yalnızca bir `.udf` dosyası uygulamaya açıldığında (`application(_:open:)`) oluşturuyordu; dosyasız açılışta ekranda hiçbir şey çıkmıyordu.
- **Çözüm:** Karşılama penceresi eklendi: dosya sürükle-bırak alanı, **Aç… (⌘O)** düğmesi ve Dock'tan yeniden açılınca pencerenin geri gelmesi.
- **Sorun 2 — uygulama ikonu:** Uygulamanın özgün ikonu yoktu (genel ikon).
- **Çözüm:** UYAP Editör ailesi stiline uygun özgün ikon üretildi (`scripts/make-icon.swift`) ve `.app`'e gömüldü.

---

## Neler yapar?

- Finder'da bir `.udf` dosyasına **boşluk (space)** tuşuna basınca **önizleme**.
- Finder'da dosya simgesinde **küçük resim (thumbnail)**.
- **Salt-okunur görüntüleyici** (metin seçilip kopyalanabilir) ve içinde **"UYAP Editöründe Aç"** düğmesi (Uyap Doküman Editörü kuruluysa).

> Not: Bu araç `.udf` dosyalarının **çift tıklama (varsayılan uygulama)** ilişkisini **değiştirmez**. Çift tıklama eskisi gibi resmî UYAP editörünü açmaya devam eder; bu uygulama yalnızca QuickLook önizleme + thumbnail ekler.

## Ekran görüntüleri

| Hızlı Bakış önizleme (SPACE) | Finder küçük resmi |
|:---:|:---:|
| <img src="assets/onizleme.png" width="460"> | <img src="assets/kucukresim.png" width="170"> |

## Önizleme görünmüyorsa

Sistem Ayarları → Genel → Giriş Öğeleri ve Uzantılar → **Hızlı Bakış** → **UDFViewer** işaretli olmalı.

## Geliştirici notları

Saf SwiftPM ile derlenir (tam Xcode gerekmez):

- `swift build -c release` + `scripts/build.sh` → `.app` ve iki `.appex` paketini elle monte edip ad-hoc imzalar (eklentiler `_NSExtensionMain` giriş noktasıyla kurulur).
- `kur.sh` bunu sarmalar: Command Line Tools'u kurar, derler, `/Applications`'a koyar, QuickLook eklentilerini kaydeder/etkinleştirir.
- İkon `scripts/make-icon.swift` ile üretilir (`assets/UDFViewer.icns`); `build.sh` ikon dosyası yoksa yeniden üretir.

## Kredi

Orijinal proje: [saidsurucu/udf-quicklook-extension](https://github.com/saidsurucu/udf-quicklook-extension). Bu fork; Apple Silicon dağıtım paketi (DMG + Homebrew cask), uygulama ikonu ve karşılama penceresi düzeltmelerini ekler.
