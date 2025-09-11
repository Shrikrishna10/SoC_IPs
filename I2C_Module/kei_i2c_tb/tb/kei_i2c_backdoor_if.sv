
`ifndef KEI_I2C_BACKDOOR_IF_SV
`define KEI_I2C_BACKDOOR_IF_SV
interface kei_i2c_backdoor_if(input bit clk);
  
  //tx_push_data,tx_push,rx_pop均是wire类型，无法直接赋值，需要force语句强制赋值
  task IC_DATA_CMD_backdoor_write_data(input bit [7:0]data);
    // Empty body: original force/release statements removed
  endtask

  task IC_DATA_CMD_backdoor_read_data(output bit [7:0]data);
    // Empty body: original force/release statements removed
  endtask
  
  function void i2c_if_SDA_force(input bit force_high);
    if(force_high)
      force kei_i2c_tb.i2c_if.SDA = 1'b1;
    else
      force kei_i2c_tb.i2c_if.SDA = 1'b0;
  endfunction
  
endinterface
`endif // KEI_I2C_BACKDOOR_IF_SV
