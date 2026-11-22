#!/bin/bash
#SBATCH -J koa83
#SBATCH -A PUOM0008
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH -c 48
#SBATCH -t 03:00:00
#SBATCH -o out/slurm83_%j.log
# koa v142 rebuild: BYI patched (script 81: out-of-bag BYI at FIA training plots, C2 index without the 474 duplicate Eq. 1 rows),
# then the koa 1.15.0 chain (chain_1150.sh, chains C and D, M), the origin x size test (82), release, Bakuzis, figures and workbook.
# Each step runs only if the previous critical one exited 0.
JOB=$PWD; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 HOME=$JOB/home OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 KOA_CORES=48
cd $HOME/jobs/koa_1150_20261121; mkdir -p logs142
R() { tag=$1; shift; echo "$(date +%T) start $tag" >> $JOB/out/chain142.log; env "$@" > logs142/$tag.log 2>&1; s=$?; echo "$(date +%T) end $tag exit $s" >> $JOB/out/chain142.log; return $s; }
C() { R "$@" || { echo "$(date +%T) STOP at $1" >> $JOB/out/chain142.log; exit 1; }; }
R 83c Rscript scripts/83c_ratio_heightforms.R
R 83a Rscript scripts/83a_coverage_heldout.R
R 83b Rscript scripts/83b_bakuzis_lists.R
echo "$(date +%T) CHAIN 83 DONE" >> $JOB/out/chain142.log
