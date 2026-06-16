---
title: "Phase 01 — Add read state to AlertModel"
---

## Overview

Add an explicit `read` boolean to `AlertModel` so the app can distinguish between alerts the user has seen and alerts still needing attention.

## Requirements

- `AlertModel` stores `read` (default `false`).
- `copyWith`, `fromMap`, `toMap` support `read` with backward-compatible defaults.
- New alerts are unread by default.

## Related Code Files

- Modify: `lib/models/alert_model.dart`
- Update tests: `test/alert_sorting_and_autoack_test.dart`

## Implementation Steps

1. Add `final bool read;` field to `AlertModel` after `acknowledged`.
2. Add `bool? read` parameter to `copyWith` and use `?? this.read`.
3. In `fromMap`, parse `read` from `map['read']` with default `0` (false) for backward compatibility.
4. In `toMap`, serialize `read` as `1/0`.
5. Update `_buildAlert` helper in `test/alert_sorting_and_autoack_test.dart` to accept optional `read`.

## Success Criteria

- `AlertModel` compiles and round-trips through `toMap`/`fromMap` preserving `read`.
- Existing tests continue to pass.

## Risk Assessment

- Existing persisted alert data lacks `read`; defaulting to `0` keeps behavior consistent (all old alerts treated as unread, so badge may temporarily spike; acceptable first run).
