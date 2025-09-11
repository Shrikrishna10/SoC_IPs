
TOP       = kei_i2c_tb
TEST     ?= kei_i2c_quick_reg_access_test
OUT      ?= out
VERB     ?= UVM_HIGH
INCDIR   = +incdir+../../kei_dw_apb_i2c/src \
					 +incdir+../agents/kei_vip_apb3 \
					 +incdir+../agents/kei_vip_i2c \
					 +incdir+../cfg \
					 +incdir+../cov \
					 +incdir+../reg \
					 +incdir+../env \
					 +incdir+../seq_lib \
					 +incdir+../seq_lib/elem_seqs \
					 +incdir+../seq_lib/user_elem_seqs \
					 +incdir+../seq_lib/user_virt_seqs \
					 +incdir+../tests \
					 +incdir+../tests/user_tests

VLIB     = vlib work
VLOG     = vlog $(INCDIR) -sv -timescale 1ns/1ps
VSIM     = vsim -c -do "run -all; quit"

I2C_TESTS = \
	kei_i2c_base_test \
	kei_i2c_quick_reg_access_test \
	kei_i2c_master_directed_interrupt_test \
	kei_i2c_master_directed_write_packet_test \
	kei_i2c_master_directed_read_packet_test \
	kei_i2c_reg_access_test \
	kei_i2c_reg_bit_bash_test \
	kei_i2c_reg_hw_reset_test

.PHONY: verify_all
		$(VSIM) +TESTNAME=$$test; \
		echo "Finished $$test"; \
	done

prepare:
	mkdir -p $(OUT)/work
	mkdir -p $(OUT)/log

	# QuestaSim/ModelSim flow only
	prepare:
		mkdir -p $(OUT)/work
		mkdir -p $(OUT)/log
		mkdir -p $(OUT)/sim
		mkdir -p $(OUT)/obj
		mkdir -p .shadow

	comp: prepare
		vlib work
		vlog $(INCDIR) -sv -timescale 1ns/1ps -f kei_i2c.flist
		vlog $(INCDIR) -sv -timescale 1ns/1ps ../env/kei_i2c_pkg.sv
		vlog $(INCDIR) -sv -timescale 1ns/1ps ../tb/kei_i2c_if.sv
		vlog $(INCDIR) -sv -timescale 1ns/1ps ../tb/kei_i2c_backdoor_if.sv
		vlog $(INCDIR) -sv -timescale 1ns/1ps ../tb/kei_i2c_tb.sv
		vlog $(INCDIR) -sv -timescale 1ns/1ps ../agents/kei_vip_apb3/kei_vip_apb_if.sv
		vlog $(INCDIR) -sv -timescale 1ns/1ps ../agents/kei_vip_apb3/kei_vip_apb_pkg.sv

	kei_i2c_master_directed_read_packet_test \
	kei_i2c_reg_access_test \
	kei_i2c_reg_bit_bash_test \
	kei_i2c_reg_hw_reset_test

# Target to run all I2C tests
.PHONY: verify_all
verify_all: comp
	@for test in $(I2C_TESTS); do \
		echo "Running $$test..."; \
		$(RUN) +TESTNAME=$$test; \
		echo "Finished $$test"; \
	done
all: clean dcomp comp regr mergecov dvemergecov


# QuestaSim/ModelSim flow only
prepare:
	mkdir -p $(OUT)/work
	mkdir -p $(OUT)/log
	mkdir -p $(OUT)/sim
	mkdir -p $(OUT)/obj
	mkdir -p .shadow

comp: prepare
	vlib work
	vlog $(INCDIR) -sv -timescale 1ns/1ps -f kei_i2c.flist
	vlog $(INCDIR) -sv -timescale 1ns/1ps ../env/kei_i2c_pkg.sv
	vlog $(INCDIR) -sv -timescale 1ns/1ps ../tb/kei_i2c_if.sv
	vlog $(INCDIR) -sv -timescale 1ns/1ps ../tb/kei_i2c_backdoor_if.sv
	vlog $(INCDIR) -sv -timescale 1ns/1ps ../tb/kei_i2c_tb.sv
	vlog $(INCDIR) -sv -timescale 1ns/1ps ../agents/kei_vip_apb3/kei_vip_apb_if.sv
	vlog $(INCDIR) -sv -timescale 1ns/1ps ../agents/kei_vip_apb3/kei_vip_apb_pkg.sv

verify_all: comp
	@for test in $(I2C_TESTS); do \
		echo "Running $$test..."; \
		vsim -c -do "run -all; quit" $(TOP) +TESTNAME=$$test; \
		echo "Finished $$test"; \
	done

elab: comp
	$(ELAB) $(TOP)

run: 
	$(RUN) +UVM_TESTNAME=$(TEST) -l $(OUT)/sim/$(CM_NAME).log -cm_dir $(CM_DIR) -cm_name $(CM_NAME)  

regr: 
	for t in $(TESTLIST); do \
		$(RUN) +UVM_TESTNAME=$$t -l $(OUT)/sim/$$t.log +vpdfile+$(OUT)/sim/$$t_$(SEED)_$(VPDFILE) -cm_dir $(OUT)/$$t.vdb; \
	done

mergecov:
	urg -full64 -format both  -dir $(OUT)/*.vdb -dbname $(CM_REGR_DIR)

dvecov:
	dve $(COV_OPTS) $(CM_DIR)

dvemergecov:
	dve $(COV_OPTS) $(CM_REGR_DIR)

verdicov:
	verdi -cov -plan ../doc/vcs_vplan.hvp -covdir $(CM_DIR)

verdimergecov:
	verdi -cov -plan ../doc/vcs_vplan.hvp -covdir $(CM_REGR_DIR)

htmlmergecov:
	firefox urgReport/dashboard.html

clean:
	-rm -rf csrc DVEfiles ucli.key uvm_dpi.so vc_hdrs.h  *simv* *.vpd *.log *.sml *.fsdb work.* *.vdb
	-rm -rf AN.DB urgReport novas.conf verdiLog vdCovLog novas.rc $(OUT) .shadow
	-rm -rf eman* vhdl_objs_dir
	-rm -rf transcript vsim* regr_ucdb* work kei_i2c_tb kei_i2c_tb.vdb
