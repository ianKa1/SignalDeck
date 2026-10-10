# 05 designing: dw-3-chart-grounded-reply (revision round 2)

This revision fixes the FAIL in `04-spec-review.md`. Only the named defect
and the non-blocking note were changed.

## Changes

- **D3: Architecture › Amendments › `test_boundaries.py`.**
  - `test_divination_imports_only_llm_prompts_chart_dictionary` is RETIRED,
    because the borrow line would turn it red.
  - It is folded into `test_divination_borrows_only_the_restate_helper`,
    which runs the same `DIVINATION_FORBIDDEN_RE` check over every
    divination file. Only the one exact borrow line is stripped from
    render.py first, and that line must appear exactly once.
  - All six old self-checks are kept: interpretation, `from .. import jobs`
    and cards are caught; llm, prompts and chart pass.
  - The regex is not widened.
- **D3: S10.**
  - S10 now names the old test as retired and requires that it no longer
    exists (grep finds no definition).
  - It requires the six self-checks to be kept.
  - It requires `DIVINATION_FORBIDDEN_RE` to be byte-identical to dw-2's.
- **Non-blocking note: where `isChartRef` lives.**
  - `isChartRef` lives in `packages/core/src/divination/types.ts` and is
    exported from the divination barrel.
  - `BODIES` is a VALUE import from the `../chart` barrel, where it is
    exported at `chart/index.ts:12`. It is not a type-only import.

## Word counts (`wc -w`)

| Section | Words |
|---|---|
| Spec without criteria | 1,201 |
| Architecture | 1,456 |
| Criteria | 1,077 |

Both budgeted sections are within 1,500. The criteria are exempt.

## Transition

designing (revision 2) → spec-review (round 3).
