# FPGA Verification Refresh Project

## Overview
This project demonstrates a complete ASIC/FPGA verification flow using
SystemVerilog and UVM, including testbench architecture, functional coverage,
assertions, and coverage-driven verification.

The goal of this project is to showcase hands-on verification skills and
modern verification practices.

## Design Under Test (DUT)
Brief description of the DUT and its functionality.

## Verification Approach
- UVM-based layered testbench
- Self-checking scoreboard
- Functional coverage and coverage closure
- Assertion-based verification
- Directed and constrained-random tests

## Tools & Languages
- SystemVerilog, UVM
- Linux-based simulation environment

## How to Run
```bash
make run

## Run (ModelSim Intel FPGA Edition)
cd C:/.../uvm-refresh
vlib work
vlog -sv -work work -f scripts/files.f
vsim -c top_tb
run 2 us
