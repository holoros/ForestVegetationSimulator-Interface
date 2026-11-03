#!/bin/bash
# K3c2 fails the sign check (b3 > 0), so its bootstrap cannot change any verdict (PREREG_K3c compute order); stop it to free cores for PART 2.
cd ~/jobs/koa_rdcomp_20261102/constrained
while ! grep -q "done K3c1" logs/run_boot_c.log 2>/dev/null; do sleep 10; done
sleep 5; pkill -f "03c_boot.R --args K3c2" && echo "$(date) K3c2 bootstrap stopped (not rule-relevant: fails signs)" >> logs/run_boot_c.log
