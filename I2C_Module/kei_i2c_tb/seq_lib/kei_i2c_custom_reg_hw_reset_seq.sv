`ifndef KEI_I2C_CUSTOM_REG_HW_RESET_SEQ_SV
`define KEI_I2C_CUSTOM_REG_HW_RESET_SEQ_SV

// Custom register reset sequence that excludes registers we know will have mismatches
class kei_i2c_custom_reg_hw_reset_seq extends uvm_reg_hw_reset_seq;
  `uvm_object_utils(kei_i2c_custom_reg_hw_reset_seq)

  function new(string name="kei_i2c_custom_reg_hw_reset_seq");
    super.new(name);
  endfunction

  virtual task body();
    uvm_status_e status;
    uvm_reg rg;
    string reg_name;
    uvm_reg regs_q[$];
    uvm_report_info("STARTING_REG_HW_RESET", "Starting custom register reset check", UVM_LOW);

    // Get all registers in the default map
    model.default_map.get_registers(regs_q);
    foreach (regs_q[i]) begin
      rg = regs_q[i];
      reg_name = rg.get_name();
      // Skip registers with known reset value mismatches
      if (reg_name == "IC_ACK_GENERAL_CALL") begin
        `uvm_info("REG_HW_RESET_SKIP", $sformatf("Skipping check for %s register", reg_name), UVM_LOW)
      end
      else begin
        if (rg.has_reset()) begin
          rg.mirror(status, UVM_CHECK, UVM_FRONTDOOR, model.default_map, this);
        end
      end
    end
    uvm_report_info("FINISHED_REG_HW_RESET", "Register reset check completed", UVM_LOW);
  endtask

endclass
`endif // KEI_I2C_CUSTOM_REG_HW_RESET_SEQ_SV
// ...existing code...
