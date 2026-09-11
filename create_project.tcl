set script_dir [file dirname [file normalize [info script]]]
set build_dir  [file join $script_dir build]

create_project CPU_design $build_dir -part xc7a100tcsg324-1 -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

add_files [glob -nocomplain [file join $script_dir rtl *.v]]

# Re-create the two Block Memory Generator IPs from the original project settings.
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name blk_ram
set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Write_Depth_A {256} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Operating_Mode_A {WRITE_FIRST} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Use_Byte_Write_Enable {false} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File [file normalize [file join $script_dir ip blk_ram ram.coe]] \
] [get_ips blk_ram]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name blk_rom
set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Write_Depth_A {256} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File [file normalize [file join $script_dir ip blk_rom rom.coe]] \
] [get_ips blk_rom]

generate_target all [get_ips blk_ram]
generate_target all [get_ips blk_rom]

add_files -fileset constrs_1 [file join $script_dir constraints nexys_a7_100t.xdc]
add_files -fileset sim_1 [file join $script_dir sim cpu_sim.v]

set_property top TOP [current_fileset]
set_property top cpu_sim [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Project created at: $build_dir"
