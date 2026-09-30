# koa_rv_fiaagent_20260929
Date 2026-09-29. Host firebreather. Purpose: R2 c7, damage and disturbance attribution for the six FIA validation subplots (three FIA plots).
Inputs: ../koa_rv_byi_20260928/in/HI_TREE.csv, HI_COND.csv; ../koa_rv_mort_20260928/out_a2/point_with_level.csv (plot keys, server side only).
Method: agent.py joins the six validation subplots to HI_TREE and HI_COND, groups them as the heavy-loss plot (observed cohort survival < 0.5, four subplots of one plot) and the other two plots, and tabulates STATUSCD by INVYR, AGENTCD and DAMAGE_AGENT_CD1 to 3 of trees dead at the 2019 visit, and DSTRBCD1 to 3, DSTRBYR and TRTCD1 to 3 of the conditions at both visits. Only counts are printed; no plot key, CN or coordinate is written.
Run: python3 agent.py > agent.log
