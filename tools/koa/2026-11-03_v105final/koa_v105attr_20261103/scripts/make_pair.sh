# make_pair.sh P_<a>_<b>: copy the v105d job for a pairwise revert run (as make_copies.sh), SDImax_pop in inc_v103.R, out/inc from R_dHT (dHT reverted) or D742.
set -u; J=~/jobs/koa_v105attr_20261103; R=$1; mkdir -p $J/$R
( cd ~/jobs/koa_v105d_20261102 && tar -cf - --exclude='./a5/loio' --exclude='*.tgz' . ) | ( cd $J/$R && tar -xpf - )
cd $J/$R; grep -rIl "koa_v105d_20261102" . --include='*.py' --include='*.R' --include='*.sh' | grep -v '_PREV_' > $J/logs/rewrite_$R.txt
xargs -a $J/logs/rewrite_$R.txt sed -i "s#koa_v105d_20261102#koa_v105attr_20261103/$R#g"
find . -type l | while read l; do t=$(readlink "$l"); case "$t" in *koa_v105d_20261102*) ln -sfn "${t//koa_v105d_20261102/koa_v105attr_20261103\/$R}" "$l";; esac; done
sed -i 's/SDIMAX_POP <- 923; /SDIMAX_POP <- 741.996871565; /' track2/inc/inc_v103.R
case $R in *dHT*) S=R_dHT;; *) S=D742;; esac; cp -a $J/$S/out/inc/. out/inc/; echo "$R copied, out/inc from $S"
