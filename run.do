quit -sim
.main clear

file delete -force presynth
vlib presynth
vmap presynth presynth
vmap rtg4 "C:/Microchip/Libero_SoC_v2022.3/Designer/lib/modelsimpro/precompiled/vlog/rtg4"

vlog -sv -work presynth \
    "rtl/i2c_master.sv" \
    "test/i2c_slave.v" \
    "test/testbench.sv"

vsim -L rtg4 -L presynth -work presynth -t 1ps presynth.testbench
add log -r /*

if {[file exists "wave.do"]} {
    do  "wave.do"
}

run -all