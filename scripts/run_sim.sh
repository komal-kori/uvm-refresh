#!/usr/bin/env bash
set -euo pipefail

TOP="top_tb"
LIB="work"
FLIST="scripts/files.f"
LOGDIR="logs"
COVDIR="cov"

mkdir -p "${LOGDIR}" "${COVDIR}"

echo "[INFO] Clean"
rm -rf "${LIB}" transcript vsim.wlf
vlib "${LIB}"

echo "[INFO] Compile"
vlog -sv -work "${LIB}" +acc -f "${FLIST}" | tee "${LOGDIR}/compile.log"

echo "[INFO] Sim (no coverage)"
vsim -c -voptargs=+acc "${TOP}" -do "run -all; quit" | tee "${LOGDIR}/sim.log"

echo "[INFO] Done"
