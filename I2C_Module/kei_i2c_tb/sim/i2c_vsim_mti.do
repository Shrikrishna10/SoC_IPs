vlog -sv -work work /home/prawns/apb_i2c/i2c_master_bit_ctrl.sv
vlog -sv +incdir+/home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_apb3 -work work /home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_apb3/kei_vip_apb_if.sv
vlog -sv +incdir+/home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_i2c -work work /home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_i2c/kei_vip_i2c_if.sv
vlog -sv +incdir+/home/prawns/apb_i2c/kei_i2c_tb/tb -work work /home/prawns/apb_i2c/kei_i2c_tb/tb/kei_i2c_if.sv
vlog -sv +incdir+/home/prawns/apb_i2c/kei_i2c_tb/tb -work work /home/prawns/apb_i2c/kei_i2c_tb/tb/kei_i2c_backdoor_if.sv
vlog -sv -work work /home/prawns/apb_i2c/i2c_master_byte_ctrl.sv
vlog -sv +incdir+/home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_apb3 \
           -work work /home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_apb3/kei_vip_apb_pkg.sv
vlog -sv +incdir+/home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_i2c \
           -work work /home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_i2c/kei_vip_i2c_pkg.sv
onerror {resume}
onbreak {resume}
onElabError {resume}


# Simulation specific setup
set NumericStdNoWarnings 1
vlog -sv \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_apb3 \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_i2c \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/cfg \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/reg \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/env \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/seq_lib \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/seq_lib/elem_seqs \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/seq_lib/user_elem_seqs \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/seq_lib/user_virt_seqs \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/tests \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/tests/user_tests \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/cov \
           -work work /home/prawns/apb_i2c/kei_i2c_tb/env/kei_i2c_pkg.sv
vlog -sv +incdir+/home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_apb3 \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_i2c \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/cfg \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/reg \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/env \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/seq_lib \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/tests \
           -work work /home/prawns/apb_i2c/apb_i2c.sv
vlog -sv +incdir+/home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_apb3 \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/agents/kei_vip_i2c \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/cfg \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/reg \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/env \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/seq_lib \
           +incdir+/home/prawns/apb_i2c/kei_i2c_tb/tests \
           -work work /home/prawns/apb_i2c/kei_i2c_tb/tb/kei_i2c_tb.sv
# source $env(VRMDATA_DIR)/fullregr/i2c_wave_mti.do

vsim work.kei_i2c_tb
set StdArithNoWarnings   1
set NumericStdNoWarnings 1
if {[batch_mode]} {
   echo "Sim in batch mode"
   run -a
   log -r /*
} else {
   echo "Sim in gui mode"
   run -a
   log -r /* -depth 2
}

###########################################
# You may save coverage in the script OR
# specify it in the RMDB command actions
###########################################

## # Start the simulation
## run -a        
## 
## # Save coverage, and prepare for next run...
## coverage attribute  -name TESTNAME -value [format "%s" [file rootname $env(UCDBFILE)] ]
## coverage save      [format "%s" $env(UCDBFILE) ]
## 
## quit


