# Makefile (Questa/ModelSim)
# Usage:
#   make clean
#   make build
#   make run
#   make cov
#
# Notes:
# - Requires: vlib, vmap, vlog, vsim (Questa)
# - Produces: work/ library and logs/

SHELL := /bin/bash

TOP      := top_tb
LIB      := work
FLIST    := scripts/files.f
LOGDIR   := logs
COVDIR   := cov

# Questa options
VLOG_OPTS := -sv -work $(LIB) +acc
VSIM_OPTS := -c -voptargs=+acc

.PHONY: all clean build run cov

all: run

clean:
	rm -rf $(LIB) transcript vsim.wlf $(LOGDIR) $(COVDIR)
	mkdir -p $(LOGDIR) $(COVDIR)

build: clean
	vlib $(LIB)
	vlog $(VLOG_OPTS) -f $(FLIST) | tee $(LOGDIR)/compile.log

run: build
	vsim $(VSIM_OPTS) $(TOP) -do "run -all; quit" | tee $(LOGDIR)/sim.log

# Enable coverage collection (Questa)
# - 'coverage save' writes UCDB
cov: build
	vsim $(VSIM_OPTS) -coverage $(TOP) -do "run -all; coverage save -onexit $(COVDIR)/fifo.ucdb; quit" | tee $(LOGDIR)/sim_cov.log
	@echo "Coverage database: $(COVDIR)/fifo.ucdb"
	@echo "To view: vsim -viewcov $(COVDIR)/fifo.ucdb"
