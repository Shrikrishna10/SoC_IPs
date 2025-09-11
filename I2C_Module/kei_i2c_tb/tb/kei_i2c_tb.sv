`timescale 1ns/1ps
module kei_i2c_tb;
  parameter real i2c_clk_peroid = 10ns; // 100MHz
  parameter real apb_clk_peroid = 4ns;  // 250MHz
  parameter real ref_clk_peroid = 1ns;  // 1GHz

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import kei_i2c_pkg::*;

  logic i2c_clk;
  logic i2c_rstn;
  logic apb_clk;
  logic apb_rstn;
  logic ref_clk;
  wire  i2c_sda;
  wand  i2c_scl;
  logic i2c_data_oe;
  logic i2c_clk_oe;

  // KEI I2C DUT instantiation
  apb_i2c dut (
    .HCLK(apb_clk),
    .HRESETn(apb_rstn),
    .PADDR(apb_if.paddr),
    .PWDATA(apb_if.pwdata),
    .PWRITE(apb_if.pwrite),
    .PSEL(apb_if.psel),
    .PENABLE(apb_if.penable),
    .PRDATA(apb_if.prdata),
    .PREADY(apb_if.pready),
    .PSLVERR(apb_if.pslverr),
    .interrupt_o(), // Not connected
    .scl_pad_i(i2c_scl),
    .scl_pad_o(), // Not connected
    .scl_padoen_o(), // Not connected
    .sda_pad_i(i2c_sda),
    .sda_pad_o(), // Not connected
    .sda_padoen_o() // Not connected
  );


  initial begin 
    i2c_clk <= 0;
    apb_clk <= 0;
    ref_clk <= 0;
    fork
      forever begin
        #(i2c_clk_peroid/2.0) i2c_clk <= !i2c_clk;
      end
      forever begin
        #(apb_clk_peroid/2.0) apb_clk <= !apb_clk;
      end
      forever begin
        #(ref_clk_peroid/2.0) ref_clk <= !ref_clk;
      end
    join_none
  end

    // Simulation timeout: finish after 1 ms
    initial begin
      #1ms;
      $display("[TB] Simulation timeout reached. Calling $finish.");
      $finish;
    end
  
  // reset trigger
  initial begin 
    #10ns; 
    i2c_rstn <= 0;
    apb_rstn <= 0;
    fork
      begin
        repeat(10) @(posedge i2c_clk);
        i2c_rstn <= 1;
      end
      begin
        repeat(25) @(posedge apb_clk);
        apb_rstn <= 1;
      end
    join_none
  end

  kei_vip_apb_if apb_if(apb_clk, apb_rstn);

  kei_vip_i2c_if i2c_if(ref_clk);
  assign i2c_if.RST = !i2c_rstn;
  
  /*
  DUT在master mode下
  DUT驱动SDA时：
  i2c vip一侧sda_slave为x或z使得对SDA的strong0驱动一定失败，表现为z，但本身有个weak1兜底，所以i2c vip一侧SDA综合表现为weak1
  DUT一侧的i2c_data_oe按照数据输出（反相），使得tb里的i2c_sda为strong0或z，而i2c_sda本来为pull1
  故i2c_sda综合表现为strong0或pull1，i2c_if.SDA综合表现为strong0或weak1
  i2c vip驱动SDA时：
  i2c vip一侧sda_slave按照数据输出（同相）使得对SDA的strong0驱动有可能成功也有可能失败，表现为strong0或z，但本身有个weak1兜底，
  所以i2c vip一侧SDA综合表现为strong0或weak1
  DUT一侧的的i2c_data_oe为0，故i2c_sda综合表现为为strong0或pull1
  */
  assign i2c_sda = i2c_data_oe ? 1'b0 : 1'bz;//assign默认驱动强度为strong0和strong1
  assign i2c_sda = i2c_if.SDA === 1'b0 ? 1'b0 : 1'bz;//i2c vip驱动i2c_if.SDA时，保证i2c_sda与之一致
  pullup(i2c_sda);//pullup门驱动强度pull1，strength0未定义；pulldown门驱动强度pull0，strength1未定义
  assign i2c_if.SDA = i2c_data_oe ? 1'b0 : 1'bz;//DUT驱动i2c_sda时，保证i2c_if.SDA 与之一致

  assign i2c_scl = i2c_clk_oe ? 1'b0 : 1'bz;
  assign i2c_scl = i2c_if.SCL === 1'b0 ? 1'b0 : 1'bz;
  pullup(i2c_scl);
  assign i2c_if.SCL = i2c_clk_oe ? 1'b0 : 1'bz;

  kei_i2c_if top_if();
  assign top_if.i2c_clk  = i2c_clk;
  assign top_if.i2c_rstn = i2c_rstn;
  assign top_if.apb_clk  = apb_clk;
  assign top_if.apb_rstn = apb_rstn;
  
  kei_i2c_backdoor_if backdoor_if(i2c_clk);

  initial begin
    // Interface configuration from top tb (HW) to verification env (SW)
    string test_name;
    uvm_config_db#(virtual kei_i2c_if)::set(uvm_root::get(), "uvm_test_top.env", "vif", top_if);
    uvm_config_db#(virtual kei_i2c_backdoor_if)::set(uvm_root::get(), "uvm_test_top.env", "backdoor_vif", backdoor_if);
    uvm_config_db#(virtual kei_vip_apb_if)::set(uvm_root::get(), "uvm_test_top.env.apb_mst*", "vif", apb_if);
    uvm_config_db#(virtual kei_vip_i2c_if)::set(uvm_root::get(), "uvm_test_top.env", "i2c_vif", i2c_if);

    if (!$value$plusargs("TESTNAME=%s", test_name)) begin
      test_name = "kei_i2c_quick_reg_access_test";
      $display("[TB] No TESTNAME plusarg provided. Defaulting to: %s", test_name);
    end
    else begin
      $display("[TB] TESTNAME plusarg provided. Running: %s", test_name);
    end
    run_test(test_name);
  end

  // Simulation timeout: finish after 10 ms (longer for full test completion)
  initial begin
    #10ms;
    $display("[TB] Simulation timeout reached. Calling $finish.");
    $finish;
  end

endmodule
