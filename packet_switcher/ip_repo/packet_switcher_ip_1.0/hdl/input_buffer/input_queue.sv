`timescale 1ns / 1ps

// Takes input from pmod and build data and meta FIFOs
// 
// This will not work if FIFO takes more than ~32 cyles to read input
// This will not work if it recives a packet shorter than min size
// Can think an invalid packet is valid if it has ip at right place

module input_queue(
   //General ports
   input wire clk,
   input wire resetn,
   
   // Ports of Axi Slave Bus Interface pmod_AXIS (input to block)
   output wire  pmod_axis_tready,
   input wire [7:0] pmod_axis_tdata,
   input wire  pmod_axis_tlast,
   input wire  pmod_axis_tvalid,
   
   // Ports of Axi Master Bus Interface buf_AXIS (output of data queue)
   output wire  buf_axis_tvalid,
   output wire [7:0] buf_axis_tdata,
   output wire  buf_axis_tlast,
   input wire  buf_axis_tready,
   
   // Ports of Axi Master Bus Interface meta_AXIS (output of meta queue)
   output wire  meta_axis_tvalid,
   output wire [31:0] meta_axis_tdata,
   input wire  meta_axis_tready
);

//Instantiate data and meta queues 
wire [31:0] dataFifoCount;
wire [31:0] metaFifoData;
wire metaFifoReady;
wire metaFifoValid;
wire dataFifoReady;

axis_data_fifo buf_axis (
  .s_axis_aresetn(resetn),
  .s_axis_aclk(clk),
  .s_axis_tvalid(pmod_axis_tvalid),
  .s_axis_tready(dataFifoReady),
  .s_axis_tdata(pmod_axis_tdata),
  .s_axis_tlast(pmod_axis_tlast),
  .m_axis_tvalid(buf_axis_tvalid),
  .m_axis_tready(buf_axis_tready),
  .m_axis_tdata(buf_axis_tdata),
  .m_axis_tlast(buf_axis_tlast),
  .axis_data_count(dataFifoCount),
  .axis_wr_data_count(),
  .axis_rd_data_count()
);

axis_meta_fifo meta_axis (
  .s_axis_aresetn(resetn),
  .s_axis_aclk(clk),
  .s_axis_tvalid(metaFifoValid),
  .s_axis_tready(metaFifoReady),
  .s_axis_tdata(metaFifoData),
  .m_axis_tvalid(meta_axis_tvalid),
  .m_axis_tready(meta_axis_tready),
  .m_axis_tdata(meta_axis_tdata),
  .axis_data_count(),
  .axis_wr_data_count(),
  .axis_rd_data_count()
);



//Constants
localparam etherTypeOffset = 13; // 12 + 1
localparam ipv4AddOffset = 19;   // 16 + 3
localparam arpAddOffset = 27;    // 24 + 3

localparam etherTypeIPv4 = 16'h0800;
localparam etherTypeARP = 16'h0806;

localparam maxPacketSize = 32'd510;

//State list
localparam 
   idle = 3'b000,
   protocol_lookup_1 = 3'b001,
   ip_address_lookup_1 = 3'b010,
   ip_address_lookup_2 = 3'b011,
   update_meta_fifo = 3'b100,
   transfer = 3'b101;

//Variables
//Address Counter
reg [4:0] counter;
reg counterWr;
reg [4:0] counterValue;

//metaData
reg [15:0] etherProtocol;
reg etherProtocolWr;
reg etherProtocolSel;
reg [31:0] desIpAdd;
reg desIpAddWr;
reg [1:0] desIpAddSel;

reg invalidProto;

//packet counter
reg [31:0] packetCount;
reg packetCountEnc;

//
wire transmission;
reg queueFull;
assign transmission = pmod_axis_tready & pmod_axis_tvalid;

//State assignment    
reg [2:0] currentState, nextState;
always @(posedge clk)
begin
   if(!resetn) 
       currentState <= idle;
   else 
       currentState <= nextState;
end

//Address Counter assignment
always @(posedge clk)
begin
   if(!resetn) 
       counter <= 5'b0;
   else if (counterWr)
       counter <= counterValue;
end

//Packet counter assignment
always @(posedge clk)
begin
   if(!resetn) 
       packetCount <= 32'b0;
   else if (packetCountEnc)
       packetCount <= packetCount + 1;
end

//Metadata assignment
always @(posedge clk)
begin
   if(!resetn) begin
       etherProtocol <= 2'b0;
       desIpAdd <= 4'b0;
   end
   else if(invalidProto) begin
          etherProtocol <= 2'b0;
          desIpAdd <= 4'b0;
   end
   else begin
       if (etherProtocolWr)
           if (etherProtocolSel == 1'b0)
               etherProtocol[7:0] <= pmod_axis_tdata;
           else if (etherProtocolSel == 1'b1)
               etherProtocol[15:8] <= pmod_axis_tdata;
       if (desIpAddWr)
           if (desIpAddSel == 2'b00)
               desIpAdd[7:0] <= pmod_axis_tdata;
           else if (desIpAddSel == 2'b01)
               desIpAdd[15:8] <= pmod_axis_tdata;
           else if (desIpAddSel == 2'b10)
               desIpAdd[23:16] <= pmod_axis_tdata;
           else if (desIpAddSel == 2'b11)
               desIpAdd[31:24] <= pmod_axis_tdata;
   end
end

//Next state and control logic
always @(*)
begin
   //default values
   nextState = currentState;
   counterWr = 1'b0;
   counterValue = counter;
   etherProtocolWr = 1'b0;
   etherProtocolSel = 1'b0;
   desIpAddWr  = 1'b0;
   desIpAddSel = 2'b00;
   packetCountEnc = 1'b0;
   queueFull = 1'b0;
   invalidProto = 1'b0;
   
   case(currentState)
   idle: begin
       queueFull = dataFifoCount > maxPacketSize;
       if (transmission) begin          //Start of new packet
           nextState = protocol_lookup_1;
           counterValue = etherTypeOffset;
           counterWr = 1'b1;
       end
   end
   protocol_lookup_1: begin                //Read and save packet protocol
       if (transmission) begin
           counterValue = counter - 1'b1;
           counterWr = 1'b1;
       end
       if (counterValue == 5'b01) begin
           etherProtocolWr  = 1'b1;
           etherProtocolSel = 1'b1;
       end
       else if (counterValue == 5'b00) begin
           nextState = ip_address_lookup_1;
           etherProtocolWr  = 1'b1;
           etherProtocolSel = 1'b0;
       end
   end
   ip_address_lookup_1: begin              //Setup counter value based on packet type
       if (transmission) begin
           nextState = ip_address_lookup_2;
           counterWr = 1'b1;
           if (etherProtocol == etherTypeIPv4)
               counterValue = ipv4AddOffset;
           else if (etherProtocol == etherTypeARP)
               counterValue = arpAddOffset;
           else begin
               invalidProto = 1'b1;
               nextState = update_meta_fifo;
               counterValue = ipv4AddOffset;
           end
       end
   end
   ip_address_lookup_2: begin              //Read and save Destination IP address
       if (transmission) begin
           counterValue = counter - 1'b1;
           counterWr = 1'b1;
       end
       if (counterValue == 5'b011) begin
           desIpAddWr  = 1'b1;
           desIpAddSel = 2'b11;
       end
       else if (counterValue == 5'b010) begin
           desIpAddWr  = 1'b1;
           desIpAddSel = 2'b10;
       end
       else if (counterValue == 5'b001) begin
           desIpAddWr  = 1'b1;
           desIpAddSel = 2'b01;
       end
       else if (counterValue == 5'b000) begin
           nextState = update_meta_fifo;
           desIpAddWr  = 1'b1;
           desIpAddSel = 2'b00;
       end
   end
   update_meta_fifo: begin                 //Write to metadata FIFO the packet address
       if (metaFifoReady)
           nextState = transfer;
   end
   transfer: begin                         //Finish writing packet to data FIFO
       if (pmod_axis_tlast) begin 
           nextState = idle;
           packetCountEnc = 1'b1; 
       end 
   end
   default:
       nextState = idle;
   endcase
end

//output logic
assign metaFifoData = desIpAdd;
assign metaFifoValid = (currentState == update_meta_fifo) ? 1'b1:1'b0;
assign pmod_axis_tready = dataFifoReady & ~queueFull;


endmodule
