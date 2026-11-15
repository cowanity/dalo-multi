# Dalỏ Multi v1.3

Unofficial native macOS multi-instance manager for Zalo Desktop. Dalỏ Multi is independent and is not affiliated with Zalo/VNG.

## What v1.3 adds

- native macOS design system with shared color, surface, radius and motion tokens
- clearer dashboard hierarchy with live running/update status
- unified control surfaces and calmer card elevation
- visible form labels and stronger empty/search states
- improved VoiceOver names for icon-only actions
- Reduce Motion support for dashboard, hover and global overlays

## Included from v1.2

- polished SwiftUI dashboard
- card / compact account views
- ⌘K command palette
- workspaces and launch groups
- window Split / Grid / Cascade + save/restore layout
- Update Center with safer clone rebuild
- Activity + RAM/PID/uptime monitoring
- Health Check and sanitized diagnostics
- configuration backup/import (Dalỏ preferences only)
- menu bar controller
- categorized Dalo icon picker
- first-run onboarding and friendly errors

The current Dalo logo/icon family remains locked and is not redesigned by v1.3.

## Build 3 macOS releases

Control-click `BUILD_ALL_DMG.command` → Open.

Output:

```text
Dalo-Multi-v1.3-macOS-AppleSilicon.dmg
Dalo-Multi-v1.3-macOS-Intel.dmg
Dalo-Multi-v1.3-macOS-Universal.dmg
SHA256SUMS.txt
release-manifest.json
```

Minimum target: macOS 14.

By default local builds are ad-hoc signed. Public GitHub releases should use Developer ID + Apple notarization.

## Privacy

Dalỏ does not read messages or copy passwords, tokens, login sessions or Keychain content. It does not redistribute Zalo Desktop; clones are rebuilt from the user’s own `/Applications/Zalo.app`.
