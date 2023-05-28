quit -sim
.main clear

file delete -force presynth
vlib presynth
vmap presynth presynth

vlog -sv -work presynth \
    "rtl/i2c_master.sv" \
    "test/i2c_slave.v" \
    "test/testbench.sv"

vsim -voptargs=+acc -L presynth -work presynth -t 1ps presynth.testbench
add log -r /*

if {[file exists "wave.do"]} {
    do  "wave.do"
}

run -all