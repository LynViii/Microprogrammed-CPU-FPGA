set script_dir [file dirname [file normalize [info script]]]
set build_dir  [file join $script_dir build]

create_project CPU_design $build_dir -part xc7a100tcsg324-1 -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

add_files [glob -nocomplain [file join $script_dir rtl *.v]]
add_files [file join $script_dir ip blk_ram blk_ram.xci]
add_files [file join $script_dir ip blk_rom blk_rom.xci]

# Keep the COE paths local to the repository rather than the original desktop path.
set_property CONFIG.Coe_File [file normalize [file join $script_dir ip blk_ram ram.coe]] [get_ips blk_ram]
set_property CONFIG.Coe_File [file normalize [file join $script_dir ip blk_rom rom.coe]] [get_ips blk_rom]

generate_target all [get_ips blk_ram]
generate_target all [get_ips blk_rom]

add_files -fileset constrs_1 [file join $script_dir constraints nexys_a7_100t.xdc]
add_files -fileset sim_1 [file join $script_dir sim cpu_sim.v]

set_property top TOP [current_fileset]
set_property top cpu_sim [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Project created at: $build_dir"
