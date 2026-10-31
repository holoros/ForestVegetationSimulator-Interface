cd ~/jobs
grep -rlE --include=*.py --include=*.R "0\.2, ?5|local.?mult|lvl_loio|level_loio|mortcal_loio|MORT_CAL.*loio|held" koa_* rt* 2>/dev/null | grep -v -E "/engine[^/]*/|/export/|/stage/|/zen" > ~/jobs/koa_v104_20261030/a5/rerun/logs/find_traj.txt
grep -rlE --include=*.py --include=*.R "rq\(|quantreg|QuantReg" koa_* 2>/dev/null | grep -v -E "/export/|/stage/|/zen" > ~/jobs/koa_v104_20261030/a5/rerun/logs/find_qr.txt
grep -rlE --include=*.py --include=*.R "contrast" koa_* 2>/dev/null | grep -v -E "/engine[^/]*/|/export/|/stage/|/zen" > ~/jobs/koa_v104_20261030/a5/rerun/logs/find_contrast.txt
grep -rlE --include=*.py --include=*.R "M4|M5|kappa|0\.1467" koa_* 2>/dev/null | grep -v -E "/engine[^/]*/|/export/|/stage/|/zen" > ~/jobs/koa_v104_20261030/a5/rerun/logs/find_s22.txt
echo FINDDONE
