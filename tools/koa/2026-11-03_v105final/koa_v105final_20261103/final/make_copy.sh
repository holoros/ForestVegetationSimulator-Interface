# copy the chosen attribution run (koa_v105attr_20261103/R_HT, read only from here on) and the v105d LOIO scripts (no engines/val outputs); rewrite paths.
set -u; F=~/jobs/koa_v105final_20261103; A=~/jobs/koa_v105attr_20261103/R_HT
( cd $A && tar -cf - . ) | ( cd $F && tar -xpf - )
mkdir -p $F/a5/loio; ( cd ~/jobs/koa_v105d_20261102/a5/loio && tar -cf - --exclude='./engines' --exclude='./val' --exclude='./mort' --exclude='./fits' . ) | ( cd $F/a5/loio && tar -xpf - )
mkdir -p $F/a5/loio/val $F/a5/loio/fits $F/a5/loio/mort $F/a5/loio/engines
cd $F
grep -rIl "koa_v105attr_20261103/R_HT" . --include='*.py' --include='*.R' --include='*.sh' | grep -v '_PREV_' | grep -v '^./final/' > logs/rewrite_attr.txt
xargs -a logs/rewrite_attr.txt sed -i "s#koa_v105attr_20261103/R_HT#koa_v105final_20261103#g"
grep -rIl "koa_v105d_20261102" a5/loio --include='*.py' --include='*.R' --include='*.sh' | grep -v '_PREV_' > logs/rewrite_loio.txt
xargs -a logs/rewrite_loio.txt sed -i "s#koa_v105d_20261102#koa_v105final_20261103#g"
find . -type l | while read l; do t=$(readlink "$l"); case "$t" in *koa_v105attr_20261103/R_HT*) ln -sfn "${t//koa_v105attr_20261103\/R_HT/koa_v105final_20261103}" "$l"; echo "relinked $l";; esac; done
echo "rewritten $(wc -l < logs/rewrite_attr.txt) + loio $(wc -l < logs/rewrite_loio.txt); remaining refs to R_HT:"; grep -rIl "koa_v105attr_20261103" . --include='*.py' --include='*.R' --include='*.sh' | grep -v _PREV_ | grep -v '^./final/' | head
echo COPY DONE $(date)
