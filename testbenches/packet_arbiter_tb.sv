`timescale 1ns / 1ps

/* Testbench for the arbitration module */

// NOTE: We assume that...
//  Port A maps to Port 1, Port B maps to Port 2, etc.
module packet_arbiter_tb #(

    // Number of packets each input port will send
    parameter N_PACKETS = 36,
    
    // Determines range of packet sizes in bytes
    parameter MIN_PACKET_LENG = 8,
    parameter MAX_PACKET_LENG = 64,
    
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

// Error Flag
bit error = 1'b0;

// Flags to signify a transaction has started
reg PMOD_a_trans, PMOD_b_trans, PMOD_c_trans;

// 3-bit counter to emulate the PMOD being ready once every 8 cycles
reg [2:0] PMOD_cycle_count; 

// Queues to hold packet markers in transit
bit [7:0] out_queue_a[$], out_queue_b[$], out_queue_c[$];

// Semaphores to allow shared usage of the testbench queues - WIP
semaphore queue_sema;

/* Helper Tasks for the Testbench */

// Generates multiple packets on a given port
task genStimulus_a();
    
    integer i;   
    $display("Generating packets on Port 1...");
    
    for (i = 0; i < N_PACKETS; i++) begin
        genPacket_a(i);
    end
endtask

task genStimulus_b();
    
    integer i;   
    $display("Generating packets on Port 2...");
    
    for (i = 0; i < N_PACKETS; i++) begin
        genPacket_b(i);
    end
endtask

task genStimulus_c();
    
    integer i;   
    $display("Generating packets on Port 3...");
    
    for (i = 0; i < N_PACKETS; i++) begin
        genPacket_c(i);
    end
endtask

// Waits between 1 and 50 clock cycles
task minorDelay();
    integer delayCycles = $urandom_range(50, 1);
    #(delayCycles * CLK_P);
endtask

// Record packets in-transit, this is a bit scuffed because it
// stores only the 'last' byte of each packet, which was
// set specifically for debugging purposes
task recordPacket(integer destinationPort, integer originatorPort, integer packetNum);
    bit [7:0] record;
    queue_sema.get(1);
    record = {originatorPort[2:0], packetNum[4:0]};
    
    // Assign to an appropriate queue
    if (destinationPort === 1) begin
        out_queue_a.push_back(record);
    end
    
    else if (destinationPort === 2) begin
        out_queue_b.push_back(record);
    end
    
    else if (destinationPort === 3) begin
        out_queue_c.push_back(record);
    end
    
    queue_sema.put(1);
endtask

// Sends a single packet on input port 1
task genPacket_a(integer packetNum);
    integer packetSize, originatorPort, destinationPort, i;
    packetSize = $urandom_range(MAX_PACKET_LENG, MIN_PACKET_LENG);
   
    // Initialize packet fields
    buf_a_axis_tvalid <= 1'b1;
    meta_a_axis_tvalid <= 1'b1;
    originatorPort = 1; // 1 for Port A
    destinationPort = ($urandom_range(1, 0) === 0) ? 2 : 3; // Route to B or C
    if ($urandom_range(9, 0) === 9) destinationPort = 666; // 10% chance to route to an invalid location
    
    meta_a_axis_tdata <= 32'hc0a80109 + destinationPort;
    recordPacket(destinationPort, originatorPort, packetNum);
    $display("(%8d) - Sending Packet on Port 1 to Port %2d - Index: %4d, Length: %4d Bytes", $time, destinationPort, packetNum[4:0], packetSize);
    
    // Send packet data byte-by-byte
    for (i = 0; i < packetSize; i++) begin  
        
        // RNG Data
        buf_a_axis_tdata <= $urandom_range(255, 0);
     
        if (i === packetSize - 1) begin
            buf_a_axis_tlast <= 1'b1; // Last packet data
            
            // For debugging, preface the LAST block in the packet data with...
            //  The port encoding (the originator) - MSB 3 bits
            //  The packet number - LSB 5 bits
            buf_a_axis_tdata <= {originatorPort[2:0], packetNum[4:0]};
        end
        
        wait(buf_a_axis_tready); // Wait until arbitrator is ready
        @(posedge clk);
        #(CLK_P);
    end
    
    // Deassert signals at the end
    buf_a_axis_tlast <= 1'b0;
    buf_a_axis_tvalid <= 1'b0;
    buf_a_axis_tdata <= 32'bX;
    meta_a_axis_tvalid <= 1'b0;
    meta_a_axis_tdata <= 32'bX;
    
    minorDelay(); // Arbitrary delay between subsequent packets
endtask

// Sends a single packet on input port 2
task genPacket_b(integer packetNum);
    integer packetSize, originatorPort, destinationPort, i;
    packetSize = $urandom_range(MAX_PACKET_LENG, MIN_PACKET_LENG);
   
    // Initialize packet fields
    buf_b_axis_tvalid <= 1'b1;
    meta_b_axis_tvalid <= 1'b1;
    originatorPort = 2; // 2 for Port B
    destinationPort = ($urandom_range(1, 0) === 0) ? 1 : 3; // Route to A or C
    if ($urandom_range(9, 0) === 9) destinationPort = 666; // 10% chance to route to an invalid location
    
    meta_b_axis_tdata <= 32'hc0a80109 + destinationPort;
    recordPacket(destinationPort, originatorPort, packetNum);
    $display("(%8d) - Sending Packet on Port 2 to Port %2d - Index: %4d, Length: %4d Bytes", $time, destinationPort, packetNum[4:0], packetSize);
    
    // Send packet data byte-by-byte
    for (i = 0; i < packetSize; i++) begin  
        
        // RNG Data
        buf_b_axis_tdata <= $urandom_range(255, 0);
     
        if (i === packetSize - 1) begin
            buf_b_axis_tlast <= 1'b1; // Last packet data
            
            // For debugging, preface the LAST block in the packet data with...
            //  The port encoding (the originator) - MSB 3 bits
            //  The packet number - LSB 5 bits
            buf_b_axis_tdata <= {originatorPort[2:0], packetNum[4:0]};
        end
        
        wait(buf_b_axis_tready); // Wait until arbitrator is ready
        @(posedge clk);
        #(CLK_P);
    end
    
    // Deassert signals at the end
    buf_b_axis_tlast <= 1'b0;
    buf_b_axis_tvalid <= 1'b0;
    buf_b_axis_tdata <= 32'bX;
    meta_b_axis_tvalid <= 1'b0;
    meta_b_axis_tdata <= 32'bX;
    
    minorDelay(); // Arbitrary delay between subsequent packets
endtask

// Sends a single packet on input port 3
task genPacket_c(integer packetNum);
    integer packetSize, originatorPort, destinationPort, i;
    packetSize = $urandom_range(MAX_PACKET_LENG, MIN_PACKET_LENG);
   
    // Initialize packet fields
    buf_c_axis_tvalid <= 1'b1;
    meta_c_axis_tvalid <= 1'b1;
    originatorPort = 3; // 3 for Port C
    destinationPort = ($urandom_range(1, 0) === 0) ? 1 : 2; // Route to A or B
    if ($urandom_range(9, 0) === 9) destinationPort = 666; // 10% chance to route to an invalid location
    
    meta_c_axis_tdata <= 32'hc0a80109 + destinationPort;
    recordPacket(destinationPort, originatorPort, packetNum);
    $display("(%8d) - Sending Packet on Port 3 to Port %2d - Index: %4d, Length: %4d Bytes", $time, destinationPort, packetNum[4:0], packetSize);
    
    // Send packet data byte-by-byte
    for (i = 0; i < packetSize; i++) begin  
        
        // RNG Data
        buf_c_axis_tdata <= $urandom_range(255, 0);
     
        if (i === packetSize - 1) begin
            buf_c_axis_tlast <= 1'b1; // Last packet data
            
            // For debugging, preface the LAST block in the packet data with...
            //  The port encoding (the originator) - MSB 3 bits
            //  The packet number - LSB 5 bits
            buf_c_axis_tdata <= {originatorPort[2:0], packetNum[4:0]};
        end
        
        wait(buf_c_axis_tready); // Wait until arbitrator is ready
        @(posedge clk);
        #(CLK_P);
    end
    
    // Deassert signals at the end
    buf_c_axis_tlast <= 1'b0;
    buf_c_axis_tvalid <= 1'b0;
    buf_c_axis_tdata <= 32'bX;
    meta_c_axis_tvalid <= 1'b0;
    meta_c_axis_tdata <= 32'bX;
    
    minorDelay(); // Arbitrary delay between subsequent packets
endtask

/* Checks the output queues, they should all by empty
by the time all the packets finish sending */
task confirmPacketsSent();
    integer i, sourcePort, packetNum, lastByte;
    
    foreach (out_queue_a[i]) begin
        lastByte = out_queue_a[i];
        packetNum = lastByte[4:0];
        sourcePort = lastByte[7:5];
        $display("ERROR: Packet sent from Port %2d to Port 1 with Index %3d NOT recieved", sourcePort, packetNum);
        error = 1;
    end
    
    foreach (out_queue_b[i]) begin
        lastByte = out_queue_b[i];
        packetNum = lastByte[4:0];
        sourcePort = lastByte[7:5];
        $display("ERROR: Packet sent from Port %2d to Port 2 with Index %3d NOT recieved", sourcePort, packetNum);
        error = 1;
    end
    
    foreach (out_queue_c[i]) begin
        lastByte = out_queue_c[i];
        packetNum = lastByte[4:0];
        sourcePort = lastByte[7:5];
        $display("ERROR: Packet sent from Port %2d to Port 3 with Index %3d NOT recieved", sourcePort, packetNum);
        error = 1;
    end
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

/* Determine if any packets finished sending to the PMOD */
always @(posedge pmod_a_axis_tlast) begin
    integer extractedLastByte, expectedLastByte, matchFound, i;
    integer sourcePort, packetNum;
    
    // Extract the last byte
    extractedLastByte = pmod_a_axis_tdata[7:0];
    sourcePort = extractedLastByte[7:5]; 
    packetNum = extractedLastByte[4:0];
    matchFound = 0;
    
    queue_sema.get(1);
    
    foreach (out_queue_a[i]) begin
        expectedLastByte = out_queue_a[i];
        
        if (expectedLastByte === extractedLastByte) begin
            $display("(%8d) - Spotted packet sent from Port %2d to Port 1 with Index %3d", $time, sourcePort, packetNum);
            out_queue_a.delete(i);
            matchFound = 1;
            break;
        end
    end
    
    queue_sema.put(1); 
    
    if (!matchFound) begin
        $display("(%8d) - ERROR: Unexpected packet sent from Port %2d to Port 1 with Index %3d recieved", $time, sourcePort, packetNum);
        error = 1;
    end
end

always @(posedge pmod_b_axis_tlast) begin
    integer extractedLastByte, expectedLastByte, matchFound, i;
    integer sourcePort, packetNum;
    
    // Extract the last byte
    extractedLastByte = pmod_b_axis_tdata[7:0];
    sourcePort = extractedLastByte[7:5]; 
    packetNum = extractedLastByte[4:0];
    matchFound = 0;
    
    queue_sema.get(1);
    
    foreach (out_queue_b[i]) begin
        expectedLastByte = out_queue_b[i];
        
        if (expectedLastByte === extractedLastByte) begin
            $display("(%8d) - Spotted packet sent from Port %2d to Port 2 with Index %3d", $time, sourcePort, packetNum);
            out_queue_b.delete(i);
            matchFound = 1;
            break;
        end
    end
    
    queue_sema.put(1); 
    
    if (!matchFound) begin
        $display("(%8d) - ERROR: Unexpected packet sent from Port %2d to Port 2 with Index %3d recieved", $time, sourcePort, packetNum);
        error = 1;
    end
end

always @(posedge pmod_c_axis_tlast) begin
    integer extractedLastByte, expectedLastByte, matchFound, i;
    integer sourcePort, packetNum;
    
    // Extract the last byte
    extractedLastByte = pmod_c_axis_tdata[7:0];
    sourcePort = extractedLastByte[7:5]; 
    packetNum = extractedLastByte[4:0];
    matchFound = 0;
    
    queue_sema.get(1);
    
    foreach (out_queue_c[i]) begin
        expectedLastByte = out_queue_c[i];
        
        if (expectedLastByte === extractedLastByte) begin
            $display("(%8d) - Spotted packet sent from Port %2d to Port 3 with Index %3d", $time, sourcePort, packetNum);
            out_queue_c.delete(i);
            matchFound = 1;
            break;
        end
    end
    
    queue_sema.put(1); 
    
    if (!matchFound) begin
        $display("(%8d) - ERROR: Unexpected packet sent from Port %2d to Port 3 with Index %3d recieved", $time, sourcePort, packetNum);
        error = 1;
    end
end



/* Determine if transactions are occuring between the PMODs */
always @(posedge clk) begin
    PMOD_a_trans <= PMOD_a_trans;
    PMOD_b_trans <= PMOD_b_trans;
    PMOD_c_trans <= PMOD_c_trans;
    
    if (~resetn) begin
        PMOD_a_trans <= 1'b0;
        PMOD_b_trans <= 1'b0;
        PMOD_c_trans <= 1'b0;
    end
    
    if (pmod_a_axis_tvalid) PMOD_a_trans <= 1'b1;
    else if (pmod_a_axis_tlast) PMOD_a_trans <= 1'b0;
    
    if (pmod_b_axis_tvalid) PMOD_b_trans <= 1'b1;
    else if (pmod_b_axis_tlast) PMOD_b_trans <= 1'b0;
    
    if (pmod_c_axis_tvalid) PMOD_c_trans <= 1'b1;
    else if (pmod_c_axis_tlast) PMOD_c_trans <= 1'b0;
end

/* Generate PMOD ready signals */
always @(posedge clk) begin
    
    pmod_a_axis_tready <= 1'b0;
    pmod_b_axis_tready <= 1'b0;
    pmod_c_axis_tready <= 1'b0;
    
    if (~resetn) PMOD_cycle_count <= 3'd0;
    else PMOD_cycle_count <= PMOD_cycle_count + 3'd1;
    
    // Trigger ready signals for the PMODs
    if (PMOD_cycle_count === 3'd2 && PMOD_a_trans) pmod_a_axis_tready <= 1'b1;
    if (PMOD_cycle_count === 3'd4 && PMOD_b_trans) pmod_b_axis_tready <= 1'b1;
    if (PMOD_cycle_count === 3'd6 && PMOD_c_trans) pmod_c_axis_tready <= 1'b1;
end


/* Main code for the testbench */
initial begin
    
    $display("Beginning simulation of the Arbiter!");
    
    // Reset
    clk = 1;
    resetn = 0;
    
    // Signal initialization
    queue_sema = new(1);
    buf_a_axis_tvalid <= 1'b0;
    buf_b_axis_tvalid <= 1'b0;
    buf_c_axis_tvalid <= 1'b0;
    meta_a_axis_tvalid <= 1'b0;
    meta_b_axis_tvalid <= 1'b0;
    meta_c_axis_tvalid <= 1'b0;
    buf_a_axis_tlast <= 1'b0;
    buf_b_axis_tlast <= 1'b0;
    buf_c_axis_tlast <= 1'b0;
    
    #(CLK_P);
    resetn = 1;
    
    // Concurrently generate stimulus on all 3 ports 
    fork
        begin
            genStimulus_a();
        end
         
        begin
            genStimulus_b();
        end
        
        begin
            genStimulus_c();
        end
    join
    
    // View recorded packets to confirm they went through
    $display("Confirming all packets sent...");
    confirmPacketsSent();
    
    if (error) $display("Simulation finished with errors...");
    else $display("Simulation complete without errors!");
    $stop;
end

endmodule
