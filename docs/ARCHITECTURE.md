# Dalỏ Multi — Architecture

## Mục tiêu

Một repository có thể mở rộng theo nền tảng, nhưng **engine thực thi là platform-specific**.

```text
Dalỏ Product Layer
├── shared/
│   ├── contracts/          # schema dữ liệu trung lập nền tảng
│   └── assets/             # branding/icon
│
├── apps/
│   ├── macos/              # SwiftUI
│   ├── windows/            # tương lai: WinUI 3/.NET
│   ├── ios/                # tương lai: SwiftUI
│   └── android/            # tương lai: Compose
│
└── platform/
    ├── macos/engine/       # clone engine hiện tại
    ├── windows/engine/     # cần nghiên cứu riêng
    ├── ios/                # capability adapter riêng
    └── android/            # capability adapter riêng
```

## Nguyên tắc

UI không nên chứa logic clone Zalo. UI gọi một platform adapter/engine.

Hiện tại macOS UI gọi `manager.sh`; bước refactor tiếp theo có thể chuyển dần engine sang Swift service mà không thay đổi contract UI.

## macOS

- UI: SwiftUI + AppKit
- UI system: `DaloDesign` semantic tokens + native SwiftUI controls
- Design source of truth: `design-system/dal-multi/MASTER.md` with page overrides
- Engine: macOS app bundle / Electron clone logic
- Package: `.app` → `.dmg`
- Release architectures:
  - arm64
  - x86_64
  - universal

## Windows

Không tái sử dụng trực tiếp engine macOS. Windows sẽ cần nghiên cứu:
- vị trí cài Zalo
- Electron single-instance mechanism
- data directory
- helper processes
- code/package identity

UI đề xuất: WinUI 3.

## iOS / Android

Không nên giả định có thể “clone app” giống desktop.

- iOS bị giới hạn bởi code signing + sandbox; ứng dụng bên thứ ba không thể tùy ý clone một app khác.
- Android phụ thuộc sandbox, package ID, OEM work profile/app-clone capability và chính sách thiết bị.

Do đó mobile có thể chia sẻ branding, account model, settings và UX, nhưng **capability engine phải khác** và có thể không hỗ trợ multi-instance theo đúng cách desktop.
