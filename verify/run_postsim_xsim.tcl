set root_dir [file normalize [file join [file dirname [info script]] ".."]]
set src_dir [file join $root_dir "cpu_54.srcs" "sources_1" "new"]
set ip_dir [file join $root_dir "cpu_54.srcs" "sources_1" "ip" "imem"]
set sim_dir [file join $root_dir "cpu_54.srcs" "sim_1" "new"]
set work_dir [file join $root_dir "tmp" "postsim_xsim"]
set proj_dir [file join $work_dir "proj"]
set result_file [file join $work_dir "postsim_result.txt"]

file delete -force $work_dir
file mkdir $work_dir

create_project -force cpu54_postsim_xsim $proj_dir -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

add_files -fileset sources_1 [file join $src_dir "regfile.v"]
add_files -fileset sources_1 [file join $src_dir "scdatamem.v"]
add_files -fileset sources_1 [file join $src_dir "scinstmem.v"]
add_files -fileset sources_1 [file join $src_dir "sccpu.v"]
add_files -fileset sources_1 [file join $src_dir "postsim_top.v"]
add_files -fileset sources_1 [file join $ip_dir "imem.xci"]
add_files -fileset sim_1 [file join $sim_dir "postsim_tb.v"]
set_property top postsim_top [get_filesets sources_1]
set_property top postsim_tb [get_filesets sim_1]

set_property xsim.simulate.runtime all [get_filesets sim_1]
set_property generic "RESULT_FILE=$result_file" [get_filesets sim_1]

launch_runs synth_1 -jobs 2
wait_on_run synth_1
launch_simulation -mode post-synthesis -type timing -batch

if {![file exists $result_file]} {
    error "post-synthesis timing simulation result not generated: $result_file"
}
puts "POSTSIM_RESULT=$result_file"
