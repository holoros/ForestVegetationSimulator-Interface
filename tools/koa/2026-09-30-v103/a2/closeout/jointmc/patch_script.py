p = "a2/closeout/jointmc/joint_draws_v103_inst.R"
s = open(p).read()
def rep(a, b):
    global s
    assert s.count(a) == 1, a[:60]
    s = s.replace(a, b)
rep("## joint_draws_v103.R (2026-09-30, Stage A2). joint_draws_v102.R adapted to the v103 deployment. Same design: source resampling with both\n",
    "## joint_draws_v103_inst.R (2026-09-30, closeout, red team must-change 5). Copy of a2/joint_draws_v103.R with ONE design change: the\n"
    "## multiplier resample keeps every data source and resamples its installations (Data|Install) with replacement within source, as the\n"
    "## constants bootstrap track2/inc/boot_v103.R does; one installation draw per row is applied to both the dDBH and dHT frames. Everything\n"
    "## else (vector draws, pairing of vector j with the re-solve, height, Stage 1, kmort, seed, N) is unchanged. Output a2/closeout/jointmc/out.\n"
    "## Original header: joint_draws_v102.R adapted to the v103 deployment. Same design: source resampling with both\n")
rep('srcs <- sort(unique(c(FR$dDBH$Data, FR$dHT$Data))); logm("sources", paste(srcs, collapse = " "))\n',
    'srcs <- sort(unique(c(FR$dDBH$Data, FR$dHT$Data))); logm("sources", paste(srcs, collapse = " "))\n'
    'FR <- lapply(FR, function(d) { d$inst <- paste(d$Data, d$Install, sep = "|"); d }); SPI <- lapply(FR, function(d) split(seq_len(nrow(d)), d$inst))\n'
    'IU <- unique(do.call(rbind, lapply(FR, function(d) unique(d[, c("inst", "Data")])))); IU <- IU[order(IU$Data, IU$inst), ]\n'
    'ids_by_src <- split(IU$inst, IU$Data); logm("installations by source (union of frames):", paste(names(ids_by_src), lengths(ids_by_src), collapse = " "))\n'
    'rows_of <- function(resp, s) { sp <- SPI[[resp]]; unlist(sp[s[s %in% names(sp)]], use.names = FALSE) }\n')
rep('dd <- d[unlist(split(seq_len(nrow(d)), d$Data)[s], use.names = FALSE), ]\n',
    'dd <- d[rows_of(resp, s), ]\n')
rep('k0 <- c(csolve("dDBH", B0$dDBH, srcs), csolve("dHT", B0$dHT, srcs))',
    'k0 <- c(csolve("dDBH", B0$dDBH, IU$inst), csolve("dHT", B0$dHT, IU$inst))')
rep('repeat { s <- sample(srcs, length(srcs), replace = TRUE)\n    if (all(sapply(FR, function(d) all(c(0, 1) %in% d$Planted[d$Data %in% s])))) break; rej <- rej + 1L }',
    'repeat { s <- unlist(lapply(ids_by_src, function(v) sample(v, length(v), replace = TRUE)), use.names = FALSE)\n'
    '    if (all(sapply(names(FR), function(r) all(c(0, 1) %in% FR[[r]]$Planted[rows_of(r, s)])))) break; rej <- rej + 1L }')
rep('MCOUT <- file.path(W, "a2/mc/out")', 'MCOUT <- file.path(W, "a2/closeout/jointmc/out")')
rep('sources = paste(sort(x$s), collapse = "|"),',
    'sources = paste(sort(unique(sub("\\\\|.*", "", x$s))), collapse = "|"), n_inst_distinct = length(unique(x$s)),')
rep('num <- K[, sapply(K, is.numeric) & names(K) != "draw"]', 'num <- K[, sapply(K, is.numeric) & !(names(K) %in% c("draw", "n_inst_distinct"))]')
open(p, "w").write(s)
print("patched")
