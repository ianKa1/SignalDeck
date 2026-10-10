# 02 spec-review (round 1) — fresh-context reviewer

**Verdict: FAIL** (one blocking defect; otherwise strong)

## Checklist

1. **Serves the notes, right-sized: yes.** Six characters with the queue's domains, each reading its own planet and houses (`focus.<id>`); a one-tap handoff; a picker with glyph, name, domain, two examples and a personalised placement line; per-character transcripts; D in every prompt via `roster.rules`. Jupiter's risk and Mercury's paste are both in. No invented scope: the Mercury paste field, auto-send and server memory are all excluded.
2. **Criteria checkable: yes.** I checked S3 against a real compute of chart A and all six sheets match: Moon Pisces/8/steady, Mars Aries/9/domicile, Jupiter Cancer/12/exaltation, Saturn Capricorn/6/domicile/retrograde [Ascendant opposition, Venus trine], Mercury Gemini/11/domicile. The cited file:lines match the code: models.py:388/423/451, turn.py:167/247, session-log.ts:89, ChatPanel.tsx:200-201, SessionBar.tsx:19, and apply.ts flattening one level.
3. **Contract: clean.** `/api/divination/sheets` is a pure compute, like `/api/chart`, not a rule-14 generative endpoint. Its purity pin with a bite and the unchanged sync-exceptions pin are right. The handoff is a validated enum from the side read. It rides `done` and is never parsed from prose (it follows the chartRefs precedent). Colour stays in tokens.ts, and `roster.css` maps variables only. The rule-10 fence is unchanged, `persona.py` stays pure, the route is identity-free and nothing is migrated. Voice and summary role text change with VERSION kept, which is consistent with the epic's "FINGERPRINT is provenance, never key material". The CLAUDE.md rule-10 amendment is stated.
4. **Non-goals and defaults: stated.** One gap is noted below (non-blocking).

## Blocking

**B1: no composition with dw-11, which is built in parallel.** The spec covers dw-9 and dw-12 but names dw-11 only in Non-goals ("dw-11 owns any change to [roster.timing]"). That covers only the order where dw-11 lands after dw-8. If dw-11 lands first, dw-8's merge inserts `roster.timing` ("you have not been given the current sky… name no dates, transits") into a prompt that now carries dw-11's sky section. The two instructions contradict each other, and nothing says which wins. Both features also edit `render.system_prompt`'s order and return expression, the chart-less and with-chart goldens, and CLAUDE.md rule 10, and probably `turn.py`/`main.py` and `test_boundaries.py`. dw-11's targets (Moon, Saturn, Jupiter) exist only after dw-8. **Fix:** add a "Composition with dw-11" bullet that:
- (a) fixes the landing order (dw-8 first, or "whichever lands second rebases");
- (b) rules that `roster.timing` is emitted only when the prompt carries no sky section, or that dw-11 replaces it, with a test that the two never co-occur;
- (c) lists the shared files and where dw-11's section sits in the order (e.g. after `chart`, before `dice`);
- (d) says who re-records the goldens.

## Non-blocking

- Jupiter has only one example question in the queue. Decide the second in the spec, with its zh, e.g. dw-11's "will the next step open things up?".
- S7: add a chart-less `chat` case. `side_schema` returns `MOOD_SCHEMA` on an empty catalogue (render.py:376), so the handoff field has to be added on that branch as well.
- The sheets contract calls `sheet_for` six times, which is six `natal_report` computes. Compute one report and call `persona_sheet` per planet instead.
- The `system_prompt` signature omits dw-9's `action=` kwarg. List it.
- Picker as a view: opening it mid-stream unmounts `ChatPanel` and stops the turn. State that, or keep the panel mounted. Picking an example of the already-active character does not remount a panel keyed by persona, so `seed` would not reapply. Key it by persona plus a seed nonce.
- `sanitize` cannot check handoff ≠ own persona without the persona. Define "valid" as `isPersonaId`.
- After dw-9, the stopped-entry path runs through the pacer's `flush()`. Cite that as the "existing path".
- A3's "quit my job" handoff depends on the LLM. Allow one rephrase or retry, and log both.
