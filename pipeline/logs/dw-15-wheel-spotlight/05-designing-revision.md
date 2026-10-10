# 05 designing — revision 2 (coordinator, wording only; per 04-spec-review.md)
1. G15 scope: the Dependency-rules line and the CLAUDE.md rule-1 amendment now say "within the three walked source trees", and name `app-native/jest/skia-env.js:27` as the pre-existing jest-harness importer outside G15's walk. The guard itself is unchanged.
2. G1's last sentence now reads: the K1/K2 test gets CanvasKit only through `engine.ts`'s `initCanvasKit` and has no `canvaskit-wasm` import specifier (its locate path is a plain string).
Optional notes applied: `locateFile` uses `.pathname` rather than `href` (Risks); K2 fixes glow at 1.0 and `u_time` near the breathing peak. The F4 wording nit was left as is (the assertion is correct).
Status: spec-review round 3 (the last round allowed before `blocked`).
