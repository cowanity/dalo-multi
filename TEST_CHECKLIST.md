# Dalỏ Multi v1.3 Test Checklist

## Build
- [ ] Apple Silicon DMG builds and verifies
- [ ] Intel DMG builds and verifies
- [ ] Universal contains arm64 + x86_64

## Core clone regression
- [ ] Zalo original opens
- [ ] existing clone opens from Dalỏ button
- [ ] clone also opens from Dock
- [ ] original + multiple clones run together
- [ ] quit/reopen keeps independent sessions
- [ ] new clone creation works
- [ ] icon change works when clone is stopped

## v1.3 UI/UX
- [ ] Dashboard hierarchy is readable in Light and Dark appearance
- [ ] Card and compact layouts remain usable at the minimum window size
- [ ] VoiceOver announces icon-only actions with useful names
- [ ] Reduce Motion removes non-essential hover/overlay animation
- [ ] Empty search states appear in Dashboard and Command Palette
- [ ] Clone wizard shows persistent labels and focuses the name field

## v1.2 workflow regression
- [ ] onboarding shows once
- [ ] Card / Compact switch
- [ ] ⌘K palette
- [ ] search/favorites/sort
- [ ] menu bar account actions
- [ ] open next available account

## Workspace
- [ ] create/edit workspace
- [ ] open/quit workspace
- [ ] Split/Grid/Cascade with Accessibility permission
- [ ] save/restore positions

## Maintenance
- [ ] Update Center detects outdated clone
- [ ] update stopped clone preserves data/session/name/icon
- [ ] safe rebuild does not remove working bundle before replacement is ready
- [ ] Health Check
- [ ] diagnostic export
- [ ] config export/import

## Privacy
- [ ] no message contents in diagnostics
- [ ] no password/token/Keychain copy
