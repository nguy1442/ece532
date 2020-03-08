module port_controller (
	input clk,
	input resetn,

	// AXI Stream signals from input buffer
	input buf_axis_tvalid,
	input [7:0] buf_axis_tdata,
	input buf_axis_tlast,
	output reg buf_axis_tready,

	// AXI Stream signals from meta data buffer
	input meta_axis_tvalid,
	input [31:0] meta_axis_tdata,
	output reg meta_axis_tready,
	
	// AXi Stream to PMOD
    input s_axis_tready,
    output reg [31:0] s_axis_tdata,
    output reg s_axis_tlast,
    output reg s_axis_tvalid,

	// Arbiter handshake signals
	// to start a transfer drive start_transfer high when ready_transfer is high
	// and wait until ready_transfer is driven low
	input start_transfer,
	output reg ready_transfer
);

	enum {
		IDLE,
		WRITING
	} pmod_port_state;

	// State machine for PMOD port
	always @(posedge clk) begin
		if(~resetn) begin
			pmod_port_state <= IDLE;

			buf_axis_tready <= 1'b0;
			s_axis_tdata <= 32'd0;
			s_axis_tlast <= 1'b0;
			s_axis_tvalid <= 1'b0;

			meta_axis_tready <= 1'b0;
			
			ready_transfer <= 1'b1;
		end
		else begin
			case(pmod_port_state)
				IDLE: begin
					meta_axis_tready <= 1'b0;
					s_axis_tvalid <= 1'b0;
					buf_axis_tready <= 1'b0;
				
					if(start_transfer) begin
						pmod_port_state <= WRITING;
						ready_transfer <= 1'b0;
					end
				end
				WRITING: begin
					// PMOD ready for more data
					if(s_axis_tready) begin
						s_axis_tvalid <= 1'b1;
						buf_axis_tready <= 1'b1;
						s_axis_tdata[7:0] <= buf_axis_tdata;
						s_axis_tlast <= buf_axis_tlast;

						if(buf_axis_tlast) begin
							pmod_port_state <= IDLE;
							
							// Consume the meta data
							meta_axis_tready <= 1'b1;
							
							ready_transfer <= 1'b1;
						end
					end
					else begin
						buf_axis_tready <= 1'b0;
					end
				end
			endcase
		end
	end
endmodule