module kei_DW_apb_i2c (
    // Interrupt ports (dummy, not used in this RTL)
    output logic ic_start_det_intr,
    output logic ic_stop_det_intr,
    output logic ic_activity_intr,
    output logic ic_rx_done_intr,
    output logic ic_tx_abrt_intr,
    output logic ic_rd_req_intr,
    output logic ic_tx_empty_intr,
    output logic ic_tx_over_intr,
    output logic ic_rx_full_intr,
    output logic ic_rx_over_intr,
    output logic ic_rx_under_intr,
    output logic ic_gen_call_intr,
    output logic ic_current_src_en,
    // APB Slave I/O Signals
    input  logic pclk,
    input  logic presetn,
    input  logic psel,
    input  logic penable,
    input  logic pwrite,
    input  logic [7:0] paddr,
    input  logic [31:0] pwdata,
    output logic [31:0] prdata,
    output logic pready,
    output logic pslverr,
    // DEBUG ports (dummy)
    output logic debug_s_gen,
    output logic debug_p_gen,
    output logic [31:0] debug_data,
    output logic [7:0] debug_addr,
    output logic debug_rd,
    output logic debug_wr,
    output logic debug_hs,
    output logic debug_master_act,
    output logic debug_slave_act,
    output logic debug_addr_10bit,
    output logic [3:0] debug_mst_cstate,
    output logic [3:0] debug_slv_cstate,
    // I2C clock/reset and I2C serial ports
    input  logic ic_clk,
    input  logic ic_rst_n,
    inout  wand  ic_clk_in_a,
    inout  wire  ic_data_in_a,
    input  logic ic_clk_oe,
    input  logic ic_data_oe,
    input  logic ic_en
);

    // Map APB and I2C signals to apb_i2c RTL
    apb_i2c dut (
        .HCLK(pclk),
        .HRESETn(presetn),
        .PADDR({4'b0, paddr}),
        .PWDATA(pwdata),
        .PWRITE(pwrite),
        .PSEL(psel),
        .PENABLE(penable),
        .PRDATA(prdata),
        .PREADY(pready),
        .PSLVERR(pslverr),
        .interrupt_o(), // Not mapped to testbench
        .scl_pad_i(ic_clk_in_a),
        .scl_pad_o(), // Not mapped
        .scl_padoen_o(), // Not mapped
        .sda_pad_i(ic_data_in_a),
        .sda_pad_o(), // Not mapped
        .sda_padoen_o() // Not mapped
    );
    // All other ports are left unconnected or dummy
endmodule
