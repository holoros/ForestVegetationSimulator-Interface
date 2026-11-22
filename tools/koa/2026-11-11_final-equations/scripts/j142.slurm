#!/bin/bash
#SBATCH -J koa142
#SBATCH -A PUOM0008
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH -c 48
#SBATCH -t 08:00:00
#SBATCH -o out/slurm142_%j.log
# koa v142 rebuild: BYI patched (script 81: out-of-bag BYI at FIA training plots, C2 index without the 474 duplicate Eq. 1 rows),
# then the koa 1.15.0 chain (chain_1150.sh, chains C and D, M), the origin x size test (82), release, Bakuzis, figures and workbook.
# Each step runs only if the previous critical one exited 0.
JOB=$PWD; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 HOME=$JOB/home OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 KOA_CORES=48
cd $HOME/jobs/koa_1150_20261121; mkdir -p logs142
R() { tag=$1; shift; echo "$(date +%T) start $tag" >> $JOB/out/chain142.log; env "$@" > logs142/$tag.log 2>&1; s=$?; echo "$(date +%T) end $tag exit $s" >> $JOB/out/chain142.log; return $s; }
C() { R "$@" || { echo "$(date +%T) STOP at $1" >> $JOB/out/chain142.log; exit 1; }; }
C 81 Rscript scripts/81_patch_byi_v142.R
C 20 Rscript scripts/20_sdimax_byi.R
C 21 Rscript scripts/21_sdimax_followup.R
C 22t Rscript scripts/22t_rdbyi_final.R
R 82 Rscript scripts/82_e4_origin_size.R
C 23t Rscript scripts/23t_rdbyi_items.R
C 28a Rscript scripts/28a_heldout_and_deathrules.R
R 28b Rscript scripts/28b_installation_bootstrap.R
R 27 Rscript scripts/27_sdimax_at_percentiles.R
R 29 Rscript scripts/29_verify_and_thinning.R
R 29b Rscript scripts/29b_s1_without_kap.R
C 44 Rscript scripts/44_height_increment_round4.R
R 45 KOA_NBOOT=500 Rscript scripts/45_boot_round4.R
C 50 Rscript scripts/50_ingrowth_qmd.R
C 51 Rscript scripts/51_j1_items.R
R 52 Rscript scripts/52_j1_eval_items.R
R 58 Rscript scripts/58_rd_cap_sensitivity.R
C 64 Rscript scripts/64_longterm_metrics_e3e.R
R 64b Rscript scripts/64b_fig3_figS4_v140.R
R 57b Rscript scripts/57b_fig4_fig5_v137.R
R 33 Rscript scripts/33_height_increment.R
R 33b Rscript scripts/33b_height_increment_round2.R
R 42 Rscript scripts/42_height_increment_round3.R
R 35 Rscript scripts/35_stand_mortality.R
R 46 Rscript scripts/46_height_increment_maxmod.R
R 15 KOA_CORES=8 Rscript scripts/15_rd_final.R
R 25 Rscript scripts/25_compare_censored.R
C 67 Rscript scripts/67_release_1150.R
R 68 Rscript scripts/68_bakuzis_full_1150.R
(cd bakuzis_1150 && for f in traj_natural_d*.csv traj_planted_d*.csv traj_ref_density.csv; do echo "=== $f"; Rscript ../scripts/bakuzis_check.R $f 0.40 0.10; done > ../logs142/68_check.log 2>&1; Rscript ../scripts/bakuzis_matrix.R traj_ref_density.csv matrix_ref_density.png >> ../logs142/68_check.log 2>&1)
R 69 Rscript scripts/69_e4_density_forms.R
R 70 Rscript scripts/70_fig5_bakuzis.R
R 71 Rscript scripts/71_supp_figs_v141.R
R 72 Rscript scripts/72_workbook_1150.R
R 74 Rscript scripts/74_e2_site_terms_1150.R
R 73 Rscript scripts/73_tiff600_v141.R
echo "$(date +%T) CHAIN 142 DONE" >> $JOB/out/chain142.log
