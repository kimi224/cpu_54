set root_dir [file normalize [file join [file dirname [info script]] ".."]]
set src_dir [file join $root_dir "cpu_54.srcs" "sources_1" "new"]
set ip_dir [file join $root_dir "cpu_54.srcs" "sources_1" "ip" "imem"]
if {[info exists ::env(CPU54_PERIOD_NS)]} {
    set period_ns $::env(CPU54_PERIOD_NS)
} else {
    set period_ns 20.000
}
set half_period_ns [expr {$period_ns / 2.0}]
set work_xdc [file join $root_dir "tmp" "postsim_current.xdc"]

file delete -force [file join $root_dir "postsim_top.dcp"]
file delete -force [file join $root_dir "postsim_timesim.v"]
file delete -force [file join $root_dir "postsim_timesim.sdf"]
file delete -force [file join $root_dir "timing_report.txt"]
file mkdir [file join $root_dir "tmp"]

set fp [open $work_xdc "w"]
puts $fp "create_clock -period $period_ns -name clk_pin -waveform {0.000 $half_period_ns} \[get_ports clk_in\]"
puts $fp {set_input_delay -clock [get_clocks *] 1.000 [get_ports reset]}
puts $fp {set_output_delay -clock [get_clocks *] 0.000 [get_ports -filter { NAME =~  "*" && DIRECTION == "OUT" }]}
close $fp

create_project -in_memory cpu54_postsim xc7a100tcsg324-1
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

read_verilog [file join $src_dir "regfile.v"]
read_verilog [file join $src_dir "scdatamem.v"]
read_verilog [file join $src_dir "scinstmem.v"]
read_verilog [file join $src_dir "sccpu.v"]
read_verilog [file join $src_dir "postsim_top.v"]
read_ip [file join $ip_dir "imem.xci"]
read_xdc $work_xdc

synth_design -top postsim_top -part xc7a100tcsg324-1
write_checkpoint -force [file join $root_dir "postsim_top.dcp"]

opt_design
place_design
route_design

report_timing_summary -file [file join $root_dir "timing_report.txt"]
report_timing -max_paths 20 -file [file join $root_dir "timing_paths.txt"]
report_utilization -file [file join $root_dir "utilization_report.txt"]

write_verilog -force -mode timesim -sdf_anno true [file join $root_dir "postsim_timesim.v"]
write_sdf -force [file join $root_dir "postsim_timesim.sdf"]
