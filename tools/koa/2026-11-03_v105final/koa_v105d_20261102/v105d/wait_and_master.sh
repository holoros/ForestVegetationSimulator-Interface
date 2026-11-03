cd ~/jobs/koa_v105d_20261102
while ! grep -qE "STAGE_B DONE|STOP" v105d/logs/stage_b.log; do sleep 30; done
if grep -q "STAGE_B DONE" v105d/logs/stage_b.log; then bash v105d/master_d.sh > v105d/logs/master_d.log 2>&1; else echo "stage B stopped" > v105d/logs/master_d.log; fi
