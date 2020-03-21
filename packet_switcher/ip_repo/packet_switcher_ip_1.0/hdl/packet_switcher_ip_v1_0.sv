`timescale 1ns / 1ps

module packet_switcher_ip_v1_0 #(
	parameter integer CONFIG_AXI_S_DATA_WIDTH = 32,
    parameter integer CONFIG_AXI_S_ADDR_WIDTH = 7
) (
    input wire clk,
    input wire resetn,
    
    // AXI Stream Master interfaces to PMODs
    
    input wire pmod_a_axis_m_tready,
    output wire [31:0] pmod_a_axis_m_tdata,
    output wire pmod_a_axis_m_tlast,
    output wire pmod_a_axis_m_tvalid,

    input wire pmod_b_axis_m_tready,
    output wire [31:0] pmod_b_axis_m_tdata,
    output wire pmod_b_axis_m_tlast,
    output wire pmod_b_axis_m_tvalid,
    
    input wire pmod_c_axis_m_tready,
    output wire [31:0] pmod_c_axis_m_tdata,
    output wire pmod_c_axis_m_tlast,
    output wire pmod_c_axis_m_tvalid,
    
    // AXI Stream Slave interfaces to PMODs
    
    output wire pmod_a_axis_s_tready,
    input wire [31:0] pmod_a_axis_s_tdata,
    input wire pmod_a_axis_s_tlast,
    input wire pmod_a_axis_s_tvalid,
    
    output wire pmod_b_axis_s_tready,
    input wire [31:0] pmod_b_axis_s_tdata,
    input wire pmod_b_axis_s_tlast,
    input wire pmod_b_axis_s_tvalid,
    
    output wire pmod_c_axis_s_tready,
    input wire [31:0] pmod_c_axis_s_tdata,
    input wire pmod_c_axis_s_tlast,
    input wire pmod_c_axis_s_tvalid,
    
    // AXI Lite Slave interface for configuration
    
    input wire [CONFIG_AXI_S_ADDR_WIDTH-1:0] config_axi_s_awaddr,
    input wire [2:0] config_axi_s_awprot,
    input wire config_axi_s_awvalid,
    output wire config_axi_s_awready,
    input wire [CONFIG_AXI_S_DATA_WIDTH-1:0] config_axi_s_wdata,  
    input wire [(CONFIG_AXI_S_DATA_WIDTH/8)-1:0] config_axi_s_wstrb,
    input wire config_axi_s_wvalid,
    output wire config_axi_s_wready,
    output wire [1:0] config_axi_s_bresp,
    output wire config_axi_s_bvalid,
    input wire config_axi_s_bready,
    input wire [CONFIG_AXI_S_ADDR_WIDTH-1:0] config_axi_s_araddr,
    input wire [2:0] config_axi_s_arprot,
    input wire config_axi_s_arvalid,
    output wire config_axi_s_arready,
    output wire [CONFIG_AXI_S_DATA_WIDTH-1:0] config_axi_s_rdata,
    output wire [1:0] config_axi_s_rresp,
    output wire config_axi_s_rvalid,
    input wire config_axi_s_rready
);
    
    wire buf_a_axis_tvalid, buf_a_axis_tlast, buf_a_axis_tready;
    wire [7:0] buf_a_axis_tdata;
    wire meta_a_axis_tvalid, meta_a_axis_tready;
    wire [31:0] meta_a_axis_tdata;
    
    wire buf_b_axis_tvalid, buf_b_axis_tlast, buf_b_axis_tready;
    wire [7:0] buf_b_axis_tdata;
    wire meta_b_axis_tvalid, meta_b_axis_tready;
    wire [31:0] meta_b_axis_tdata;
    
    wire buf_c_axis_tvalid, buf_c_axis_tlast, buf_c_axis_tready;
    wire [7:0] buf_c_axis_tdata;
    wire meta_c_axis_tvalid, meta_c_axis_tready;
    wire [31:0] meta_c_axis_tdata;
    
    //counters output wires
    wire [31:0] packet_received_count_a;
    wire [31:0] packet_received_count_b;
    wire [31:0] packet_received_count_c;
    
    wire [31:0] packet_droped_count_a;
    wire [31:0] packet_droped_count_b;
    wire [31:0] packet_droped_count_c;
    
	// AXI4LITE signals
    reg [CONFIG_AXI_S_ADDR_WIDTH-1 : 0]     axi_awaddr;
    reg      axi_awready;
    reg      axi_wready;
    reg [1 : 0]     axi_bresp;
    reg      axi_bvalid;
    reg [CONFIG_AXI_S_ADDR_WIDTH-1 : 0]     axi_araddr;
    reg      axi_arready;
    reg [CONFIG_AXI_S_DATA_WIDTH-1 : 0]     axi_rdata;
    reg [1 : 0]     axi_rresp;
    reg      axi_rvalid;

    // Example-specific design signals
    // local parameter for addressing 32 bit / 64 bit CONFIG_AXI_S_DATA_WIDTH
    // ADDR_LSB is used for addressing 32/64 bit registers/memories
    // ADDR_LSB = 2 for 32 bits (n downto 2)
    // ADDR_LSB = 3 for 64 bits (n downto 3)
    localparam integer ADDR_LSB = (CONFIG_AXI_S_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 4;
    //----------------------------------------------
    //-- Signals for user logic register space example
    //------------------------------------------------
    //-- Number of Slave Registers 64
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg0;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg1;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg2;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg3;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg4;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg5;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg6;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg7;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg8;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg9;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg10;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg11;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg12;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg13;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg14;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg15;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg16;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg17;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg18;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg19;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg20;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg21;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg22;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg23;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg24;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg25;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg26;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg27;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg28;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg29;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg30;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]    slv_reg31;
    wire     slv_reg_rden;
    wire     slv_reg_wren;
    reg [CONFIG_AXI_S_DATA_WIDTH-1:0]     reg_data_out;
    integer     byte_index;
    reg     aw_en;

    // I/O Connections assignments

    assign config_axi_s_awready    = axi_awready;
    assign config_axi_s_wready    = axi_wready;
    assign config_axi_s_bresp    = axi_bresp;
    assign config_axi_s_bvalid    = axi_bvalid;
    assign config_axi_s_arready    = axi_arready;
    assign config_axi_s_rdata    = axi_rdata;
    assign config_axi_s_rresp    = axi_rresp;
    assign config_axi_s_rvalid    = axi_rvalid;
    // Implement axi_awready generation
    // axi_awready is asserted for one clk clock cycle when both
    // config_axi_s_awvalid and config_axi_s_wvalid are asserted. axi_awready is
    // de-asserted when reset is low.

    always @( posedge clk )
    begin
      if ( resetn == 1'b0 )
        begin
          axi_awready <= 1'b0;
          aw_en <= 1'b1;
        end 
      else
        begin    
          if (~axi_awready && config_axi_s_awvalid && config_axi_s_wvalid && aw_en)
            begin
              // slave is ready to accept write address when 
              // there is a valid write address and write data
              // on the write address and data bus. This design 
              // expects no outstanding transactions. 
              axi_awready <= 1'b1;
              aw_en <= 1'b0;
            end
            else if (config_axi_s_bready && axi_bvalid)
                begin
                  aw_en <= 1'b1;
                  axi_awready <= 1'b0;
                end
          else           
            begin
              axi_awready <= 1'b0;
            end
        end 
    end       

    // Implement axi_awaddr latching
    // This process is used to latch the address when both 
    // config_axi_s_awvalid and config_axi_s_wvalid are valid. 

    always @( posedge clk )
    begin
      if ( resetn == 1'b0 )
        begin
          axi_awaddr <= 0;
        end 
      else
        begin    
          if (~axi_awready && config_axi_s_awvalid && config_axi_s_wvalid && aw_en)
            begin
              // Write Address latching 
              axi_awaddr <= config_axi_s_awaddr;
            end
        end 
    end       

    // Implement axi_wready generation
    // axi_wready is asserted for one clk clock cycle when both
    // config_axi_s_awvalid and config_axi_s_wvalid are asserted. axi_wready is 
    // de-asserted when reset is low. 

    always @( posedge clk )
    begin
      if ( resetn == 1'b0 )
        begin
          axi_wready <= 1'b0;
        end 
      else
        begin    
          if (~axi_wready && config_axi_s_wvalid && config_axi_s_awvalid && aw_en )
            begin
              // slave is ready to accept write data when 
              // there is a valid write address and write data
              // on the write address and data bus. This design 
              // expects no outstanding transactions. 
              axi_wready <= 1'b1;
            end
          else
            begin
              axi_wready <= 1'b0;
            end
        end 
    end       

    // Implement memory mapped register select and write logic generation
    // The write data is accepted and written to memory mapped registers when
    // axi_awready, config_axi_s_wvalid, axi_wready and config_axi_s_wvalid are asserted. Write strobes are used to
    // select byte enables of slave registers while writing.
    // These registers are cleared when reset (active low) is applied.
    // Slave register write enable is asserted when valid address and data are available
    // and the slave is ready to accept the write address and write data.
    assign slv_reg_wren = axi_wready && config_axi_s_wvalid && axi_awready && config_axi_s_awvalid;

    always @( posedge clk )
    begin
      if ( resetn == 1'b0 )
        begin
          slv_reg0 <= 32'hc0a8010a; //192.168.1.10
          slv_reg1 <= 32'hc0a8010b; //192.168.1.11
          slv_reg2 <= 32'hc0a8010c; //192.168.1.12
          slv_reg3 <= 0;
          slv_reg4 <= 0;
          slv_reg5 <= 0;
          slv_reg6 <= 0;
          slv_reg7 <= 0;
          slv_reg8 <= 0;
          slv_reg9 <= 0;
          slv_reg10 <= 0;
          slv_reg11 <= 0;
          slv_reg12 <= 0;
          slv_reg13 <= 0;
          slv_reg14 <= 0;
          slv_reg15 <= 0;
          slv_reg16 <= 0;
          slv_reg17 <= 0;
          slv_reg18 <= 0;
          slv_reg19 <= 0;
          slv_reg20 <= 0;
          slv_reg21 <= 0;
          slv_reg22 <= 0;
          slv_reg23 <= 0;
          slv_reg24 <= 0;
          slv_reg25 <= 0;
          slv_reg26 <= 0;
          slv_reg27 <= 0;
          slv_reg28 <= 0;
          slv_reg29 <= 0;
          slv_reg30 <= 0;
          slv_reg31 <= 0;
        end 
      else begin
        if (slv_reg_wren)
          begin
            case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
              5'h00:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 0
                    slv_reg0[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h01:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 1
                    slv_reg1[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h02:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 2
                    slv_reg2[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h03:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 3
                    slv_reg3[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h04:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 4
                    slv_reg4[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h05:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 5
                    slv_reg5[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h06:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 6
                    slv_reg6[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h07:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 7
                    slv_reg7[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h08:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 8
                    slv_reg8[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h09:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 9
                    slv_reg9[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h0A:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 10
                    slv_reg10[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h0B:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 11
                    slv_reg11[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h0C:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 12
                    slv_reg12[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h0D:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 13
                    slv_reg13[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h0E:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 14
                    slv_reg14[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h0F:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 15
                    slv_reg15[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h10:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 16
                    slv_reg16[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h11:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 17
                    slv_reg17[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h12:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 18
                    slv_reg18[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h13:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 19
                    slv_reg19[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h14:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 20
                    slv_reg20[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h15:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 21
                    slv_reg21[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h16:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 22
                    slv_reg22[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h17:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 23
                    slv_reg23[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h18:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 24
                    slv_reg24[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h19:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 25
                    slv_reg25[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h1A:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 26
                    slv_reg26[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h1B:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 27
                    slv_reg27[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h1C:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 28
                    slv_reg28[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h1D:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 29
                    slv_reg29[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h1E:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 30
                    slv_reg30[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end  
              5'h1F:
                for ( byte_index = 0; byte_index <= (CONFIG_AXI_S_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( config_axi_s_wstrb[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 31
                    slv_reg31[(byte_index*8) +: 8] <= config_axi_s_wdata[(byte_index*8) +: 8];
                  end
              default : begin
                          slv_reg0 <= slv_reg0;
                          slv_reg1 <= slv_reg1;
                          slv_reg2 <= slv_reg2;
                          slv_reg3 <= slv_reg3;
                          slv_reg4 <= packet_received_count_a;
                          slv_reg5 <= packet_received_count_b;
                          slv_reg6 <= packet_received_count_b;
                          slv_reg7 <= slv_reg7;
                          slv_reg8 <= packet_droped_count_a;
                          slv_reg9 <= packet_droped_count_b;
                          slv_reg10 <= packet_droped_count_c;
                          slv_reg11 <= slv_reg11;
                          slv_reg12 <= slv_reg12;
                          slv_reg13 <= slv_reg13;
                          slv_reg14 <= slv_reg14;
                          slv_reg15 <= slv_reg15;
                          slv_reg16 <= slv_reg16;
                          slv_reg17 <= slv_reg17;
                          slv_reg18 <= slv_reg18;
                          slv_reg19 <= slv_reg19;
                          slv_reg20 <= slv_reg20;
                          slv_reg21 <= slv_reg21;
                          slv_reg22 <= slv_reg22;
                          slv_reg23 <= slv_reg23;
                          slv_reg24 <= slv_reg24;
                          slv_reg25 <= slv_reg25;
                          slv_reg26 <= slv_reg26;
                          slv_reg27 <= slv_reg27;
                          slv_reg28 <= slv_reg28;
                          slv_reg29 <= slv_reg29;
                          slv_reg30 <= slv_reg30;
                          slv_reg31 <= slv_reg31;
                        end
            endcase
          end
      end
    end    

    // Implement write response logic generation
    // The write response and response valid signals are asserted by the slave 
    // when axi_wready, config_axi_s_wvalid, axi_wready and config_axi_s_wvalid are asserted.  
    // This marks the acceptance of address and indicates the status of 
    // write transaction.

    always @( posedge clk )
    begin
      if ( resetn == 1'b0 )
        begin
          axi_bvalid  <= 0;
          axi_bresp   <= 2'b0;
        end 
      else
        begin    
          if (axi_awready && config_axi_s_awvalid && ~axi_bvalid && axi_wready && config_axi_s_wvalid)
            begin
              // indicates a valid write response is available
              axi_bvalid <= 1'b1;
              axi_bresp  <= 2'b0; // 'OKAY' response 
            end                   // work error responses in future
          else
            begin
              if (config_axi_s_bready && axi_bvalid) 
                //check if bready is asserted while bvalid is high) 
                //(there is a possibility that bready is always asserted high)   
                begin
                  axi_bvalid <= 1'b0; 
                end  
            end
        end
    end   

    // Implement axi_arready generation
    // axi_arready is asserted for one clk clock cycle when
    // config_axi_s_arvalid is asserted. axi_awready is 
    // de-asserted when reset (active low) is asserted. 
    // The read address is also latched when config_axi_s_arvalid is 
    // asserted. axi_araddr is reset to zero on reset assertion.

    always @( posedge clk )
    begin
      if ( resetn == 1'b0 )
        begin
          axi_arready <= 1'b0;
          axi_araddr  <= 32'b0;
        end 
      else
        begin    
          if (~axi_arready && config_axi_s_arvalid)
            begin
              // indicates that the slave has acceped the valid read address
              axi_arready <= 1'b1;
              // Read address latching
              axi_araddr  <= config_axi_s_araddr;
            end
          else
            begin
              axi_arready <= 1'b0;
            end
        end 
    end       

    // Implement axi_arvalid generation
    // axi_rvalid is asserted for one clk clock cycle when both 
    // config_axi_s_arvalid and axi_arready are asserted. The slave registers 
    // data are available on the axi_rdata bus at this instance. The 
    // assertion of axi_rvalid marks the validity of read data on the 
    // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
    // is deasserted on reset (active low). axi_rresp and axi_rdata are 
    // cleared to zero on reset (active low).  
    always @( posedge clk )
    begin
      if ( resetn == 1'b0 )
        begin
          axi_rvalid <= 0;
          axi_rresp  <= 0;
        end 
      else
        begin    
          if (axi_arready && config_axi_s_arvalid && ~axi_rvalid)
            begin
              // Valid read data is available at the read data bus
              axi_rvalid <= 1'b1;
              axi_rresp  <= 2'b0; // 'OKAY' response
            end   
          else if (axi_rvalid && config_axi_s_rready)
            begin
              // Read data is accepted by the master
              axi_rvalid <= 1'b0;
            end                
        end
    end    

    // Implement memory mapped register select and read logic generation
    // Slave register read enable is asserted when valid address is available
    // and the slave is ready to accept the read address.
    assign slv_reg_rden = axi_arready & config_axi_s_arvalid & ~axi_rvalid;
    always @(*)
    begin
          // Address decoding for reading registers
          case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
            5'h00   : reg_data_out <= slv_reg0;
            5'h01   : reg_data_out <= slv_reg1;
            5'h02   : reg_data_out <= slv_reg2;
            5'h03   : reg_data_out <= slv_reg3;
            5'h04   : reg_data_out <= slv_reg4;
            5'h05   : reg_data_out <= slv_reg5;
            5'h06   : reg_data_out <= slv_reg6;
            5'h07   : reg_data_out <= slv_reg7;
            5'h08   : reg_data_out <= slv_reg8;
            5'h09   : reg_data_out <= slv_reg9;
            5'h0A   : reg_data_out <= slv_reg10;
            5'h0B   : reg_data_out <= slv_reg11;
            5'h0C   : reg_data_out <= slv_reg12;
            5'h0D   : reg_data_out <= slv_reg13;
            5'h0E   : reg_data_out <= slv_reg14;
            5'h0F   : reg_data_out <= slv_reg15;
            5'h10   : reg_data_out <= slv_reg16;
            5'h11   : reg_data_out <= slv_reg17;
            5'h12   : reg_data_out <= slv_reg18;
            5'h13   : reg_data_out <= slv_reg19;
            5'h14   : reg_data_out <= slv_reg20;
            5'h15   : reg_data_out <= slv_reg21;
            5'h16   : reg_data_out <= slv_reg22;
            5'h17   : reg_data_out <= slv_reg23;
            5'h18   : reg_data_out <= slv_reg24;
            5'h19   : reg_data_out <= slv_reg25;
            5'h1A   : reg_data_out <= slv_reg26;
            5'h1B   : reg_data_out <= slv_reg27;
            5'h1C   : reg_data_out <= slv_reg28;
            5'h1D   : reg_data_out <= slv_reg29;
            5'h1E   : reg_data_out <= slv_reg30;
            5'h1F   : reg_data_out <= slv_reg31;
            default : reg_data_out <= 0;
          endcase
    end

    // Output register or memory read data
    always @( posedge clk )
    begin
      if ( resetn == 1'b0 )
        begin
          axi_rdata  <= 0;
        end 
      else
        begin    
          // When there is a valid read address (config_axi_s_arvalid) with 
          // acceptance of read address by the slave (axi_arready), 
          // output the read dada 
          if (slv_reg_rden)
            begin
              axi_rdata <= reg_data_out;     // register read data
            end   
        end
    end
    
    // All input packet buffer instances
    
    input_queue port_a_bufs (
       .clk(clk),
       .resetn(resetn),
       
       .pmod_axis_tready(pmod_a_axis_s_tready),
       .pmod_axis_tdata(pmod_a_axis_s_tdata[7:0]),
       .pmod_axis_tlast(pmod_a_axis_s_tlast),
       .pmod_axis_tvalid(pmod_a_axis_s_tvalid),
       
       .buf_axis_tvalid(buf_a_axis_tvalid),
       .buf_axis_tdata(buf_a_axis_tdata),
       .buf_axis_tlast(buf_a_axis_tlast),
       .buf_axis_tready(buf_a_axis_tready),
       
       .meta_axis_tvalid(meta_a_axis_tvalid),
       .meta_axis_tdata(meta_a_axis_tdata),
       .meta_axis_tready(meta_a_axis_tready),
       
       .packet_received_count(packet_received_count_a)
    );
    
    input_queue port_b_bufs (
       .clk(clk),
       .resetn(resetn),
       
       .pmod_axis_tready(pmod_b_axis_s_tready),
       .pmod_axis_tdata(pmod_b_axis_s_tdata[7:0]),
       .pmod_axis_tlast(pmod_b_axis_s_tlast),
       .pmod_axis_tvalid(pmod_b_axis_s_tvalid),
       
       .buf_axis_tvalid(buf_b_axis_tvalid),
       .buf_axis_tdata(buf_b_axis_tdata),
       .buf_axis_tlast(buf_b_axis_tlast),
       .buf_axis_tready(buf_b_axis_tready),
       
       .meta_axis_tvalid(meta_b_axis_tvalid),
       .meta_axis_tdata(meta_b_axis_tdata),
       .meta_axis_tready(meta_b_axis_tready),
              
       .packet_received_count(packet_received_count_b)
    );
    
    input_queue port_c_bufs (
       .clk(clk),
       .resetn(resetn),
       
       .pmod_axis_tready(pmod_c_axis_s_tready),
       .pmod_axis_tdata(pmod_c_axis_s_tdata[7:0]),
       .pmod_axis_tlast(pmod_c_axis_s_tlast),
       .pmod_axis_tvalid(pmod_c_axis_s_tvalid),
       
       .buf_axis_tvalid(buf_c_axis_tvalid),
       .buf_axis_tdata(buf_c_axis_tdata),
       .buf_axis_tlast(buf_c_axis_tlast),
       .buf_axis_tready(buf_c_axis_tready),
       
       .meta_axis_tvalid(meta_c_axis_tvalid),
       .meta_axis_tdata(meta_c_axis_tdata),
       .meta_axis_tready(meta_c_axis_tready),
              
       .packet_received_count(packet_received_count_c)
    );
    
    // Packet Arbiter instance
    
    packet_arbiter arbiter (
        .clk(clk),
        .resetn(resetn),
    
        .buf_a_axis_tvalid(buf_a_axis_tvalid),
        .buf_a_axis_tdata(buf_a_axis_tdata),
        .buf_a_axis_tlast(buf_a_axis_tlast),
        .buf_a_axis_tready(buf_a_axis_tready),
    
        .meta_a_axis_tvalid(meta_a_axis_tvalid),
        .meta_a_axis_tdata(meta_a_axis_tdata),
        .meta_a_axis_tready(meta_a_axis_tready),

        .buf_b_axis_tvalid(buf_b_axis_tvalid),
        .buf_b_axis_tdata(buf_b_axis_tdata),
        .buf_b_axis_tlast(buf_b_axis_tlast),
        .buf_b_axis_tready(buf_b_axis_tready),
    
        .meta_b_axis_tvalid(meta_b_axis_tvalid),
        .meta_b_axis_tdata(meta_b_axis_tdata),
        .meta_b_axis_tready(meta_b_axis_tready),

        .buf_c_axis_tvalid(buf_c_axis_tvalid),
        .buf_c_axis_tdata(buf_c_axis_tdata),
        .buf_c_axis_tlast(buf_c_axis_tlast),
        .buf_c_axis_tready(buf_c_axis_tready),
    
        .meta_c_axis_tvalid(meta_c_axis_tvalid),
        .meta_c_axis_tdata(meta_c_axis_tdata),
        .meta_c_axis_tready(meta_c_axis_tready),
    
        .pmod_a_axis_tready(pmod_a_axis_m_tready),
        .pmod_a_axis_tdata(pmod_a_axis_m_tdata),
        .pmod_a_axis_tlast(pmod_a_axis_m_tlast),
        .pmod_a_axis_tvalid(pmod_a_axis_m_tvalid),
    
        .pmod_b_axis_tready(pmod_b_axis_m_tready),
        .pmod_b_axis_tdata(pmod_b_axis_m_tdata),
        .pmod_b_axis_tlast(pmod_b_axis_m_tlast),
        .pmod_b_axis_tvalid(pmod_b_axis_m_tvalid),
    
        .pmod_c_axis_tready(pmod_c_axis_m_tready),
        .pmod_c_axis_tdata(pmod_c_axis_m_tdata),
        .pmod_c_axis_tlast(pmod_c_axis_m_tlast),
        .pmod_c_axis_tvalid(pmod_c_axis_m_tvalid),
        
        .port_a_IP(slv_reg0),
        .port_b_IP(slv_reg1),
        .port_c_IP(slv_reg2),
        
        .packet_droped_count_a(packet_droped_count_a),
        .packet_droped_count_b(packet_droped_count_b),
        .packet_droped_count_c(packet_droped_count_c)
    );
endmodule
