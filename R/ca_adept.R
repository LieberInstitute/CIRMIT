rm(list = ls())

library(R.matlab)
library(ggplot2)
library(dplyr)
library(reshape2)
devtools::install_github("martakarass/adept")
library(adept)
library(stringi)

print("check0")
args <- commandArgs(trailingOnly=TRUE)
file <- args[1]
outputPath <- args[2]
x.fs <- args[3] %>% as.numeric()


## Function to read Matlab data and convert to ready-to-use data.frame
get.df <- function(file.id){
  file.path.i <- files.path[file.id]
  #traces      <- readMat(file.path.i)
  if (grepl('smoothTraces', file.path.i)) {
    mat <- readMat(file.path.i)
  } else {
    mat <- readMat(file.path.i)$traces
  }
  #mat         <- traces[[1]][stat.id][[1]]
  dat         <- data.frame(mat)
  dat.names   <- paste0("tr", 1:ncol(dat))
  names(dat)  <- dat.names
  dat$time_s  <- (0:(nrow(dat)-1))/4
  dat
}

get.df2 <- function(file.path.i){
  #traces      <- readMat(file.path.i)
  if (grepl('smoothTraces', file.path.i)) {
    mat <- readMat(file.path.i)$smoothTraces
  } else {
    mat <- readMat(file.path.i)$traces
  }
  #mat         <- traces[[1]][stat.id][[1]]
  dat         <- data.frame(mat)
  dat.names   <- paste0("tr", 1:ncol(dat))
  names(dat)  <- dat.names
  dat$time_s  <- (0:(nrow(dat)-1))/4
  dat
}

print("check1")

## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------
## ADEPT SEGMENTATION

load("../R/spikes.Rdata")
load("../R/spike_df.Rdata")
## Params
pattern.dur.seq      <- seq(5, 30, by = 1/4)   ## Pattern assumed between 5 to 30 seconds
similarity.measure   <- "cor"
compute.template.idx <- TRUE
template             <- tmpl.out
# template <- lapply(tmpl.out, function(tmpl) -tmpl)
#x.fs                 <- 4
x.cut                <- FALSE

#sim_i.post.thresh    <- 0.7



## -----------------------------------------------------------------------------
## FILE 1


try({
dat1 <- get.df2(file.path(outputPath, file))

for (j in 1:(ncol(dat1)-1)) {
## TR1
t1 <- Sys.time()
out.dat1.tr1 <-
  segmentPattern(
  x                    = dat1[,j],
  x.fs                 = x.fs,
  template             = template,
  pattern.dur.seq      = pattern.dur.seq,
  similarity.measure   = similarity.measure,
  compute.template.idx = compute.template.idx,
  x.cut                = x.cut,
  run.parallel         = TRUE,
  run.parallel.cores   = parallel::detectCores()-1
  )
Sys.time() - t1 # Time difference of 32.72379 secs
out.dat1.tr1.F <-
  out.dat1.tr1 %>%
  #filter(sim_i > sim_i.post.thresh) %>%
  left_join(tmpl.par.df, by = "template_i")
if (nrow(out.dat1.tr1.F) > 0) {
rng <- rep(NA, nrow(out.dat1.tr1.F))
for (k in 1:nrow(out.dat1.tr1.F)) {
t1 <- out.dat1.tr1.F$tau_i[k]
t2 <- min(t1+out.dat1.tr1.F$T_i[k], length(dat1[,j]))
rng[k] <- range(dat1[t1:t2,j])[2]-range(dat1[t1:t2,j])[1]
}
out.dat1.tr1.F$rng <- rng
out.dat1.tr1.F$SD <- sd(dat1[,j])
}
if (grepl('smoothTraces', file)) {
  fname <- stri_replace(file, replacement='', fixed="smoothTraces.mat")
} else {
  fname <- stri_replace(file, replacement='', fixed="traces.mat")
}

fname <- paste0(fname, 'adept_trace', j, '.csv')
fname <- basename(fname)
file.path(outputPath, fname)
write.csv(out.dat1.tr1.F, file=file.path(outputPath, fname))


}
})
