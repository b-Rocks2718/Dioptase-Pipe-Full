#------------------------------------------------------------------------------
# create_project.tcl
#
# Purpose:
# - Create a Vivado project for Dioptase-Pipe-Full on Nexys A7-100T.
# - Add RTL + FPGA wrapper + constraints template.
# - Optionally run synthesis and implementation.
#
# Usage from Windows (PowerShell):
#   vivado -mode batch -source .\fpga\create_project.tcl
#
# Usage with explicit args:
#   vivado -mode batch -source .\fpga\create_project.tcl -tclargs <build_dir> <run_impl> <run_jobs> <enable_icache_preload> <enable_ddr_adapter> <enable_pixel_fb>
#
# Arguments:
# - build_dir (optional): output directory for .xpr and runs.
#   default: <repo>/build/vivado
# - run_impl (optional): 0 = synth only, 1 = synth + impl + bitstream.
#   default: 0
# - run_jobs (optional): Vivado parallel jobs for runs.
#   default: 2
# - enable_icache_preload (optional): 1 enables direct I-cache preload files,
#   0 disables preload for isolation/debug.
#   default: 1
# - enable_ddr_adapter (optional): 1 uses external `ddr_sram_adapter` in mem.v,
#   0 uses in-repo `ram.v` backing model.
#   default: 0
# - enable_pixel_fb (optional): 1 keeps the pixel framebuffer memory path
#   enabled; 0 removes it (tile+sprite VGA still enabled).
#   default: 0
#------------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ".."]]

set default_build_dir [file join $repo_dir "build" "vivado"]
set build_dir $default_build_dir
if {[llength $argv] >= 1} {
    set build_dir [file normalize [lindex $argv 0]]
}

set run_impl 0
if {[llength $argv] >= 2} {
    set run_impl [lindex $argv 1]
}

set run_jobs 2
if {[llength $argv] >= 3} {
    set run_jobs [lindex $argv 2]
}

set enable_icache_preload 1
if {[llength $argv] >= 4} {
    set enable_icache_preload [lindex $argv 3]
}

set enable_ddr_adapter 0
if {[llength $argv] >= 5} {
    set enable_ddr_adapter [lindex $argv 4]
}

set enable_pixel_fb 0
if {[llength $argv] >= 6} {
    set enable_pixel_fb [lindex $argv 5]
}

set project_name "dioptase_pipe_full"
set part_name "xc7a100tcsg324-1"

puts "==> Creating project '$project_name' in '$build_dir'"
create_project $project_name $build_dir -part $part_name -force

# Board part is optional. Vivado installs vary, so only set this if available.
set nexys_board_parts [get_board_parts -quiet "digilentinc.com:nexys-a7-100t:part0:*"]
if {[llength $nexys_board_parts] > 0} {
    set_property board_part [lindex $nexys_board_parts 0] [current_project]
    puts "==> Using board part [lindex $nexys_board_parts 0]"
} else {
    puts "==> Board part not found; continuing with part-only project."
}

set rtl_files [glob -nocomplain [file join $repo_dir "src" "*.v"]]
if {[llength $rtl_files] == 0} {
    error "No RTL files found under [file join $repo_dir src]"
}

add_files -norecurse $rtl_files
add_files -norecurse [file join $repo_dir "fpga" "dioptase_fpga_top.v"]
add_files -fileset constrs_1 [file join $repo_dir "fpga" "nexys_a7_template.xdc"]

set ps2_decode_file [file join $repo_dir "data" "scan_decode.mem"]
if {![file exists $ps2_decode_file]} {
    error "Missing PS/2 decode table: $ps2_decode_file"
}

set icache_preload_files [list \
    [file join $repo_dir "data" "icache_way0.mem"] \
    [file join $repo_dir "data" "icache_way1.mem"] \
    [file join $repo_dir "data" "icache_tagv0.mem"] \
    [file join $repo_dir "data" "icache_tagv1.mem"] \
]

if {$enable_icache_preload} {
    foreach preload_file $icache_preload_files {
        if {![file exists $preload_file]} {
            error "Missing I-cache preload file: $preload_file. Run scripts/gen_icache_preload.py first."
        }
    }
}

set mem_init_files [list $ps2_decode_file]
if {$enable_icache_preload} {
    set mem_init_files [concat $mem_init_files $icache_preload_files]
}
add_files -norecurse $mem_init_files
set_property file_type {Memory Initialization Files} [get_files $mem_init_files]

# Configure direct I-cache boot preload in RTL for FPGA synthesis.
set existing_defines [get_property verilog_define [current_fileset]]
set existing_defines [lsearch -inline -all -not -exact $existing_defines "FPGA_ICACHE_PRELOAD=1"]
if {$enable_icache_preload} {
    if {[lsearch -exact $existing_defines "FPGA_ICACHE_PRELOAD=1"] < 0} {
        lappend existing_defines "FPGA_ICACHE_PRELOAD=1"
    }
    puts "==> I-cache preload ENABLED"
} else {
    puts "==> I-cache preload DISABLED"
}
set_property verilog_define $existing_defines [current_fileset]

# Configure external DDR->SRAM adapter path in mem.v.
set existing_defines [get_property verilog_define [current_fileset]]
set existing_defines [lsearch -inline -all -not -exact $existing_defines "FPGA_USE_DDR_SRAM_ADAPTER=1"]
if {$enable_ddr_adapter} {
    if {[lsearch -exact $existing_defines "FPGA_USE_DDR_SRAM_ADAPTER=1"] < 0} {
        lappend existing_defines "FPGA_USE_DDR_SRAM_ADAPTER=1"
    }
    puts "==> DDR adapter path ENABLED (expects module ddr_sram_adapter)"
} else {
    puts "==> DDR adapter path DISABLED (using in-repo ram.v)"
}
set_property verilog_define $existing_defines [current_fileset]

# Configure pixel framebuffer resource mode for DDR-adapter FPGA builds.
set existing_defines [get_property verilog_define [current_fileset]]
set existing_defines [lsearch -inline -all -not -exact $existing_defines "FPGA_DISABLE_PIXEL_FB=1"]
if {$enable_ddr_adapter && !$enable_pixel_fb} {
    if {[lsearch -exact $existing_defines "FPGA_DISABLE_PIXEL_FB=1"] < 0} {
        lappend existing_defines "FPGA_DISABLE_PIXEL_FB=1"
    }
    puts "==> Pixel framebuffer DISABLED (tile+sprite VGA kept)"
} elseif {$enable_ddr_adapter && $enable_pixel_fb} {
    puts "==> Pixel framebuffer ENABLED"
} else {
    puts "==> Pixel framebuffer setting ignored (DDR adapter disabled)"
}
set_property verilog_define $existing_defines [current_fileset]

# When DDR adapter mode is enabled, also add Digilent reference component
# sources and DDR constraints if present in the expected repo-local location.
if {$enable_ddr_adapter} {
    set ddr_refcomp_dir [file join $repo_dir "ram2ddr_refcomp" "Ram2Ddr_RefComp" "Source" "Ram2Ddr_RefComp"]
    set ddr_user_design_dir [file join $ddr_refcomp_dir "ipcore_dir" "ddr" "user_design"]
    set ddr_user_rtl_dir [file join $ddr_user_design_dir "rtl"]
    set ddr_wrapper_vhd [file join $ddr_refcomp_dir "ram2ddr.vhd"]
    set ddr_xdc [file join $ddr_user_design_dir "constraints" "ddr.xdc"]

    if {![file exists $ddr_wrapper_vhd]} {
        error "DDR adapter enabled but missing wrapper: $ddr_wrapper_vhd"
    }
    if {![file exists $ddr_xdc]} {
        error "DDR adapter enabled but missing constraints: $ddr_xdc"
    }

    set ddr_rtl_files [list [file join $ddr_user_rtl_dir "ddr.vhd"]]
    foreach ddr_subdir {clocking controller ecc ip_top phy ui} {
        set ddr_rtl_files [concat $ddr_rtl_files \
            [glob -nocomplain [file join $ddr_user_rtl_dir $ddr_subdir "*.v"]] \
            [glob -nocomplain [file join $ddr_user_rtl_dir $ddr_subdir "*.vhd"]]]
    }
    set ddr_rtl_files [concat [list $ddr_wrapper_vhd] $ddr_rtl_files]

    foreach ddr_file $ddr_rtl_files {
        if {![file exists $ddr_file]} {
            error "DDR adapter enabled but missing expected file: $ddr_file"
        }
    }

    puts "==> Adding Digilent DDR adapter sources from $ddr_refcomp_dir"
    add_files -norecurse $ddr_rtl_files
    puts "==> Adding DDR constraints $ddr_xdc"
    add_files -fileset constrs_1 $ddr_xdc
}

set_property top dioptase_fpga_top [current_fileset]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "==> Launching synthesis (jobs=$run_jobs)"
launch_runs synth_1 -jobs $run_jobs
wait_on_run synth_1

if {$run_impl} {
    puts "==> Launching implementation + bitstream (jobs=$run_jobs)"
    launch_runs impl_1 -to_step write_bitstream -jobs $run_jobs
    wait_on_run impl_1
    puts "==> Implementation complete."
} else {
    puts "==> Synthesis complete (implementation skipped; run_impl=$run_impl)."
}
