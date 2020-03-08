`timescale 1ns / 1ps

/* Testbench for the arbitration module */

// NOTE: We assume that...
//  Port A maps to Port 1, Port B maps to Port 2, etc.
module packet_arbiter_tb #(

    // Number of packets each input port will send
    parameter N_PACKETS = 8,
    
    // Determines range of packet sizes in bytes
    parameter MIN_PACKET_LENG = 8,
    parameter MAX_PACKET_LENG = 48,
    
    // Clock Period
    parameter CLK_P = 10
);

/* Testbench Signals (connections to DUT) */
reg clk, resetn;
reg buf_a_axis_tvalid, buf_b_axis_tvalid, buf_c_axis_tvalid;
reg [7:0] buf_a_axis_tdata, buf_b_axis_tdata, buf_c_axis_tdata;
reg buf_a_axis_tlast, buf_b_axis_tlast, buf_c_axis_tlast;
reg buf_a_axis_tready, buf_b_axis_tready, buf_c_axis_tready;

reg meta_a_axis_tvalid, meta_b_axis_tvalid, meta_c_axis_tvalid;
reg [31:0] meta_a_axis_tdata, meta_b_axis_tdata, meta_c_axis_tdata;
reg meta_a_axis_tready, meta_b_axis_tready, meta_c_axis_tready;

reg pmod_a_axis_tready, pmod_b_axis_tready, pmod_c_axis_tready;
reg [31:0] pmod_a_axis_tdata, pmod_b_axis_tdata, pmod_c_axis_tdata;
reg pmod_a_axis_tlast, pmod_b_axis_tlast, pmod_c_axis_tlast;
reg pmod_a_axis_tvalid, pmod_b_axis_tvalid, pmod_c_axis_tvalid;

/* Testbench Signals (internal) */
// WIP

/* Helper Tasks for the Testbench */
task genStimulus_a();
    
    integer i;   
    $display("Generating packets on Port 1...");
    
    for (i = 0; i < N_PACKETS; i++) begin
        genPacket_a(i);
    end
endtask

// Waits between 1 and 10 clock cycles
task minorDelay();
    integer delayCycles = $urandom_range(10, 1);
    #(delayCycles * CLK_P);
endtask

// Sends a single packet on input port 1
task genPacket_a(integer packetNum);
    integer packetSize, originatorPort, destinationPort, i;
    packetSize = $urandom_range(MAX_PACKET_LENG, MIN_PACKET_LENG);
   
    // Initialize packet fields
    buf_a_axis_tvalid <= 1'b1;
    meta_a_axis_tvalid <= 1'b1;
    originatorPort = 1; // 1 for Port A
    destinationPort = ($urandom_range(1, 0) == 0) ? 2 : 3; // Route to B or C
    if ($urandom_range(9, 0) == 9) destinationPort = 666; // 10% chance to route to an invalid location
    
    meta_a_axis_tdata <= 32'hc0a80109 + destinationPort;
    
    // For debugging, preface the first block in the packet data with...
    //  The port encoding (the originator) - MSB 3 bits
    //  The packet number - LSB 5 bits
    buf_a_axis_tdata <= {originatorPort[2:0], packetNum[4:0]};
    
    $display("(%10d) - Sending Packet on Port 1 - Length: %6d Bytes, Destination: %2d", $time, packetSize, destinationPort);
    
    // Send packet data byte-by-byte
    for (i = 0; i < packetSize; i++) begin
        integer data;
        
        if (i == packetSize - 1)
            buf_a_axis_tlast <= 1'b1; // Last packet data
        
        wait(buf_a_axis_tready); // Wait until arbitrator is ready
        @(posedge clk);
        #(CLK_P);
        
        // RNG Data
        buf_a_axis_tdata <= $urandom_range(255, 0);
    end
    
    // Deassert signals at the end
    buf_a_axis_tlast <= 1'b0;
    buf_a_axis_tvalid <= 1'b0;
    buf_a_axis_tdata <= 32'bX;
    meta_a_axis_tvalid <= 1'b0;
    meta_a_axis_tdata <= 32'bX;
    
    minorDelay(); // Arbitrary delay between subsequent packets
endtask

 
/* Connections to Packet Arbiter DUT */
packet_arbiter pa(
.clk(clk), .resetn(resetn),

// AXI Stream Slave from Input Buffers
.buf_a_axis_tvalid(buf_a_axis_tvalid), .buf_a_axis_tdata(buf_a_axis_tdata), 
.buf_a_axis_tlast(buf_a_axis_tlast), .buf_a_axis_tready(buf_a_axis_tready),
.meta_a_axis_tvalid(meta_a_axis_tvalid), .meta_a_axis_tdata(meta_a_axis_tdata), 
.meta_a_axis_tready(meta_a_axis_tready),
.buf_b_axis_tvalid(buf_b_axis_tvalid), .buf_b_axis_tdata(buf_b_axis_tdata),
.buf_b_axis_tlast(buf_b_axis_tlast), .buf_b_axis_tready(buf_b_axis_tready),
.meta_b_axis_tvalid(meta_b_axis_tvalid), .meta_b_axis_tdata(meta_b_axis_tdata), 
.meta_b_axis_tready(meta_b_axis_tready),
.buf_c_axis_tvalid(buf_c_axis_tvalid), .buf_c_axis_tdata(buf_c_axis_tdata),
.buf_c_axis_tlast(buf_c_axis_tlast), .buf_c_axis_tready(buf_c_axis_tready),
.meta_c_axis_tvalid(meta_c_axis_tvalid), .meta_c_axis_tdata(meta_c_axis_tdata), 
.meta_c_axis_tready(meta_c_axis_tready),

// AXI Stream Master to PMOD
.pmod_a_axis_tready(pmod_a_axis_tready), .pmod_a_axis_tdata(pmod_a_axis_tdata), 
.pmod_a_axis_tlast(pmod_a_axis_tlast), .pmod_a_axis_tvalid(pmod_a_axis_tvalid),
.pmod_b_axis_tready(pmod_b_axis_tready), .pmod_b_axis_tdata(pmod_b_axis_tdata), 
.pmod_b_axis_tlast(pmod_b_axis_tlast), .pmod_b_axis_tvalid(pmod_b_axis_tvalid),
.pmod_c_axis_tready(pmod_c_axis_tready), .pmod_c_axis_tdata(pmod_c_axis_tdata), 
.pmod_c_axis_tlast(pmod_c_axis_tlast), .pmod_c_axis_tvalid(pmod_c_axis_tvalid)
);

/* Clock generator */
always begin
    #(CLK_P / 2) clk = ~clk;
end

/* Main code for the testbench */
initial begin
    
    $display("Beginning simulation of the Arbiter!");
    
    // Reset
    clk = 1;
    resetn = 0;
    
    // Signal initialization
    buf_a_axis_tvalid <= 1'b0;
    buf_b_axis_tvalid <= 1'b0;
    buf_c_axis_tvalid <= 1'b0;
    meta_a_axis_tvalid <= 1'b0;
    meta_b_axis_tvalid <= 1'b0;
    meta_c_axis_tvalid <= 1'b0;
    buf_a_axis_tlast <= 1'b0;
    buf_b_axis_tlast <= 1'b0;
    buf_c_axis_tlast <= 1'b0;
    
    // Assume PMOD is always accepting input, TODO: Change?
    pmod_a_axis_tready <= 1'b1;
    pmod_b_axis_tready <= 1'b1;
    pmod_c_axis_tready <= 1'b1;
    
    #(CLK_P);
    resetn = 1;
    
    // Concurrently generate stimulus on all 3 ports 
    fork
        genStimulus_a(); // TODO: Ports B/C
    join
    
    $display("Simulation complete!");
    $stop;
end

endmodule
