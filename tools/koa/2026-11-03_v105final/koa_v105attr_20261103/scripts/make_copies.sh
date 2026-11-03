# copy the v105d job (read only) into one folder per run, excluding the LOIO tree (4.1 GB, not run here) and build tarballs; rewrite absolute job paths.
set -u; J=~/jobs/koa_v105attr_20261103
for R in D742 R_dHT R_HT R_HCB R_S3 C742; do
  mkdir -p $J/$R
  ( cd ~/jobs/koa_v105d_20261102 && tar -cf - --exclude='./a5/loio' --exclude='*.tgz' . ) | ( cd $J/$R && tar -xpf - )
  cd $J/$R
  grep -rIl "koa_v105d_20261102" . --include='*.py' --include='*.R' --include='*.sh' | grep -v '_PREV_' > $J/logs/rewrite_$R.txt
  xargs -a $J/logs/rewrite_$R.txt sed -i "s#koa_v105d_20261102#koa_v105attr_20261103/$R#g"
  # repoint absolute symlinks into the v105d job
  find . -type l | while read l; do t=$(readlink "$l"); case "$t" in *koa_v105d_20261102*) ln -sfn "${t//koa_v105d_20261102/koa_v105attr_20261103\/$R}" "$l"; echo "relinked $l" ;; esac; done
  echo "$R copied $(wc -l < $J/logs/rewrite_$R.txt) files rewritten $(date)"
done
echo COPIES DONE
