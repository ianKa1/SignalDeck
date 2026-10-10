# 01 · designing (2026-09-30)

Started fresh (previous coordinator stopped at `designing` with no spec).
Skills invoked in order: /frontend-design (visual bar), /feature-spec (pipeline
mode: Goal, Non-goals, Decided defaults, Acceptance Criteria),
/architecture-designer (pipeline mode: Architecture section only).

Targeted reads: App.tsx, account/SignInGate.tsx, account/useAccount.ts,
opening/OpeningPrototype.tsx + opening.test.tsx, platform/account-boot.ts,
platform/device-wipe.ts, theme/ground-store.ts, theme/reload.ts,
i18n/lang-store.ts, birth-input/BirthSheet.tsx, settings/SettingsScreen.tsx,
settings/LocationRow.tsx (header), core account/sync.ts + service.ts + index.ts,
App.test.tsx, text-variant-guard residue block, native-guards cost-gate and
raw-literal walks; rn-forced-signin spec D16 + validating log 11 (device recipe).

Key decisions (spec "Decided defaults"):
- one threshold page: OpeningPrototype hosts the gate controls as children;
  wordmark removed; buttons after the words finish (D1–D3);
- setup trigger = signed-in ∧ pull succeeded ∧ no device birth data; pull
  failure → no setup (D4); a new core sync-phase channel exposes the pull;
- appearance needs the existing reload; a progress key `astrology.setup.v1`
  resumes setup and makes the opening `still` after the reload (D5, D7);
- birth form body lifted out of BirthSheet into BirthForm, shared (D9);
- "location" = birth place; the current-location anchor stays in Settings;
- device harness: monkeypatched google verifier + temporary uncommitted
  googleIdToken stub (D14).
- Supersedes (tier 3): opening-animation-prototype spec-review approval
  (standalone hand-off page) and rn-forced-signin spec-review approval
  (its D16 wordmark gate).

Spec: pipeline/specs/rn-onboarding-after-signin.md (24 criteria).
Transition: designing → spec-review
