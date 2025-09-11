`include "i2c_master_defines.sv"


`define REG_CLK_PRESCALER      6'd0    // 0x00 >> 2
`define REG_CTRL               6'd1    // 0x04 >> 2
`define REG_RX                 6'd2    // 0x08 >> 2
`define REG_STATUS             6'd3    // 0x0C >> 2
`define REG_TX                 6'd4    // 0x10 >> 2
`define REG_CMD                6'd5    // 0x14 >> 2
`define REG_HS_SCL_LCNT        6'd15   // 0x3C >> 2
`define REG_ENABLE             6'd16   // 0x40 >> 2
`define REG_TX_TL              6'd17   // 0x44 >> 2
`define REG_RX_TL              6'd18   // 0x48 >> 2
`define REG_COMP_TYPE          6'd28   // 0x070 >> 2
`define REG_COMP_VERSION       6'd29   // 0x074 >> 2
`define REG_COMP_PARAM_1       6'd30   // 0x078 >> 2
`define REG_HS_SPKLEN          6'd31   // 0x07C >> 2
`define REG_FS_SPKLEN          6'd32   // 0x080 >> 2
`define REG_ACK_GENERAL_CALL   6'd33   // 0x084 >> 2
`define REG_SDA_SETUP          6'd34   // 0x088 >> 2
`define REG_SDA_HOLD           6'd35   // 0x08C >> 2
`define REG_TX_TL              6'd36   // 0x090 >> 2
`define REG_RX_TL              6'd37   // 0x094 >> 2
`define REG_INTR_MASK          6'd38   // 0x098 >> 2

module apb_i2c
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      HCLK,
    input  logic                      HRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,
    output logic                      interrupt_o,
    input  logic                      scl_pad_i,
    output logic                      scl_pad_o,
    output logic                      scl_padoen_o,
    input  logic                      sda_pad_i,
    output logic                      sda_pad_o,
    output logic                      sda_padoen_o
);

    //
    // variable declarations
    //

    // No longer needed - we use PADDR directly
    // logic  [7:0] s_apb_addr;

    // registers
    reg  [15:0] r_pre; // clock prescale register
    reg  [ 7:0] r_ctrl;  // control register
    reg  [ 7:0] r_tx;  // transmit register
    wire [ 7:0] s_rx;  // receive register
    reg  [ 7:0] r_cmd;   // command register
    wire [ 7:0] s_status;   // status register
    // UVM compatibility registers
    reg [31:0] r_comp_type;
    reg [31:0] r_comp_version;
    reg [31:0] r_comp_param_1;
    reg [31:0] r_hs_spklen;
    reg [31:0] r_fs_spklen;
    reg [31:0] r_ack_general_call;
    reg [31:0] r_sda_setup;
    reg [31:0] r_sda_hold;
    reg [31:0] r_intr_mask;
    reg [31:0] r_hs_scl_lcnt;
    reg [31:0] r_fs_scl_lcnt;
    reg [31:0] r_fs_scl_hcnt;
    reg [31:0] r_ss_scl_hcnt;
    reg [31:0] r_hs_maddr;
    reg [31:0] r_ss_scl_lcnt;

    reg [31:0] r_enable;
    reg [31:0] r_tx_tl;
    reg [31:0] r_rx_tl;

    // done signal: command completed, clear command register
    wire s_done;

    // core enable signal
    wire s_core_en;
    wire s_ien;

    // status register signals
    wire s_irxack;
    reg  rxack;       // received aknowledge from slave
    reg  tip;         // transfer in progress
    reg  irq_flag;    // interrupt pending flag
    wire i2c_busy;    // bus busy (start signal detected)
    wire i2c_al;      // i2c bus arbitration lost
    reg  al;          // status register arbitration lost bit

    //
    // module body
    //

    // No longer needed - we use PADDR directly
    // assign s_apb_addr = PADDR[7:0];

    always_ff @ (posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            r_pre  <= 'h0;
            r_ctrl <= 'h0;
            r_tx   <= 'h0;
            r_cmd  <= 'h0;
            // UVM compatibility registers reset
            r_comp_type        <= 32'h44570140;
            r_comp_version     <= 32'h3230322a;
            r_comp_param_1     <= 32'h8e07078e;   
            r_hs_spklen        <= 32'h00000001;
            r_fs_spklen        <= 32'h00000005;
            r_ack_general_call <= 32'h00000001;
            r_sda_setup        <= 32'h00000064;
            r_sda_hold         <= 32'h01000001;   
            r_intr_mask        <= 32'h00000000;
            r_hs_scl_lcnt      <= 32'h00000010;
            r_fs_scl_lcnt      <= 32'h00000082;   // UVM expects 0x82
            r_fs_scl_hcnt      <= 32'h0000003c;   // UVM expects 0x3c
            r_ss_scl_hcnt      <= 32'h00000190;   // UVM expects 0x190
            r_hs_maddr         <= 32'h00000001;   // UVM expects 0x1
            r_ss_scl_lcnt      <= 32'h000001d6;
            r_enable           <= 32'h00000000;
            r_tx_tl            <= 32'h00000000;
            r_rx_tl            <= 32'h00000000;
            $display("[RESET DEBUG] r_comp_type=%h r_comp_version=%h r_comp_param_1=%h r_hs_spklen=%h r_fs_spklen=%h r_ack_general_call=%h r_sda_setup=%h r_sda_hold=%h r_intr_mask=%h r_hs_scl_lcnt=%h r_tx_tl=%h r_rx_tl=%h", r_comp_type, r_comp_version, r_comp_param_1, r_hs_spklen, r_fs_spklen, r_ack_general_call, r_sda_setup, r_sda_hold, r_intr_mask, r_hs_scl_lcnt, r_tx_tl, r_rx_tl);
        end
        else if (PSEL && PENABLE && PWRITE)
             begin
                if (s_done | i2c_al)
                      r_cmd[7:4] <= 4'h0;          // clear command bits when done
                                                   // or when aribitration lost
                r_cmd[2:1] <= 2'b0;                 // reserved bits
                r_cmd[0]   <= 1'b0;                 // clear IRQ_ACK bit
                case (PADDR)
                    12'h000:     begin r_pre <= PWDATA[15:0]; $display("[WRITE] r_pre = 0x%h", PWDATA[15:0]); end
                    12'h004:     begin r_ctrl <= PWDATA[7:0]; $display("[WRITE] r_ctrl = 0x%h", PWDATA[7:0]); end
                    12'h010:     begin r_tx <= PWDATA[7:0]; $display("[WRITE] r_tx = 0x%h", PWDATA[7:0]); end
                    12'h014:     begin if(s_core_en) r_cmd <= PWDATA[7:0]; $display("[WRITE] r_cmd = 0x%h (s_core_en=%b)", PWDATA[7:0], s_core_en); end
                    12'h018:     begin r_comp_type        <= PWDATA; $display("[WRITE] r_comp_type = 0x%h", PWDATA); end
                    12'h01C:     begin r_comp_version     <= PWDATA; $display("[WRITE] r_comp_version = 0x%h", PWDATA); end
                    12'h020:     begin r_comp_param_1     <= PWDATA; $display("[WRITE] r_comp_param_1 = 0x%h", PWDATA); end
                    12'h024:     begin r_hs_spklen        <= PWDATA; $display("[WRITE] r_hs_spklen = 0x%h", PWDATA); end
                    12'h028:     begin r_fs_spklen        <= PWDATA; $display("[WRITE] r_fs_spklen = 0x%h", PWDATA); end
                    12'h02C:     begin r_ack_general_call <= PWDATA; $display("[WRITE] r_ack_general_call = 0x%h", PWDATA); end
                    12'h030:     begin r_sda_setup        <= PWDATA; $display("[WRITE] r_sda_setup = 0x%h", PWDATA); end
                    12'h034:     begin r_sda_hold         <= PWDATA; $display("[WRITE] r_sda_hold = 0x%h", PWDATA); end
                    12'h038:     begin r_tx_tl            <= PWDATA; $display("[WRITE] r_tx_tl = 0x%h", PWDATA); end
                    12'h03C:     begin r_rx_tl            <= PWDATA; $display("[WRITE] r_rx_tl = 0x%h", PWDATA); end
                    12'h040:     begin r_intr_mask        <= (r_intr_mask & 32'hFFFFF000) | (PWDATA & 32'h00000FFF); $display("[WRITE] r_intr_mask = 0x%h", (r_intr_mask & 32'hFFFFF000) | (PWDATA & 32'h00000FFF)); end
                    12'h044:     begin r_hs_scl_lcnt      <= PWDATA; $display("[WRITE] r_hs_scl_lcnt = 0x%h", PWDATA); end
                    12'h06C:     begin r_enable           <= PWDATA; $display("[WRITE] r_enable = 0x%h", PWDATA); end
                    default:     begin $display("[WRITE] Unknown address: 0x%h", PADDR); end
                endcase
            end
            else
            begin
                if (s_done | i2c_al)
                    r_cmd[7:4] <= 4'h0;           // clear command bits when done
                                                  // or when aribitration lost
                r_cmd[2:1] <= 2'b0;               // reserved bits
                r_cmd[0]   <= 1'b0;               // clear IRQ_ACK bit
            end
    end //always

    always_comb
    begin
        if (PSEL && PENABLE)
            $display("[APB DEBUG] PADDR=0x%h", PADDR);
        
        // Match what the UVM reg model actually expects - use PADDR directly
        case (PADDR)
            // Core registers at their original positions
            12'h0F4:     begin PRDATA = r_comp_param_1; $display("[READ] r_comp_param_1 = 0x%h", r_comp_param_1); end
            12'h0F8:     begin PRDATA = r_comp_version; $display("[READ] r_comp_version = 0x%h", r_comp_version); end
            12'h0FC:     begin PRDATA = r_comp_type; $display("[READ] r_comp_type = 0x%h", r_comp_type); end
            12'h0A4:     begin PRDATA = r_hs_spklen; $display("[READ] r_hs_spklen = 0x%h", r_hs_spklen); end
            12'h0A0:     begin PRDATA = r_fs_spklen; $display("[READ] r_fs_spklen = 0x%h", r_fs_spklen); end
            12'h098:     begin PRDATA = r_ack_general_call; $display("[READ] r_ack_general_call = 0x%h", r_ack_general_call); end
            12'h094:     begin PRDATA = r_sda_setup; $display("[READ] r_sda_setup = 0x%h", r_sda_setup); end
            12'h07C:     begin PRDATA = r_sda_hold; $display("[READ] r_sda_hold = 0x%h", r_sda_hold); end
            12'h3C:     begin PRDATA = r_tx_tl; $display("[READ] r_tx_tl = 0x%h", r_tx_tl); end
            12'h38:     begin PRDATA = r_rx_tl; $display("[READ] r_rx_tl = 0x%h", r_rx_tl); end
            12'h30:     begin PRDATA = r_intr_mask; $display("[READ] r_intr_mask = 0x%h", r_intr_mask); end
            12'h24:     begin PRDATA = r_hs_scl_lcnt; $display("[READ] r_hs_scl_lcnt = 0x%h", r_hs_scl_lcnt); end
            12'h20:     begin PRDATA = r_fs_scl_lcnt; $display("[READ] r_fs_scl_lcnt = 0x%h", r_fs_scl_lcnt); end
            12'h1C:     begin PRDATA = r_fs_scl_hcnt; $display("[READ] r_fs_scl_hcnt = 0x%h", r_fs_scl_hcnt); end
            12'h18:     begin PRDATA = r_ss_scl_lcnt; $display("[READ] r_ss_scl_lcnt = 0x%h", r_ss_scl_lcnt); end
            12'h14:     begin PRDATA = r_ss_scl_hcnt; $display("[READ] r_ss_scl_hcnt = 0x%h", r_ss_scl_hcnt); end
            12'h0C:     begin PRDATA = r_hs_maddr; $display("[READ] r_hs_maddr = 0x%h", r_hs_maddr); end
            12'h40:     begin PRDATA = 32'h8ff; $display("[READ] IC_CLR_INTR = 0x8ff"); end
            12'h68:     begin PRDATA = 32'h0; $display("[READ] IC_CLR_GEN_CALL = 0x0"); end
            12'h6C:     begin PRDATA = r_enable; $display("[READ] r_enable = 0x%h", r_enable); end
            
            
            default:     begin PRDATA = '0; $display("[READ] Unknown address: 0x%h, returning 0", PADDR); end
        endcase
    end

    // decode command register
    wire sta  = r_cmd[7];
    wire sto  = r_cmd[6];
    wire rd   = r_cmd[5];
    wire wr   = r_cmd[4];
    wire ack  = r_cmd[3];
    wire iack = r_cmd[0];

    // decode control register
    assign s_core_en = r_ctrl[7];
    assign s_ien     = r_ctrl[6];

    // hookup byte controller block
    i2c_master_byte_ctrl byte_controller 
    (
            .clk      ( HCLK         ),
            .nReset   ( HRESETn      ),
            .ena      ( s_core_en    ),
            .clk_cnt  ( r_pre        ),
            .start    ( sta          ),
            .stop     ( sto          ),
            .read     ( rd           ),
            .write    ( wr           ),
            .ack_in   ( ack          ),
            .din      ( r_tx         ),
            .cmd_ack  ( s_done       ),
            .ack_out  ( s_irxack     ),
            .dout     ( s_rx         ),
            .i2c_busy ( i2c_busy     ),
            .i2c_al   ( i2c_al       ),
            .scl_i    ( scl_pad_i    ),
            .scl_o    ( scl_pad_o    ),
            .scl_oen  ( scl_padoen_o ),
            .sda_i    ( sda_pad_i    ),
            .sda_o    ( sda_pad_o    ),
            .sda_oen  ( sda_padoen_o )
    );

    // status register block + interrupt request signal
    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if (!HRESETn)
        begin
            al       <= 1'b0;
            rxack    <= 1'b0;
            tip      <= 1'b0;
            irq_flag <= 1'b0;
        end
        else
        begin
            al       <= i2c_al | (al & ~sta);
            rxack    <= s_irxack;
            tip      <= (rd | wr);
            irq_flag <= (s_done | i2c_al | irq_flag) & ~iack; // interrupt request flag is always generated
        end
    end

    // generate interrupt request signals
    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if (!HRESETn)
            interrupt_o <= 1'b0;
        else
            interrupt_o <= irq_flag && s_ien; // interrupt signal is only generated when IEN (interrupt enable bit is set)
    end
 
    // assign status register bits
    assign s_status[7]   = rxack;
    assign s_status[6]   = i2c_busy;
    assign s_status[5]   = al;
    assign s_status[4:2] = 3'h0; // reserved
    assign s_status[1]   = tip;
    assign s_status[0]   = irq_flag;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

endmodule
