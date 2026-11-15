# Changelog

## v1.3

### UI system
- Added a native macOS design-token layer for brand, semantic status colors, surfaces, borders, radius and motion.
- Reworked the overview hierarchy into a clearer control center with live running and update status.
- Unified metric cards, account rows, workspace cards, update rows and activity rows with calmer native surfaces.
- Added a status footer and discoverable Command Palette entry in the sidebar.

### Accessibility and interaction
- Added VoiceOver labels, values and hints to key icon-only controls and icon selections.
- Added visible field labels and helper text to the clone wizard.
- Added explicit empty results to dashboard search and Command Palette search.
- Respect Reduce Motion for global overlays, dashboard updates and card hover feedback.
- Removed layout-shifting hover scale from account cards.

### Compatibility
- Preserved the v1.2 Command Palette `@FocusState` fix.
- Preserved the clone engine, profile paths, safe rebuild flow and locked icon family.

## v1.2

- Fixed Command Palette `@FocusState` binding compile error (`.focused($focused)`).


### UX & Productivity
- Redesigned native macOS overview with improved spacing, typography and hierarchy.
- Card and Compact account modes.
- Favorites section, search, sorting and manual ordering.
- ⌘K command palette with account search and quick actions.
- Workspace groups with preferred window layout.
- Split, Grid and Cascade Zalo window arrangements.
- Save and restore Zalo window positions.
- Improved menu bar controller and “open next available account”.

### Maintenance
- Dedicated Update Center.
- Safe clone rebuild now keeps the previous app bundle until the new signed bundle swaps into place.
- Health Check and sanitized diagnostics remain available.
- Configuration export/import for Dalỏ metadata and preferences only.

### Visibility
- Activity Center with recent actions.
- RAM, PID and uptime overview for running accounts.
- Success toast feedback and clearer error guidance.

### Polish
- First-run onboarding.
- Better empty states.
- Hover transitions and restrained animations.
- Categorized icon picker and redesigned clone wizard.
- In-memory icon cache and default status refresh interval changed to 5 seconds.

### Privacy
- No message reading.
- No password/token/Keychain copying.
- No multi-app expansion.
- Dalo logo and finalized icon family are treated as locked assets.
