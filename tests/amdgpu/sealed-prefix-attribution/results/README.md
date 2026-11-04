# Prefix replay attribution: negative result

The fixed Stage A cost gate failed: **0 of 5 cases qualified**. The suspension proposal was rejected before production implementation; no retuning followed.

The instrumentation-only source is `4be3a57f7493271d635f9e9399dd1998c1c4ce49` on parent `f0ee44285286aa1ea92f3e99aed6574ad89f3c82`. The immutable current-ON executable is `57d555dbafee093f804b2c0744c477c4a5e567726aece81017f828647bdbc167`; the separate instrumented executable is `d58991cdb7d41ec42744068caacb2e65a6e0559c27e675c0b3895585029ed45e`.

All 26 declared configurations ran exactly 5 times: 65 certified hazardous-prefix rejections and 65 safe graph analyses. All 130 phase records and archived outcome/first-witness/export comparisons were valid. The 13 safe controls retained complete exports; 11 had previously proved equations and 2 remain unproved. This collection creates no new mathematical proofs.

A gate case needed both median final replay >=1ms and median per-observation final-replay share >=15% of parent marker-reception wall time. At least 3/5 cases had to qualify.

| Fixed gate case | Median final replay (ns) | Median per-sample parent share | Qualifies |
| --- | ---: | ---: | --- |
| `memory-gfx950-normalization-address-alias` | 2124301 | 0.09665767445436416 | no |
| `memory-gfx950-gemm-address-alias` | 975159 | 0.05230857779551443 | no |
| `memory-gfx1250-normalization-address-alias` | 2296080 | 0.09432437496522206 | no |
| `memory-gfx1250-gemm-address-alias` | 1376059 | 0.06578248791322619 | no |
| `memory-gfx1250-attention-address-alias` | 925364 | 0.05063720800422849 | no |

[All 130 observations and all 26 summaries](observations.json) retain full numeric precision. [All 130 case/phase distribution rows](phase-distributions.csv) give min/median/max exclusive nanoseconds, calls and per-observation shares over exactly 5 observations; these are descriptive distributions, not tail estimates.

Hazard endpoints are parent-observed certified-marker reception; safe endpoints are full process completion including export. Phases are exclusive wall-clock observations. Startup, parsing, rendering/export and recorder-write work outside the pipeline span remain unassigned. No CPU attribution, speedup comparison, GPU result or replacement implementation is claimed.

Raw report SHA-256: `b7b5fc03a96b1d416f8ddcea44b3015760e2a7721f61f8740248649623419b9d`. Plan SHA-256: `42abaf77f355f0e909e4100abf8fc18192ead98b961c857ad6d4c171018732e2`. Public observations SHA-256: `d860f1ff12b6897fee1154966febc22e426bd8bcb22d242ef511e8fea2d207b2`. Distribution CSV SHA-256: `ee6b5e1a316cd778931b25e107b6462536209612a170d5c9a4894d114370c15b`.

The [independent raw audit](independent-audit.json) passed 8,317 checks with zero errors, verifying all 130 records, 5,654,460,115 retained safe-expression bytes and 125,400 coordinates. Its SHA-256 is `e82f6a53aeb2fcd77b28734ecfe794c69c524fbd47d17fec50ea08585613c79a`.

Regenerate with the publisher and the exact bound raw plan/report/patch, selection and protocol. Independent raw/projection audit receipts are bound separately, avoiding a self-hash cycle. The earlier study remains unchanged.
