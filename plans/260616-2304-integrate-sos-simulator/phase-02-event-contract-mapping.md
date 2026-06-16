# Phase 02 — Backend Event Contract & Elderly Mapping

## Context Links

- `Project_GiaLap/sos_care_backend/src/services/sos.service.js`
- `Project_GiaLap/sos_care_backend/src/services/event.service.js`
- `Project_GiaLap/sos_care_backend/src/services/location.service.js`
- `Project_GiaLap/sos_care_backend/src/services/deviceStatus.service.js`
- `Project_GiaLap/sos_device_simulator/lib/features/sos_simulator/data/models/*.dart`
- `lib/models/elderly_model.dart`
- `lib/utils/app_state.dart`
- Report: `reports/researcher-260616-socket-io-client.md`

## Overview

Define how each Socket.IO event is parsed and how the simulator’s string `deviceId` / `elderlyId` maps to `ElderlyModel.id` (`int`).

## Key Insights

- The backend emits five events: `sos:alert`, `event:fall`, `event:heart_rate`, `device:location`, `device:status`.
- Every payload contains `deviceId` and `elderlyId` strings; coordinates / status fields vary by event.
- Demo `ElderlyModel` data uses integer ids `1`, `2`, `3`; the simulator default is `ELDERLY-001`, whose numeric suffix `1` matches the first demo relative.
- No schema change to `ElderlyModel` is required; matching uses the existing `wearableDevice` field as a fallback.

## Requirements

- Functional: every backend event either updates an existing relative or creates a temporary one; unmatched events are never silently dropped.
- Non-functional: mapping logic is deterministic, unit-testable, and avoids extra model fields.

## Architecture

- `DeviceEventService` owns a pure `resolveElderlyId(String elderlyId, {String? deviceId})` helper.
- Resolution order: numeric suffix of `elderlyId`; then `deviceId` == `ElderlyModel.wearableDevice`; then create a temporary relative with a generated negative id.

## Related Code Files

- Read for context: the four backend service files and the four simulator payload model files.
- Modify: `lib/services/device_event_service.dart` (created in phase 03).
- No `ElderlyModel` schema change is required.

## Implementation Steps

1. Document the payload shapes observed from the backend:
   - `sos:alert`: `{id, deviceId, elderlyId, type, latitude, longitude, timestamp, status, createdAt}`
   - `event:fall`: same shape, `type: 'FALL_DETECTED'`
   - `event:heart_rate`: same shape, `type: 'HEART_RATE_ALERT'` (no explicit BPM field)
   - `device:location`: `{id, deviceId, elderlyId, latitude, longitude, timestamp, createdAt}`
   - `device:status`: `{id, deviceId, elderlyId, batteryPercent, heartRateBpm, isOnline, timestamp, createdAt}`
2. Implement safe parsing helpers in `device_event_service.dart`: `_asMap`, `_string`, `_double`, `_int`, `_bool`, `_timestamp`.
3. Implement `_resolveElderlyId`:
   ```dart
   int? _resolveElderlyId(String elderlyId, {String? deviceId}) {
     final numeric = int.tryParse(elderlyId.replaceFirst(RegExp(r'^ELDERLY-'), ''));
     if (numeric != null && AppState().relatives.any((e) => e.id == numeric)) return numeric;
     if (deviceId != null) {
       final match = AppState().relatives.cast<ElderlyModel?>().firstWhere(
         (e) => e!.wearableDevice == deviceId, orElse: () => null);
       if (match != null) return match.id;
     }
     return null;
   }
   ```
4. Implement `_ensureElderlyExists(String elderlyId, String deviceId, double lat, double lng)` that returns an `int id`. If no match exists, create a temporary `ElderlyModel` with `id = -DateTime.now().millisecondsSinceEpoch`, name = `"Người thân $elderlyId"`, a default safe zone centered on `lat`/`lng`, and call `AppState().addElderly(...)`.

## TODO

- [ ] List exact backend payload fields per event.
- [ ] Write `_resolveElderlyId` and temp-elderly creation.
- [ ] Add unit tests for mapping logic with `ELDERLY-001`, `ELDERLY-999`, and `deviceId` fallback.

## Success Criteria

- `ELDERLY-001` resolves to the existing relative id `1`.
- An unknown id such as `ELDERLY-999` creates a temporary relative and receives alerts.
- Unit tests for the mapping helper pass.

## Risk Assessment

- If the simulator changes the `elderlyId` prefix or format, numeric-suffix parsing breaks. Mitigation: keep the `deviceId` fallback and document the assumed format.
- Temporary relatives may clutter the relative list. Mitigation: they are clearly named and can be deleted by an admin; limit temp creation to events that need UI visibility.

## Security Considerations

- Do not evaluate `elderlyId` as code; parse only with `int.tryParse`.
- Avoid logging raw device payloads that may contain personal identifiers.

## Next Steps

- Phase 03 to implement the Socket.IO connection and event handlers.
