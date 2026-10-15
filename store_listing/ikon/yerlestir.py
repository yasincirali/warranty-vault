"""render.js çıktısını (ikon.png, isaret.png) platform klasörlerine dağıtır.

Açılış rengi #0F2E28: ikonun gradyanının ortası. Uygulamadaki açılış animasyonu
(VBrand.splash) aynı rengi kullanır; böylece sistem açılış ekranından Flutter'a
geçişte zemin ve işaret yerinden oynamaz. Değiştirirsen ikisini birlikte değiştir.
"""
from pathlib import Path
from PIL import Image

kok = Path(__file__).resolve().parents[2]
ikon = Image.open('ikon.png').convert('RGB')  # App Store alfa kanalı kabul etmez
isaret = Image.open('isaret.png').convert('RGBA')

def kaydet(img, yol, px):
    yol.parent.mkdir(parents=True, exist_ok=True)
    img.resize((px, px), Image.LANCZOS).save(yol, optimize=True)

ios = kok / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for pt, olcekler in [(20, [1, 2, 3]), (29, [1, 2, 3]), (40, [1, 2, 3]), (60, [2, 3]),
                     (76, [1, 2]), (83.5, [2]), (1024, [1])]:
    for s in olcekler:
        ad = f'{pt:g}x{pt:g}'
        kaydet(ikon, ios / f'Icon-App-{ad}@{s}x.png', round(pt * s))

# Açılış işareti 160 pt; Flutter'daki animasyon da 160 pt'de, aynı merkezde başlar.
acilis = kok / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
for s, ek in [(1, ''), (2, '@2x'), (3, '@3x')]:
    kaydet(isaret, acilis / f'LaunchImage{ek}.png', 160 * s)

res = kok / 'android/app/src/main/res'
for klasor, k in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    kaydet(ikon, res / f'mipmap-{klasor}/ic_launcher.png', round(48 * k))
    # Uyarlanır ikon ön planı 108 dp; işaret 66 dp güvenli dairenin içinde kalsın diye
    # tuvalin %80'ine küçültülür (çizim tuvalin ~%69'unu kaplar → ~60 dp).
    on = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    k80 = isaret.resize((820, 820), Image.LANCZOS)
    on.paste(k80, (102, 102), k80)
    kaydet(on, res / f'mipmap-{klasor}/ic_launcher_foreground.png', round(108 * k))
    kaydet(isaret, res / f'drawable-{klasor}/acilis_isareti.png', round(160 * k))
print('tamam')
