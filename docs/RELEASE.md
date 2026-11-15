# macOS Release Guide

## Build 3 bản

Double-click / Control-click:

`BUILD_ALL_DMG.command`

Output:

```text
dist/
├── Dalo-Multi-v1.3-macOS-AppleSilicon.dmg
├── Dalo-Multi-v1.3-macOS-Intel.dmg
├── Dalo-Multi-v1.3-macOS-Universal.dmg
├── SHA256SUMS.txt
└── release-manifest.json
```

### Apple Silicon

Binary chỉ có `arm64`. Nhẹ nhất cho M1/M2/M3/M4/M5... và không cần Rosetta.

### Intel

Binary chỉ có `x86_64`, dành cho Mac Intel.

### Universal

Một binary chứa cả `arm64` và `x86_64`. Dễ phân phối nhất nhưng lớn hơn một chút.

## Vì sao build từ một máy được?

Xcode/macOS SDK có thể cross-compile cả `arm64` và `x86_64`. Universal được ghép bằng `lipo`.

Nếu Terminal trên Apple Silicon đang chạy bằng Rosetta, release builder tự re-exec bản thân qua `arch -arm64`.

## Ký để test cá nhân

Mặc định script dùng ad-hoc signing:

```bash
codesign --sign -
```

Dùng cá nhân/test được, nhưng không phải phương án public tốt nhất.

## Public GitHub: Developer ID + notarization

Sau khi có Apple Developer Program:

```bash
export MACOS_SIGN_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)'
```

Tạo notary keychain profile một lần:

```bash
xcrun notarytool store-credentials "dalo-notary"   --apple-id "YOUR_APPLE_ID"   --team-id "TEAMID"   --password "APP_SPECIFIC_PASSWORD"
```

Sau đó:

```bash
export NOTARY_PROFILE='dalo-notary'
./BUILD_ALL_DMG.command
```

Builder sẽ:
1. ký app với hardened runtime
2. verify signature
3. tạo DMG
4. ký DMG
5. gửi Apple notarization
6. staple ticket
7. validate ticket

## Kiểm tra release

```bash
lipo -archs "Dalo Multi.app/Contents/MacOS/DaloMulti"
codesign --verify --deep --strict --verbose=2 "Dalo Multi.app"
hdiutil verify Dalo-Multi-*.dmg
shasum -a 256 Dalo-Multi-*.dmg
```
