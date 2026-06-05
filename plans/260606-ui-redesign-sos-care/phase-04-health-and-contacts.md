---
title: "Phase 04 — Health Tracking and Emergency Contacts"
description: "Create health tracking screen and emergency contacts screen with red headers and modular lists."
status: pending
priority: P1
effort: 2h
created: 2026-06-06
---

# Phase 04 — Health Tracking and Emergency Contacts

## Context Links
- `lib/models/elderly_model.dart`
- `lib/widgets/sos_app_header.dart`
- `lib/utils/localization.dart`

## Overview
Create two new screens:
- `HealthTrackingScreen`: centered avatar, 4 vital metrics, status badge, action buttons (call, message, SOS).
- `EmergencyContactsScreen`: list of contacts with avatar, name, relationship, phone, red "Call now" button per row, plus "Add new contact" FAB.

## Key Insights
- Health tracking is essentially a simplified read-only version of Detail focused on vitals.
- Emergency contacts currently live inside `detail_screen.dart` as a simple list. The new screen elevates them to a full management UI.
- `ElderlyModel.emergencyContacts` is `List<String>` (phone numbers only). The reference image shows name + relationship + avatar. We need a new model `EmergencyContact` or reuse `ElderlyModel` with enriched contact list.

## Requirements

### Functional

**Health Tracking Screen**
- Red header "Theo dõi sức khỏe" via `SosAppHeader`.
- Large centered avatar (radius 50).
- Name and status badge below avatar.
- 2x2 grid of vitals: heart rate, SpO2, temperature, blood pressure.
- Bottom action row: Call (green), Message (blue), SOS (red).
- Data sourced from selected `ElderlyModel`.

**Emergency Contacts Screen**
- Red header "Danh bạ khẩn cấp" via `SosAppHeader`.
- List of contacts. Each contact has: avatar, name, relationship label, phone number.
- Red "Call now" button per contact row.
- Floating "Add new contact" button at bottom (or FAB).
- Placeholder/mock contacts if model not enriched yet.

### Non-functional
- Each file < 200 lines.
- Reuse `MetricCard`, `VitalBadge`, `BigButton` where possible.

## Architecture

```
lib/models/
  emergency_contact_model.dart   (new, optional if enriching contacts)
lib/screens/
  health_tracking_screen.dart    (new, <200 lines)
  emergency_contacts_screen.dart (new, <200 lines)
lib/widgets/
  contact_list_item.dart         (new, <80 lines)
```

## Related Code Files

### Create
- `lib/screens/health_tracking_screen.dart` — health tracking UI
- `lib/screens/emergency_contacts_screen.dart` — contacts management UI
- `lib/widgets/contact_list_item.dart` — single contact row
- `lib/models/emergency_contact_model.dart` — `name`, `relationship`, `phone`, `avatarUrl` (optional, only if needed)

### Modify (optional)
- `lib/models/elderly_model.dart` — change `emergencyContacts` from `List<String>` to `List<EmergencyContact>` if plan includes data migration. **Decision**: keep `List<String>` for now to avoid breaking existing serialization; display contacts as simple phone list with generic avatars. Add a TODO to migrate later.

## Implementation Steps

1. **Create contact_list_item.dart**
   - Stateless widget `ContactListItem`.
   - Props: `avatarUrl`, `name`, `relationship`, `phone`, `onCallTap`.
   - Build: `ListTile`-style row with avatar leading, name/relationship subtitle, red `ElevatedButton` trailing with "Call now" label.

2. **Create emergency_contacts_screen.dart**
   - Props: `elderlyId`.
   - Use `AnimatedBuilder` to watch `AppState` and get current elderly.
   - `SosAppHeader` with back button.
   - Body: `ListView` of `ContactListItem`s built from `elderly.emergencyContacts`.
   - For each phone string, display phone as name, relationship as "Người giám hộ", generic avatar.
   - FAB or bottom button: "Add new contact" (shows placeholder dialog or reuses `AddRelativeDialog` pattern).

3. **Create health_tracking_screen.dart**
   - Props: `elderlyId`.
   - Use `AnimatedBuilder`.
   - `SosAppHeader` with title `Localization.translate('healthTracking')`.
   - Body `SingleChildScrollView`:
     - Centered `CircleAvatar` radius 50.
     - Name text, status badge.
     - `HealthMetricsPanel` (reuse from Phase 03).
     - Row of 3 action buttons: Call, Message (push `SendSmsScreen`), SOS (push `RemoteSosScreen`).

## Todo List

- [ ] Create `contact_list_item.dart`
- [ ] Create `emergency_contacts_screen.dart`
- [ ] Create `health_tracking_screen.dart`
- [ ] Decide on `EmergencyContact` model enrichment (defer to future phase)
- [ ] Verify navigation from Detail or Home to these screens works
- [ ] Run compile check

## Success Criteria
- Health tracking renders avatar + 4 vitals + 3 action buttons.
- Emergency contacts renders list with call buttons.
- Both screens use red header.
- File sizes under 200 lines.

## Risk Assessment
- **Risk**: `emergencyContacts` is just phone strings — no names/avatars. **Mitigation**: Display phone as primary text, generic avatar, relationship as static label. Document TODO for model enrichment.

## Next Steps
- Phase 05 (Alerts flow) and Phase 06 (Settings & Account) can run in parallel after this.
