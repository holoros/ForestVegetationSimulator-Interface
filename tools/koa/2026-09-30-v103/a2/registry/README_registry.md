# koa v103 number registry

This folder holds numbers_v103.json, the registry of every number quoted in the manuscript and supplement, rebuilt on the v103 engine. It has the 93 keys of numbers_v102.json plus 13 new v103 keys, 106 in all. Every entry reads key -> {value, units, source, note}.

How it was built. The track3 stage scripts of koa_v102_20260918 are copied unchanged. Pristine copies are in v102_scripts, and 18 of them were checked identical to their working copies. Each stage was rerun on v103 inputs by the run_*.sh wrappers here: s01 accounting, s02 height with LOIO, s05 trajectory metrics, s06 survival respecification, s07 validation equivalence, long term and scenario runs, clip shares, joint_diag, ceiling, planted mortality level, a natural mortality gate, and proto_mort. Stages that write into an engine ran on registry copies (engine, and engine_nocal with MORT_CAL (1, 1)). The stage12 summary was rerun by stage12/stage12_summary_v103.R. The increment keys (inc_variants, inc_coef, calibration, calibration_diag, k_source_boot, k_by_source) were computed directly from the v103 Stage A1 outputs in out/inc and out/v103_constants.json. The v102 increment chain fits a model form the v103 engine no longer uses, and each note says so. Keys that meant "the before engine" (suffix _record, _v97, _v98) now hold engine_v102.

Four keys are null. calibration_loio and loso are null because no leave-one-out refit exists for the v103 engine form fits. width_ratio and width_ratio_all_ages are null because the v103 Monte Carlo has joint draws only, with no independent draw run to divide by.

Gate. gate_v103.py derives 21 headline numbers two independent ways, and all 21 agree within tolerance (build/gate_v103.csv; last section of numbers_v103_vs_v102.md). Rerunning the natural mortality stage reproduces MORT_CAL 2.542751 and SE_LOG 0.243353 exactly.

To rebuild, run bash make_md.sh. It runs koa_numbers_v103.py, compare_v103_vs_v102.py and gate_v103.py. Logs are in logs. Leaf level comparisons are in build/leaves_v103_vs_v102.csv. No FIA coordinate column is read, because every csv reader refuses LAT and LON.

md5 (logs/md5_deliverables.txt)

d1211eb13f184d534dc8c73519b38442 numbers_v103.json
52029b27292673fae383217a8a5fbab4 numbers_v103_vs_v102.md
f20076ed115d2aa28ce765b536b405fd koa_numbers_v103.py
cadb00dacbae4879d8053167ad40f544 compare_v103_vs_v102.py
2ef9a28606f4f14a92cd1805c0dd6fae gate_v103.py
e8f57d083cb1728afdabbf0c353b15b7 make_md.sh
1a91d6aa96dd77f2a80ed7d8a2da7a79 stage12/stage12_summary_v103.R
e0fa439261abafeb2943d2309b7d046a build/gate_v103.csv
