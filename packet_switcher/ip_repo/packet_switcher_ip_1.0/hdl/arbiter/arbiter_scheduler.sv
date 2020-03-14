module arbiter_scheduler (
	input clk,
	input resetn,

	input ready_a,
	input ready_b,
	input ready_c,

	output [1:0] port_sel
);

	// Port encoding
	enum reg [1:0] {
		NONE  = 2'b00,
		PORTA = 2'b01,
		PORTB = 2'b10,
		PORTC = 2'b11
	} last_sel, next_sel;

	// Store the previously used port
	always @(posedge clk) begin
		if(~resetn) begin
			last_sel <= PORTC;
		end
		else if(next_sel != NONE) begin
			last_sel <= next_sel;
		end
	end

	// Port select logic
	always @(*) begin
		next_sel = NONE;

		case(last_sel)
			PORTC: begin
				if(ready_a)
					next_sel = PORTA;
				else if(ready_b)
					next_sel = PORTB;
				else if(ready_c)
					next_sel = PORTC;
			end
			PORTA: begin
				if(ready_b)
					next_sel = PORTB;
				else if(ready_c)
					next_sel = PORTC;
				else if(ready_a)
					next_sel = PORTA;
			end
			PORTB: begin
				if(ready_c)
					next_sel = PORTC;
				else if(ready_a)
					next_sel = PORTA;
				else if(ready_b)
					next_sel = PORTB;
			end
			default: begin
				next_sel = NONE;
			end
		endcase
	end

	assign port_sel = next_sel;
endmodule