
`timescale 1 ns / 1 ps

module pmod_nic100_axi_stream_ip_v1_0 (
    // NIC100 Pmod signals
    output wire pmod_mosi,
    input wire pmod_miso,
    output wire pmod_ss,
    output wire pmod_sck,
    
	// AXI4Stream Slave signals
    output wire s_axis_tready,
    input wire [31:0] s_axis_tdata,
    input wire s_axis_tlast,
    input wire s_axis_tvalid,
    
    // AXI4Stream Master signals
    input wire m_axis_tready,
    output wire [31:0] m_axis_tdata,
    output wire m_axis_tlast,
    output wire m_axis_tvalid,
    
    input wire axis_aclk,
    input wire axis_resetn
);

    wire wr_valid, wr_done, wr_got_byte, rd_valid, rd_stop, ss;
    wire [7:0] wr_data, rd_data;

    pmod_nic100_axi_stream_controller axi_stream_controller_inst (
        .AXIS_ACLK(axis_aclk),
        .AXIS_ARESETN(axis_resetn),
        
        .S_AXIS_TREADY(s_axis_tready),
        .S_AXIS_TDATA(s_axis_tdata),
        .S_AXIS_TLAST(s_axis_tlast),
        .S_AXIS_TVALID(s_axis_tvalid),
        
        .M_AXIS_TREADY(m_axis_tready),
        .M_AXIS_TDATA(m_axis_tdata),
        .M_AXIS_TLAST(m_axis_tlast),
        .M_AXIS_TVALID(m_axis_tvalid),
        
        .wr_valid(wr_valid),
        .wr_data(wr_data),
        .wr_done(wr_done),
        .wr_got_byte(wr_got_byte),
        .rd_valid(rd_valid),
        .rd_stop(rd_stop),
        .rd_data(rd_data)
    );

    pmod_nic100_spi_controller spi_controller_inst (
        .wr_valid(wr_valid),
        .wr_data(wr_data),
        .wr_done(wr_done),
        .wr_got_byte(wr_got_byte),
    
        .rd_valid(rd_valid),
        .rd_stop(rd_stop),
        .rd_data(rd_data),
    
        .ss(ss),
        .pmod_mosi(pmod_mosi),
        .pmod_miso(pmod_miso),
    
        .clk(axis_aclk),
        .rst(axis_resetn)
    );

    pmod_nic100_clock clock_inst (
        .ss(ss),
        .pmod_sck(pmod_sck),
        .clk(axis_aclk),
        .rst(axis_resetn)
    );

    assign pmod_ss = ss;
endmodule
