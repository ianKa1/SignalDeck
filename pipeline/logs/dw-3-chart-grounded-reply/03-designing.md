# 03 designing: dw-3-chart-grounded-reply (revision round 1)

This revision answers the FAIL in `02-spec-review.md`. Only the named
defects were changed.

- **D1**: S1 and the `render.natal_context` contract now match the real
  signature. `r = natal_report(person)` is a dict `{"chart","structure"}`,
  and the comparisons are against `_restate(r["chart"], r["structure"])`
  and `relevant_meanings(r["chart"], r["structure"])`. I searched the whole
  spec for `natal_report` and `_restate(`; no other place had the wrong
  unpacking. The reuse row and the dependency rule only name the function.
- **D2**: `packages/core/src/divination/transcript.ts` is now in the module
  map. Its contract is that `sanitize` keeps `chartRefs` only when it is a
  non-empty array after filtering through `isChartRef`, and omits it
  otherwise. C2 now also checks a fresh KV read and that malformed stored
  refs are dropped.
- **Non-blocking S3 note**: S3 now first asserts that the fixture chart has
  no Venus–Mars square in either order. I checked this against the
  designing probe: the chart has no Venus–Mars aspect at all.

## Word counts (`wc -w`)

| Section | Words |
|---|---|
| Spec without criteria (Goal, Non-goals, Decided defaults) | 1,201 |
| Architecture | 1,366 |
| Criteria | 1,030 |

Both budgeted sections are within 1,500. The criteria are exempt.

## Transition

designing (revision) → spec-review (round 2).
