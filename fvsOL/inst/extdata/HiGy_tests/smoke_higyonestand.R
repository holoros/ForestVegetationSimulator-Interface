# Smoke test: five years of HiGYOneStand() on a synthetic natural and a synthetic
# planted stand, 30 koa records and one OT record. Run from HiGy_tests with a
# copy of HiGy.R alongside, or edit the source() path. OT records must keep their
# expansion factor.

suppressMessages(source(if (file.exists('HiGy.R')) 'HiGy.R' else '../HiGy.R'))
ops = make_ops()
for (pl in c(0,1)) {
  st = make_stand('S', elev=500, byi=264, planted=pl)
  set.seed(1); tr = data.frame(year=2026, plot=1, tree=1:31, sp=c(rep('AK',30),'OT'), dbh=c(runif(30,5,40),30), ht=NA, cr=runif(31,0.3,0.8), expf=40,
                  ddbh.mult=1, dht.mult=1, mort.mult=1, max.dbh=90, max.height=92)
  tr$ht = pmax(1.4, 1.3 + 0.6*tr$dbh)
  stand <<- st
  n = sum(tr$expf[tr$sp=='AK']); ot = tr$expf[tr$sp=='OT']
  for (i in 1:5) { tr = HiGYOneStand(tr, st, ops); n = c(n, sum(tr$expf[tr$sp=='AK'])); ot = c(ot, tr$expf[tr$sp=='OT']) }
  cat('planted', pl, 'AK trees ha-1:', round(n, 3), ' OT expf:', round(ot, 3), '\n')
}
