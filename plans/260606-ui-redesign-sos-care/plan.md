---
title: "UI Redesign SOS Care Flutter App"
description: "Redesign all screens to match reference image with red headers, bottom nav, modular widgets under 200 lines."
status: pending
priority: P1
effort: 14h
branch: main
tags: [ui, flutter, redesign, sos-care]
created: 2026-06-06
---

# UI Redesign SOS Care — Plan Overview

Redesign the SOS Care Flutter app to match the 9-screen reference image style: red gradient headers, persistent bottom navigation, card-based layouts, and modular widget files all under 200 lines.

## Key Decisions

- **Header style**: Red gradient `AppBar` (statusCritical-based) replaces the current white/dark AppBar.
- **Bottom nav**: Persistent `BottomNavigationBar` on main screens (Home, Alerts, Add, Settings, Account). Sub-screens (Detail, Map, etc.) use back-arrow AppBar without bottom nav.
- **File size limit**: Every file must stay under 200 lines. Large screens split into reusable widget files.
- **Theme compatibility**: Light/dark mode preserved; red header adapts slightly in dark mode (deeper red).
- **State management**: Keep existing `AppState` + `AnimatedBuilder` pattern. No new state libraries.

## Phase List

| Phase | Subject | Status | Effort |
|-------|---------|--------|--------|
| [01](phase-01-theme-and-shared-widgets.md) | Theme update + shared widgets (header, bottom nav) | pending | 2h |
| [02](phase-02-home-screen.md) | Home screen redesign + elderly card widgets | pending | 2h |
| [03](phase-03-detail-and-map.md) | Elderly detail + map view screens | pending | 2h |
| [04](phase-04-health-and-contacts.md) | Health tracking + emergency contacts screens | pending | 2h |
| [05](phase-05-alerts-flow.md) | Alerts list + add alert screens | pending | 2h |
| [06](phase-06-settings-and-account.md) | Settings refactor + notification settings + account | pending | 2h |
| [07](phase-07-integration-and-testing.md) | Bottom nav integration, compile check, testing | pending | 2h |

## Dependencies

- Phase 01 must complete before all others (shared widgets).
- Phase 07 must be last (integration across all screens).
- Phases 02–06 can run in parallel after Phase 01.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Existing screens exceed 200 lines after refactor | Medium | Medium | Extract widgets aggressively; use composition |
| Bottom nav state sync with AppState | Low | High | Wrap index in AppState or use `PageController` |
| Dark mode red header contrast | Low | Low | Test both modes in Phase 07 |
| Localization keys missing for new screens | Low | Medium | Add keys in Phase 01, use throughout |

## Rollback Plan

- Each screen refactor keeps original logic (WebSocket, simulation, alerts) intact.
- If build breaks, revert to last commit on `main`.
- No database migrations; all changes are UI-only.
