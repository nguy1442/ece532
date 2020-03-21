module ip_port_mapper (
	input [31:0] ip_address,
	
	output reg porta_sel,
	output reg portb_sel,
	output reg portc_sel,
	
	output reg invalid_ip,
	
	//Remote access ports
    input wire [31:0] port_a_IP,
    input wire [31:0] port_b_IP,
    input wire [31:0] port_c_IP
);

	// Static IPs for ports
	//localparam PORTA_IP = 32'hc0a8010a; //192.168.1.10
	//localparam PORTB_IP = 32'hc0a8010b; //192.168.1.11
	//localparam PORTC_IP = 32'hc0a8010c; //192.168.1.12

	always @(*) begin
		porta_sel = 1'b0;
		portb_sel = 1'b0;
		portc_sel = 1'b0;
		invalid_ip = 1'b0;

		case(ip_address)
			port_a_IP: begin
				porta_sel = 1'b1;
			end
			port_b_IP: begin
				portb_sel = 1'b1;
			end
			port_c_IP: begin
				portc_sel = 1'b1;
			end
			default: begin
				porta_sel = 1'b0;
				portb_sel = 1'b0;
				portc_sel = 1'b0;
				
				invalid_ip = 1'b1;
			end
		endcase
	end
endmodule