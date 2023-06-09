onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group master /testbench/i2c_master/clock
add wave -noupdate -expand -group master /testbench/i2c_master/reset_n
add wave -noupdate -expand -group master /testbench/i2c_master/enable
add wave -noupdate -expand -group master /testbench/i2c_master/read_write
add wave -noupdate -expand -group master /testbench/i2c_master/mosi_data
add wave -noupdate -expand -group master /testbench/i2c_master/register_address
add wave -noupdate -expand -group master /testbench/i2c_master/device_address
add wave -noupdate -expand -group master /testbench/i2c_master/divider
add wave -noupdate -expand -group master /testbench/i2c_master/miso_data
add wave -noupdate -expand -group master /testbench/i2c_master/busy
add wave -noupdate -expand -group master /testbench/i2c_master/external_serial_data
add wave -noupdate -expand -group master /testbench/i2c_master/external_serial_clock
add wave -noupdate -expand -group master /testbench/i2c_master/state
add wave -noupdate -expand -group master /testbench/i2c_master/_state
add wave -noupdate -expand -group master /testbench/i2c_master/post_state
add wave -noupdate -expand -group master /testbench/i2c_master/_post_state
add wave -noupdate -expand -group master /testbench/i2c_master/serial_clock
add wave -noupdate -expand -group master /testbench/i2c_master/_serial_clock
add wave -noupdate -expand -group master /testbench/i2c_master/saved_device_address
add wave -noupdate -expand -group master /testbench/i2c_master/_saved_device_address
add wave -noupdate -expand -group master /testbench/i2c_master/saved_register_address
add wave -noupdate -expand -group master /testbench/i2c_master/_saved_register_address
add wave -noupdate -expand -group master /testbench/i2c_master/saved_mosi_data
add wave -noupdate -expand -group master /testbench/i2c_master/_saved_mosi_data
add wave -noupdate -expand -group master -radix unsigned /testbench/i2c_master/process_counter
add wave -noupdate -expand -group master -radix unsigned /testbench/i2c_master/_process_counter
add wave -noupdate -expand -group master -radix unsigned /testbench/i2c_master/bit_counter
add wave -noupdate -expand -group master -radix unsigned /testbench/i2c_master/_bit_counter
add wave -noupdate -expand -group master /testbench/i2c_master/serial_data
add wave -noupdate -expand -group master /testbench/i2c_master/_serial_data
add wave -noupdate -expand -group master /testbench/i2c_master/post_serial_data
add wave -noupdate -expand -group master /testbench/i2c_master/_post_serial_data
add wave -noupdate -expand -group master /testbench/i2c_master/last_acknowledge
add wave -noupdate -expand -group master /testbench/i2c_master/_last_acknowledge
add wave -noupdate -expand -group master /testbench/i2c_master/_saved_read_write
add wave -noupdate -expand -group master /testbench/i2c_master/saved_read_write
add wave -noupdate -expand -group master /testbench/i2c_master/divider_counter
add wave -noupdate -expand -group master /testbench/i2c_master/_divider_counter
add wave -noupdate -expand -group master /testbench/i2c_master/divider_tick
add wave -noupdate -expand -group master /testbench/i2c_master/_miso_data
add wave -noupdate -expand -group master /testbench/i2c_master/_busy
add wave -noupdate -expand -group master /testbench/i2c_master/serial_data_output_enable
add wave -noupdate -expand -group master /testbench/i2c_master/serial_clock_output_enable
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {53739810000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 84
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {120245529152 ps} {148648778382 ps}
