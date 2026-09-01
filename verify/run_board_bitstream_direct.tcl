set root_dir [file normalize [file join [file dirname [info script]] ".."]]
set src_dir [file join $root_dir "cpu_54.srcs" "sources_1" "new"]
set ip_dir [file join $root_dir "cpu_54.srcs" "sources_1" "ip" "imem"]
set constr_dir [file join $root_dir "cpu_54.srcs" "constrs_1" "new"]
set out_dir [file join $root_dir "cpu_54.runs" "board_direct"]

file mkdir $out_dir

create_project -in_memory cpu54_board_bit xc7a100tcsg324-1
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

read_verilog [file join $src_dir "regfile.v"]
read_verilog [file join $src_dir "scdatamem.v"]
read_verilog [file join $src_dir "scinstmem.v"]
read_verilog [file join $src_dir "sccpu.v"]
read_verilog [file join $src_dir "cpu54_board.v"]
read_verilog [file join $src_dir "seg7x16.v"]
read_verilog [file join $src_dir "test.v"]
read_ip [file join $ip_dir "imem.xci"]
read_xdc [file join $constr_dir "icf.xdc"]

synth_design -top test -part xc7a100tcsg324-1
write_checkpoint -force [file join $out_dir "post_synth.dcp"]
report_utilization -file [file join $out_dir "post_synth_utilization.rpt"]

opt_design
place_design
route_design
report_timing_summary -file [file join $out_dir "timing_summary.rpt"]
report_route_status -file [file join $out_dir "route_status.rpt"]
write_bitstream -force [file join $out_dir "test.bit"]

puts "BITSTREAM=[file join $out_dir test.bit]"
