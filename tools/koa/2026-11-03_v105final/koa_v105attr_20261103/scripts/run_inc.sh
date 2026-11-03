# increment refits under SDImax_pop: K3c1 dDBH + K3c1h dHT (D742), K3c1 dDBH + v105c-form dHT (R_dHT). frames are not changed (no RD columns).
J=~/jobs/koa_v105attr_20261103; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
( cd $J/D742 && KOA_DDBH_FORM=K3c1 KOA_DHT_FORM=K3c1h Rscript --vanilla track2/inc/inc_v103.R all > $J/logs/inc_D742.log 2>&1; echo "inc D742 $? $(date)" ) &
( cd $J/R_dHT && KOA_DDBH_FORM=K3c1 KOA_DHT_FORM=v105b Rscript --vanilla track2/inc/inc_v103.R all > $J/logs/inc_R_dHT.log 2>&1; echo "inc R_dHT $? $(date)" ) &
wait; echo INC DONE $(date)
