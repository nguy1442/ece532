`timescale 1ns / 1ps

/*
 * Testbench used to validate that the meta data has been correctly extracted by the input_queue
 * Note: This simulation will likely fail as this has not been updated after changes have been made
 *       to the input_queue. This changes include but are not limited to endianness of the IP address
 *       and IP
 */

module input_queue_tb #(
    // Number of packets each input port will send
    parameter N_PACKETS = 8,
    
    // Determines range of packet sizes in bytes
    parameter MIN_PACKET_LENG = 46,
    parameter MAX_PACKET_LENG = 1500,
    
    // Clock Period
    parameter CLK_P = 10
);

reg clk, resetn;
reg pmod_axis_tready, buf_axis_tready, meta_axis_tready;
reg [7:0] pmod_axis_tdata, buf_axis_tdata;
reg [31:0] meta_axis_tdata;
reg pmod_axis_tlast, buf_axis_tlast;
reg pmod_axis_tvalid, buf_axis_tvalid, meta_axis_tvalid;
integer i; 

typedef enum reg [15:0] {ipv4=16'h0800, arp=16'h0806, invalid} etherType;

task generatePacket(etherType headerType, input integer packetSize);
    reg [111:0] header;
    assign header = {headerType, -48'd1, -48'd1}; 
    
    //sync clock
    @(posedge clk);
    
    pmod_axis_tdata <= header[7:0];
    
    //Send header
    pmod_axis_tvalid <= 1'b1;
    for (i = 0; i < 14; i++) begin
        wait(pmod_axis_tready); // Wait until queue is ready
        pmod_axis_tdata <= header[8*i +: 8];
        @(posedge clk);
        #(CLK_P/2);
    end
    
    //Send body
    for (i = 0; i < packetSize; i++) begin
        wait(pmod_axis_tready); // Wait until arbitrator is ready
        if (i == packetSize - 1)
            pmod_axis_tlast <= 1'b1; // Last packet data
        pmod_axis_tdata <= i;
        @(posedge clk);
        #(CLK_P/2);
    end
    
    pmod_axis_tlast <= 1'b0;
    pmod_axis_tvalid <= 1'b0;
    pmod_axis_tdata <= 8'bX;
    @(posedge clk);
    
endtask

task checkPacket(etherType headerType, input integer packetSize);
    reg [111:0] header;
    assign header = {headerType, -48'd1, -48'd1}; 
    
    //sync clock
    @(posedge clk);
    
    //Check buf
    #(CLK_P/2);
    buf_axis_tready <= 1'b1;
    for (i = 0; i < 14; i++) begin
        wait(buf_axis_tvalid); // Wait until queue is ready
        if (buf_axis_tdata != header[8*i +: 8])
            $display("Mis-match in packet at time: %4d, %d \n", $time, i);
        @(posedge clk);
        #(CLK_P/2);
    end
        
    for (i = 0; i < packetSize; i++) begin
        if (buf_axis_tdata != i[7:0])
            $display("Mis-match in packet at time: %4d \n", $time);
        @(posedge clk);
        #(CLK_P/2);
    end
    buf_axis_tready = 1'b0;
    
    //Check metadata
    @(posedge clk);
    meta_axis_tready = 1'b1;
    if (headerType == arp)
        if (meta_axis_tdata != {8'd27,8'd26,8'd25,8'd24})
            $display("Mis-match in packet address: %4d \n", $time);
    else if (headerType == ipv4)
        if (meta_axis_tdata != {8'd19,8'd18,8'd17,8'd16})
            $display("Mis-match in packet address: %4d \n", $time);
    #(CLK_P);
    meta_axis_tready = 1'b0;
endtask

// DUT
input_queue DUT(
   //General ports
   .clk(clk),
   .resetn(resetn),
   
   // Ports of Axi Slave Bus Interface pmod_AXIS (input to block)
   .pmod_axis_tready(pmod_axis_tready),
   .pmod_axis_tdata(pmod_axis_tdata),
   .pmod_axis_tlast(pmod_axis_tlast),
   .pmod_axis_tvalid(pmod_axis_tvalid),
   
   // Ports of Axi Master Bus Interface buf_AXIS (output of data queue)
   .buf_axis_tvalid(buf_axis_tvalid),
   .buf_axis_tdata(buf_axis_tdata),
   .buf_axis_tlast(buf_axis_tlast),
   .buf_axis_tready(buf_axis_tready),
   
   // Ports of Axi Master Bus Interface meta_AXIS (output of meta queue)
   .meta_axis_tvalid(meta_axis_tvalid),
   .meta_axis_tdata(meta_axis_tdata),
   .meta_axis_tready(meta_axis_tready)
);

/* Clock generator */
always begin
    #(CLK_P / 2) clk = ~clk;
end

/* Main code for the testbench */
initial begin
    $display("Beginning simulation of the input queue!");
    
    // Reset
    clk = 1;
    resetn = 0;
    
    // Signal initialization
    pmod_axis_tvalid <= 1'b0;
    pmod_axis_tlast <= 1'b0;
    buf_axis_tready <= 1'b0;
    meta_axis_tready <= 1'b0;
    
    #(CLK_P);
    resetn = 1;
    #(CLK_P);
      
    generatePacket(arp, 64);  
    generatePacket(invalid, 64);
    checkPacket(arp, 64);
    checkPacket(invalid, 64);
    
    generatePacket(arp, 500);
    generatePacket(arp, 46);
    
    checkPacket(arp, 500);
    checkPacket(arp, 46);
        
    $display("Simulation complete!");
    $stop;
end

    
endmodule