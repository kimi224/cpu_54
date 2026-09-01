set root_dir [file normalize [file join [file dirname [info script]] ".."]]
set ip_path [file join $root_dir "cpu_54.srcs" "sources_1" "ip" "imem" "imem.xci"]
set repair_dir [file join $root_dir "tmp" "imem_ip_repair"]

file delete -force $repair_dir
create_project -force imem_ip_repair $repair_dir -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

read_ip $ip_path
set imem_ip [get_ips imem]
if {[llength $imem_ip] == 0} {
    error "imem IP was not found in project"
}

report_ip_status -file [file join $root_dir "verify" "imem_ip_status_before.txt"]
upgrade_ip -quiet $imem_ip
generate_target all $imem_ip
export_ip_user_files -of_objects $imem_ip -no_script -force -quiet
report_ip_status -file [file join $root_dir "verify" "imem_ip_status_after.txt"]
close_project
