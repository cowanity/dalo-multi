# Dalỏ Multi — Overview Override

This page is the daily control center. It prioritizes current system state and
fast account actions over decorative content.

## Hierarchy

1. Brand header with live running/update summary and one primary action: **Thêm tài khoản**.
2. Four scan-friendly metrics: account count, running count/RAM, update health and workspaces.
3. Update warning only when action is required.
4. Search, sort, display mode and refresh in one bounded control surface.
5. Original account, favorites, then remaining clones.
6. Bulk actions and refresh timestamp in a low-emphasis footer.

## Interaction rules

- Keep Command Palette visible through both `⌘K` and the sidebar affordance.
- Search must show an actionable empty state instead of a blank result area.
- Status uses text and icon/shape in addition to color.
- Card hover may change border/elevation but must not shift layout.
- Icon-only controls require a tooltip and an accessibility label.
- Preserve the v1.2 `@FocusState` binding fix.
