# Joint Monte Carlo patch, 2026-09-16 (v99)

patch_jointmc.py (2026-09-16, v99 round): switch the engine Monte Carlo to joint, source-level parameter rows.
Usage: python3 patch_jointmc.py ENGINE_DIR JOB_DIR
cal_reset restores every base value and rewinds the row counter. cal_draw reads the next row of
out_joint/K_joint_draws.csv and sets the height vector, both increment vectors, the four origin multipliers,
the Stage 1 occurrence coefficients with their mean annual occurrence, and the natural mortality level.
The call sits after the drivers' own normal draws, so the Garcia alpha and the diameter CF streams are unchanged,
and the drivers' independent height and b8 draws are overwritten by the joint row.
