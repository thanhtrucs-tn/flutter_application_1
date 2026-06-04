'use strict';

/**
 * Shared allowlist `reason` validator for skill-routing-allowlist.json and
 * skill-description-lint-allowlist.json.
 *
 * Audit-trail rule: an allowlist entry MUST carry a real justification.
 * Empty / whitespace-only / placeholder strings ("ok", "tbd", ".") defeat
 * the purpose. Enforce a minimum content length so future maintainers
 * can't rubber-stamp entries.
 */

const MIN_REASON_LENGTH = 20;

/**
 * Validate an allowlist entry's `reason` field.
 *
 * @param {unknown} reason — the reason value to validate
 * @returns {{ ok: true } | { ok: false, error: string }}
 */
function validateReason(reason) {
  if (typeof reason !== 'string') {
    return { ok: false, error: 'missing required "reason" field (must be a string)' };
  }
  const trimmed = reason.trim();
  if (trimmed.length === 0) {
    return { ok: false, error: 'has empty "reason" field' };
  }
  if (trimmed.length < MIN_REASON_LENGTH) {
    return {
      ok: false,
      error: `"reason" too short (${trimmed.length} chars, need ≥${MIN_REASON_LENGTH}). Placeholder strings like "ok" or "tbd" are not real justifications.`,
    };
  }
  return { ok: true };
}

module.exports = { validateReason, MIN_REASON_LENGTH };
