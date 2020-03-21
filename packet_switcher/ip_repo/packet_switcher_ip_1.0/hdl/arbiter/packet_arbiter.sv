module packet_arbiter (
	input clk,
	input resetn,

	// AXI Stream Slave connections to all input buffers

	// AXI Stream Slave connections to input buffer a and its metadata
	input buf_a_axis_tvalid,
	input [7:0] buf_a_axis_tdata,
	input buf_a_axis_tlast,
	output reg buf_a_axis_tready,

	input meta_a_axis_tvalid,
	input [31:0] meta_a_axis_tdata, // ip address
	output reg meta_a_axis_tready,

	// AXI Stream Slave connections to input buffer c and its metadata
	input buf_b_axis_tvalid,
	input [7:0] buf_b_axis_tdata,
	input buf_b_axis_tlast,
	output reg buf_b_axis_tready,

	input meta_b_axis_tvalid,
	input [31:0] meta_b_axis_tdata,
	output reg meta_b_axis_tready,

	// AXI Stream Slave connections to input buffer c and its metadata
	input buf_c_axis_tvalid,
	input [7:0] buf_c_axis_tdata,
	input buf_c_axis_tlast,
	output reg buf_c_axis_tready,

	input meta_c_axis_tvalid,
	input [31:0] meta_c_axis_tdata,
	output reg meta_c_axis_tready,


	// AXI Stream Master connections to PMODs

	// AXI Stream Slave connections to PMOD port a
    input pmod_a_axis_tready,
    output wire [31:0] pmod_a_axis_tdata,
    output wire pmod_a_axis_tlast,
    output wire pmod_a_axis_tvalid,

	// AXI Stream Slave connections to PMOD port b
    input pmod_b_axis_tready,
    output wire [31:0] pmod_b_axis_tdata,
    output wire pmod_b_axis_tlast,
    output wire pmod_b_axis_tvalid,

	// AXI Stream Slave connections to PMOD port c
    input pmod_c_axis_tready,
    output wire [31:0] pmod_c_axis_tdata,
    output wire pmod_c_axis_tlast,
    output wire pmod_c_axis_tvalid,
    
    //Remote access ports
    input wire [31:0] port_a_IP,
    input wire [31:0] port_b_IP,
    input wire [31:0] port_c_IP,
    
    output wire [31:0] packet_droped_count_a,
    output wire [31:0] packet_droped_count_b,
    output wire [31:0] packet_droped_count_c
);

	reg [31:0] buf_a_dropped_packet_count, buf_b_dropped_packet_count, buf_c_dropped_packet_count;
	assign packet_droped_count_a = buf_a_dropped_packet_count;
	assign packet_droped_count_b = buf_b_dropped_packet_count;
	assign packet_droped_count_c = buf_c_dropped_packet_count;
	//reg [31:0] total_dropped_packet_count;
	//assign total_dropped_packet_count = buf_a_dropped_packet_count + buf_b_dropped_packet_count + buf_c_dropped_packet_count;
	
	wire buf_a_porta_sel, buf_a_portb_sel, buf_a_portc_sel;
	wire buf_b_porta_sel, buf_b_portb_sel, buf_b_portc_sel;
	wire buf_c_porta_sel, buf_c_portb_sel, buf_c_portc_sel;

	wire buf_a_invalid_ip, buf_b_invalid_ip, buf_c_invalid_ip;
	
	wire pmod_port_a_ready_a, pmod_port_a_ready_b, pmod_port_a_ready_c;
	wire [1:0] pmod_port_a_port_sel;
	reg [1:0] port_a_scheduled_buf;
	wire pmod_port_b_ready_a, pmod_port_b_ready_b, pmod_port_b_ready_c;
	wire [1:0] pmod_port_b_port_sel;
	reg [1:0] port_b_scheduled_buf;
	wire pmod_port_c_ready_a, pmod_port_c_ready_b, pmod_port_c_ready_c;
	wire [1:0] pmod_port_c_port_sel;
	reg [1:0] port_c_scheduled_buf;

	reg port_a_buf_axis_tvalid, port_a_buf_axis_tlast;
	reg [7:0] port_a_buf_axis_tdata;
	reg port_a_meta_axis_tvalid;
	wire port_a_buf_axis_tready, port_a_meta_axis_tready;
	reg buf_a_axis_tready_invalid, meta_a_axis_tready_invalid;
	reg [31:0] port_a_meta_axis_tdata;
	
	reg port_b_buf_axis_tvalid, port_b_buf_axis_tlast;
	reg [7:0] port_b_buf_axis_tdata;
	reg port_b_meta_axis_tvalid;
	wire port_b_buf_axis_tready, port_b_meta_axis_tready;
	reg buf_b_axis_tready_invalid, meta_b_axis_tready_invalid;
	reg [31:0] port_b_meta_axis_tdata;
	
	reg port_c_buf_axis_tvalid, port_c_buf_axis_tlast;
	reg [7:0] port_c_buf_axis_tdata;
	reg port_c_meta_axis_tvalid;
	wire port_c_buf_axis_tready, port_c_meta_axis_tready;
	reg buf_c_axis_tready_invalid, meta_c_axis_tready_invalid;
	reg [31:0] port_c_meta_axis_tdata;
	
	reg port_a_start_transfer, port_b_start_transfer, port_c_start_transfer;
	wire port_a_ready_transfer, port_b_ready_transfer, port_c_ready_transfer;
	
	assign pmod_port_a_ready_a = buf_a_axis_tvalid & buf_a_porta_sel; // BUG fix: prevent replay packets
	assign pmod_port_a_ready_b = buf_b_axis_tvalid & buf_b_porta_sel;
	assign pmod_port_a_ready_c = buf_c_axis_tvalid & buf_c_porta_sel;
	
	assign pmod_port_b_ready_a = buf_a_axis_tvalid & buf_a_portb_sel;
	assign pmod_port_b_ready_b = buf_b_axis_tvalid & buf_b_portb_sel; // BUG fix: prevent replay packets
	assign pmod_port_b_ready_c = buf_c_axis_tvalid & buf_c_portb_sel;
	
	assign pmod_port_c_ready_a = buf_a_axis_tvalid & buf_a_portc_sel;
	assign pmod_port_c_ready_b = buf_b_axis_tvalid & buf_b_portc_sel;
	assign pmod_port_c_ready_c = buf_c_axis_tvalid & buf_c_portc_sel; // BUG fix: prevent replay packets
	
	enum {
		WAITING_FOR_SCHEDULE,
		SCHEDULED
	} port_a_schedule_state, port_b_schedule_state, port_c_schedule_state;

	/////////////////////////////////////////////////////////////////
	// Port scheduler state machines
	/////////////////////////////////////////////////////////////////

	// port a scheduler
	always @(posedge clk) begin
		if(~resetn) begin
			port_a_schedule_state <= WAITING_FOR_SCHEDULE;
			port_a_scheduled_buf <= 2'b00;
			port_a_start_transfer <= 1'b0;
		end
		else begin
			case(port_a_schedule_state)
				WAITING_FOR_SCHEDULE: begin
					// There is a packet ready for transmission
					if((pmod_port_a_ready_b | pmod_port_a_ready_c) & port_a_ready_transfer & ~pmod_port_a_ready_a) begin // BUG fix: prevent replay packets
						port_a_start_transfer <= 1'b1;
						port_a_schedule_state <= SCHEDULED;

						// arbitrator's decision
						port_a_scheduled_buf <= pmod_port_a_port_sel;
					end
				end
				SCHEDULED: begin
					port_a_start_transfer <= 1'b0;

					// Wait until transfer form buffer is complete
					if(port_a_ready_transfer && ~port_a_start_transfer) begin
						port_a_schedule_state <= WAITING_FOR_SCHEDULE;
						port_a_scheduled_buf <= 2'b00;
					end
				end
			endcase
		end
	end
	
	// port b scheduler
	always @(posedge clk) begin
		if(~resetn) begin
			port_b_schedule_state <= WAITING_FOR_SCHEDULE;
			port_b_scheduled_buf <= 2'b00;
			port_b_start_transfer <= 1'b0;
		end
		else begin
			case(port_b_schedule_state)
				WAITING_FOR_SCHEDULE: begin
					// There is a packet ready for transmission
					if((pmod_port_b_ready_a | pmod_port_b_ready_c) & port_b_ready_transfer & ~pmod_port_b_ready_b) begin // BUG fix: prevent replay packets
						port_b_start_transfer <= 1'b1;
						port_b_schedule_state <= SCHEDULED;

						// arbitrator's decision
						port_b_scheduled_buf <= pmod_port_b_port_sel;
					end
				end
				SCHEDULED: begin
					port_b_start_transfer <= 1'b0;

					// Wait until transfer form buffer is complete
					if(port_b_ready_transfer && ~port_b_start_transfer) begin
						port_b_schedule_state <= WAITING_FOR_SCHEDULE;
						port_b_scheduled_buf <= 2'b00;
					end
				end
			endcase
		end
	end
	
	// port c scheduler
	always @(posedge clk) begin
		if(~resetn) begin
			port_c_schedule_state <= WAITING_FOR_SCHEDULE;
			port_c_scheduled_buf <= 2'b00;
			port_c_start_transfer <= 1'b0;
		end
		else begin
			case(port_c_schedule_state)
				WAITING_FOR_SCHEDULE: begin
					// There is a packet ready for transmission
					if((pmod_port_c_ready_a | pmod_port_c_ready_b) & port_c_ready_transfer & ~pmod_port_c_ready_c) begin // BUG fix: prevent replay packets
						port_c_start_transfer <= 1'b1;
						port_c_schedule_state <= SCHEDULED;

						// arbitrator's decision
						port_c_scheduled_buf <= pmod_port_c_port_sel;
					end
				end
				SCHEDULED: begin
					port_c_start_transfer <= 1'b0;

					// Wait until transfer form buffer is complete
					if(port_c_ready_transfer && ~port_c_start_transfer) begin
						port_c_schedule_state <= WAITING_FOR_SCHEDULE;
						port_c_scheduled_buf <= 2'b00;
					end
				end
			endcase
		end
	end
	
	enum {
		WAITING_FOR_INVALID_IP,
		CONSUME_INVALID_IP
	} buf_a_consume_invalid_ip_state, buf_b_consume_invalid_ip_state, buf_c_consume_invalid_ip_state;
	
	/////////////////////////////////////////////////////////////////
	// Handle comsuming invalid IPs
	/////////////////////////////////////////////////////////////////
	
	// buffer a conume invalid ip
	always @(posedge clk) begin
		if(~resetn) begin
			buf_a_dropped_packet_count <= 1'b0;
			buf_a_consume_invalid_ip_state <= WAITING_FOR_INVALID_IP;
			
			buf_a_axis_tready_invalid <= 1'b0;
			meta_a_axis_tready_invalid <= 1'b0;
		end
		else begin
			case(buf_a_consume_invalid_ip_state)
				WAITING_FOR_INVALID_IP: begin
					buf_a_axis_tready_invalid <= 1'b0;
					meta_a_axis_tready_invalid <= 1'b0;
				
					if((buf_a_invalid_ip & buf_a_axis_tvalid) | pmod_port_a_ready_a) begin // BUG fix: prevent replay packets
						buf_a_dropped_packet_count <= buf_a_dropped_packet_count + 1;
						buf_a_consume_invalid_ip_state <= CONSUME_INVALID_IP;
					end
				end
				CONSUME_INVALID_IP: begin
					buf_a_axis_tready_invalid <= 1'b1;
				
					if(buf_a_axis_tvalid & buf_a_axis_tlast) begin
						meta_a_axis_tready_invalid <= 1'b1;
						buf_a_consume_invalid_ip_state <= WAITING_FOR_INVALID_IP;
					end
				end
			endcase
		end
	end

	// buffer b conume invalid ip
	always @(posedge clk) begin
		if(~resetn) begin
			buf_b_dropped_packet_count <= 1'b0;
			buf_b_consume_invalid_ip_state <= WAITING_FOR_INVALID_IP;

			buf_b_axis_tready_invalid <= 1'b0;
			meta_b_axis_tready_invalid <= 1'b0;
		end
		else begin
			case(buf_b_consume_invalid_ip_state)
				WAITING_FOR_INVALID_IP: begin
					buf_b_axis_tready_invalid <= 1'b0;
					meta_b_axis_tready_invalid <= 1'b0;

					if((buf_b_invalid_ip & buf_b_axis_tvalid) | pmod_port_b_ready_b) begin // BUG fix: prevent replay packets
						buf_b_dropped_packet_count <= buf_b_dropped_packet_count + 1;
						buf_b_consume_invalid_ip_state <= CONSUME_INVALID_IP;
					end
				end
				CONSUME_INVALID_IP: begin
					buf_b_axis_tready_invalid <= 1'b1;
				
					if(buf_b_axis_tvalid & buf_b_axis_tlast) begin
						meta_b_axis_tready_invalid <= 1'b1;
						buf_b_consume_invalid_ip_state <= WAITING_FOR_INVALID_IP;
					end
				end
			endcase
		end
	end
	
	// buffer c conume invalid ip
	always @(posedge clk) begin
		if(~resetn) begin
			buf_c_dropped_packet_count <= 1'b0;
			buf_c_consume_invalid_ip_state <= WAITING_FOR_INVALID_IP;
			
			buf_c_axis_tready_invalid <= 1'b0;
			meta_c_axis_tready_invalid <= 1'b0;
		end
		else begin
			case(buf_c_consume_invalid_ip_state)
				WAITING_FOR_INVALID_IP: begin
					buf_c_axis_tready_invalid <= 1'b0;
					meta_c_axis_tready_invalid <= 1'b0;

					if((buf_c_invalid_ip & buf_c_axis_tvalid) | pmod_port_c_ready_c) begin // BUG fix: prevent replay packets
						buf_c_dropped_packet_count <= buf_c_dropped_packet_count + 1;
						buf_c_consume_invalid_ip_state <= CONSUME_INVALID_IP;
					end
				end
				CONSUME_INVALID_IP: begin
					buf_c_axis_tready_invalid <= 1'b1;
				
					if(buf_c_axis_tvalid & buf_c_axis_tlast) begin
						meta_c_axis_tready_invalid <= 1'b1;
						buf_c_consume_invalid_ip_state <= WAITING_FOR_INVALID_IP;
					end
				end
			endcase
		end
	end

	/////////////////////////////////////////////////////////////////	
	// Buffer input muxes
	/////////////////////////////////////////////////////////////////
	
	// port a buffer mux
	always @(*) begin
		case(port_a_scheduled_buf)
			2'b01: begin
				port_a_buf_axis_tvalid = buf_a_axis_tvalid;
				port_a_buf_axis_tlast = buf_a_axis_tlast;
				port_a_buf_axis_tdata = buf_a_axis_tdata;
				
				port_a_meta_axis_tvalid = meta_a_axis_tvalid;
				port_a_meta_axis_tdata =  meta_a_axis_tdata;
			end
			2'b10: begin
				port_a_buf_axis_tvalid = buf_b_axis_tvalid;
				port_a_buf_axis_tlast = buf_b_axis_tlast;
				port_a_buf_axis_tdata = buf_b_axis_tdata;
				
				port_a_meta_axis_tvalid = meta_b_axis_tvalid;
				port_a_meta_axis_tdata =  meta_b_axis_tdata;
			end
			2'b11: begin
				port_a_buf_axis_tvalid = buf_c_axis_tvalid;
				port_a_buf_axis_tlast = buf_c_axis_tlast;
				port_a_buf_axis_tdata = buf_c_axis_tdata;
				
				port_a_meta_axis_tvalid = meta_c_axis_tvalid;
				port_a_meta_axis_tdata =  meta_c_axis_tdata;
			end
			default: begin
				port_a_buf_axis_tvalid = 1'b0;
				port_a_buf_axis_tlast = 1'b0;
				port_a_buf_axis_tdata = 8'd0;
				
				port_a_meta_axis_tvalid = 1'b0;
				port_a_meta_axis_tdata =  32'd0;
			end
		endcase
	end

	// port b buffer mux
	always @(*) begin
		case(port_b_scheduled_buf)
			2'b01: begin
				port_b_buf_axis_tvalid = buf_a_axis_tvalid;
				port_b_buf_axis_tlast = buf_a_axis_tlast;
				port_b_buf_axis_tdata = buf_a_axis_tdata;
				
				port_b_meta_axis_tvalid = meta_a_axis_tvalid;
				port_b_meta_axis_tdata =  meta_a_axis_tdata;
			end
			2'b10: begin
				port_b_buf_axis_tvalid = buf_b_axis_tvalid;
				port_b_buf_axis_tlast = buf_b_axis_tlast;
				port_b_buf_axis_tdata = buf_b_axis_tdata;
				
				port_b_meta_axis_tvalid = meta_b_axis_tvalid;
				port_b_meta_axis_tdata =  meta_b_axis_tdata;
			end
			2'b11: begin
				port_b_buf_axis_tvalid = buf_c_axis_tvalid;
				port_b_buf_axis_tlast = buf_c_axis_tlast;
				port_b_buf_axis_tdata = buf_c_axis_tdata;
				
				port_b_meta_axis_tvalid = meta_c_axis_tvalid;
				port_b_meta_axis_tdata =  meta_c_axis_tdata;
			end
			default: begin
				port_b_buf_axis_tvalid = 1'b0;
				port_b_buf_axis_tlast = 1'b0;
				port_b_buf_axis_tdata = 8'd0;
				
				port_b_meta_axis_tvalid = 1'b0;
				port_b_meta_axis_tdata =  32'd0;
			end
		endcase
	end
	
	// port c buffer mux
	always @(*) begin
		case(port_c_scheduled_buf)
			2'b01: begin
				port_c_buf_axis_tvalid = buf_a_axis_tvalid;
				port_c_buf_axis_tlast = buf_a_axis_tlast;
				port_c_buf_axis_tdata = buf_a_axis_tdata;
				
				port_c_meta_axis_tvalid = meta_a_axis_tvalid;
				port_c_meta_axis_tdata =  meta_a_axis_tdata;
			end
			2'b10: begin
				port_c_buf_axis_tvalid = buf_b_axis_tvalid;
				port_c_buf_axis_tlast = buf_b_axis_tlast;
				port_c_buf_axis_tdata = buf_b_axis_tdata;
				
				port_c_meta_axis_tvalid = meta_b_axis_tvalid;
				port_c_meta_axis_tdata =  meta_b_axis_tdata;
			end
			2'b11: begin
				port_c_buf_axis_tvalid = buf_c_axis_tvalid;
				port_c_buf_axis_tlast = buf_c_axis_tlast;
				port_c_buf_axis_tdata = buf_c_axis_tdata;
				
				port_c_meta_axis_tvalid = meta_c_axis_tvalid;
				port_c_meta_axis_tdata =  meta_c_axis_tdata;
			end
			default: begin
				port_c_buf_axis_tvalid = 1'b0;
				port_c_buf_axis_tlast = 1'b0;
				port_c_buf_axis_tdata = 8'd0;
				
				port_c_meta_axis_tvalid = 1'b0;
				port_c_meta_axis_tdata =  32'd0;
			end
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	// Buffer output muxes
	/////////////////////////////////////////////////////////////////
	
	// buf a port mux
	always @(*) begin
		if(buf_a_invalid_ip | buf_a_porta_sel) begin // BUG fix: prevent replay packets
			buf_a_axis_tready = buf_a_axis_tready_invalid;
			meta_a_axis_tready = meta_a_axis_tready_invalid;
		end
		else begin
			buf_a_axis_tready = 1'b0;
			meta_a_axis_tready = 1'b0;
		
			if(port_a_scheduled_buf == 2'b01) begin
				buf_a_axis_tready = port_a_buf_axis_tready;
				meta_a_axis_tready = port_a_meta_axis_tready;
			end
			else if(port_b_scheduled_buf == 2'b01) begin
				buf_a_axis_tready = port_b_buf_axis_tready;
				meta_a_axis_tready = port_b_meta_axis_tready;
			end
			else if(port_c_scheduled_buf == 2'b01) begin
				buf_a_axis_tready = port_c_buf_axis_tready;
				meta_a_axis_tready = port_c_meta_axis_tready;
			end
		end
	end
	
	// buf b port mux
	always @(*) begin
		if(buf_b_invalid_ip | buf_b_portb_sel) begin // BUG fix: prevent replay packets
			buf_b_axis_tready = buf_b_axis_tready_invalid;
			meta_b_axis_tready = meta_b_axis_tready_invalid;
		end
		else begin
			buf_b_axis_tready = 1'b0;
			meta_b_axis_tready = 1'b0;
		
			if(port_a_scheduled_buf == 2'b10) begin
				buf_b_axis_tready = port_a_buf_axis_tready;
				meta_b_axis_tready = port_a_meta_axis_tready;
			end
			else if(port_b_scheduled_buf == 2'b10) begin
				buf_b_axis_tready = port_b_buf_axis_tready;
				meta_b_axis_tready = port_b_meta_axis_tready;
			end
			else if(port_c_scheduled_buf == 2'b10) begin
				buf_b_axis_tready = port_c_buf_axis_tready;
				meta_b_axis_tready = port_c_meta_axis_tready;
			end
		end
	end
	
	// buf c port mux
	always @(*) begin
		if(buf_c_invalid_ip | buf_c_portc_sel) begin // BUG fix: prevent replay packets
			buf_c_axis_tready = buf_c_axis_tready_invalid;
			meta_c_axis_tready = meta_c_axis_tready_invalid;
		end
		else begin
			buf_c_axis_tready = 1'b0;
			meta_c_axis_tready = 1'b0;
		
			if(port_a_scheduled_buf == 2'b11) begin
				buf_c_axis_tready = port_a_buf_axis_tready;
				meta_c_axis_tready = port_a_meta_axis_tready;
			end
			else if(port_b_scheduled_buf == 2'b11) begin
				buf_c_axis_tready = port_b_buf_axis_tready;
				meta_c_axis_tready = port_b_meta_axis_tready;
			end
			else if(port_c_scheduled_buf == 2'b11) begin
				buf_c_axis_tready = port_c_buf_axis_tready;
				meta_c_axis_tready = port_c_meta_axis_tready;
			end
		end
	end
	
	/////////////////////////////////////////////////////////////////
	// IP to port mapping instances
	/////////////////////////////////////////////////////////////////

	// Given a ip address, outputs a onehot encoding of which port to use.
	// If the ip address is unknown invalid_ip is high
	ip_port_mapper buff_a_ip (
		.ip_address(meta_a_axis_tdata),
	
		.porta_sel(buf_a_porta_sel),
		.portb_sel(buf_a_portb_sel),
		.portc_sel(buf_a_portc_sel),
		
		.invalid_ip(buf_a_invalid_ip),
		
		.port_a_IP(port_a_IP),
        .port_b_IP(port_b_IP),
        .port_c_IP(port_c_IP)
	);

	ip_port_mapper buff_b_ip (
		.ip_address(meta_b_axis_tdata),
	
		.porta_sel(buf_b_porta_sel),
		.portb_sel(buf_b_portb_sel),
		.portc_sel(buf_b_portc_sel),
		
		.invalid_ip(buf_b_invalid_ip),
		
		.port_a_IP(port_a_IP),
        .port_b_IP(port_b_IP),
        .port_c_IP(port_c_IP)
	);

	ip_port_mapper buff_c_ip (
		.ip_address(meta_c_axis_tdata),
	
		.porta_sel(buf_c_porta_sel),
		.portb_sel(buf_c_portb_sel),
		.portc_sel(buf_c_portc_sel),
		
		.invalid_ip(buf_c_invalid_ip),
		
		.port_a_IP(port_a_IP),
        .port_b_IP(port_b_IP),
        .port_c_IP(port_c_IP)
	);

	/////////////////////////////////////////////////////////////////
	// Controllers for each PMOD port
	/////////////////////////////////////////////////////////////////
	
	// Controller for PMOD port a
	port_controller port_a_controller (
		.clk(clk),
		.resetn(resetn),

		// AXI Stream signals from input buffer
		.buf_axis_tvalid(port_a_buf_axis_tvalid),
		.buf_axis_tdata(port_a_buf_axis_tdata),
		.buf_axis_tlast(port_a_buf_axis_tlast),
		.buf_axis_tready(port_a_buf_axis_tready),

		// AXI Stream signals from meta data buffer
		.meta_axis_tvalid(port_a_meta_axis_tvalid),
		.meta_axis_tdata(port_a_meta_axis_tdata),
		.meta_axis_tready(port_a_meta_axis_tready),
		
		// AXI Stream to PMOD
		.s_axis_tready(pmod_a_axis_tready),
		.s_axis_tdata(pmod_a_axis_tdata),
		.s_axis_tlast(pmod_a_axis_tlast),
		.s_axis_tvalid(pmod_a_axis_tvalid),

		// Arbiter handshake signals
		.start_transfer(port_a_start_transfer),
		.ready_transfer(port_a_ready_transfer)
	);

	// Controller for PMOD port b
	port_controller port_b_controller (
		.clk(clk),
		.resetn(resetn),

		// AXI Stream signals from input buffer
		.buf_axis_tvalid(port_b_buf_axis_tvalid),
		.buf_axis_tdata(port_b_buf_axis_tdata),
		.buf_axis_tlast(port_b_buf_axis_tlast),
		.buf_axis_tready(port_b_buf_axis_tready),

		// AXI Stream signals from meta data buffer
		.meta_axis_tvalid(port_b_meta_axis_tvalid),
		.meta_axis_tdata(port_b_meta_axis_tdata),
		.meta_axis_tready(port_b_meta_axis_tready),
		
		// AXI Stream to PMOD
		.s_axis_tready(pmod_b_axis_tready),
		.s_axis_tdata(pmod_b_axis_tdata),
		.s_axis_tlast(pmod_b_axis_tlast),
		.s_axis_tvalid(pmod_b_axis_tvalid),

		// Arbiter handshake signals
		.start_transfer(port_b_start_transfer),
		.ready_transfer(port_b_ready_transfer)
	);
	
	// Controller for PMOD port c
	port_controller port_c_controller (
		.clk(clk),
		.resetn(resetn),

		// AXI Stream signals from input buffer
		.buf_axis_tvalid(port_c_buf_axis_tvalid),
		.buf_axis_tdata(port_c_buf_axis_tdata),
		.buf_axis_tlast(port_c_buf_axis_tlast),
		.buf_axis_tready(port_c_buf_axis_tready),

		// AXI Stream signals from meta data buffer
		.meta_axis_tvalid(port_c_meta_axis_tvalid),
		.meta_axis_tdata(port_c_meta_axis_tdata),
		.meta_axis_tready(port_c_meta_axis_tready),
		
		// AXI Stream to PMOD
		.s_axis_tready(pmod_c_axis_tready),
		.s_axis_tdata(pmod_c_axis_tdata),
		.s_axis_tlast(pmod_c_axis_tlast),
		.s_axis_tvalid(pmod_c_axis_tvalid),

		// Arbiter handshake signals
		.start_transfer(port_c_start_transfer),
		.ready_transfer(port_c_ready_transfer)
	);

	/////////////////////////////////////////////////////////////////
	// Round Robin Arbiters for each PMOD port
	/////////////////////////////////////////////////////////////////
	
	// Round Robin Arbiter for PMOD port a
	arbiter_scheduler pmod_port_a_arbiter (
		.clk(clk),
		.resetn(resetn),

		.ready_a(pmod_port_a_ready_a),
		.ready_b(pmod_port_a_ready_b),
		.ready_c(pmod_port_a_ready_c),
		.port_sel(pmod_port_a_port_sel)
	);

	// Round Robin Arbiter for PMOD port b
	arbiter_scheduler pmod_port_b_arbiter (
		.clk(clk),
		.resetn(resetn),

		.ready_a(pmod_port_b_ready_a),
		.ready_b(pmod_port_b_ready_b),
		.ready_c(pmod_port_b_ready_c),
		.port_sel(pmod_port_b_port_sel)
	);

	// Round Robin Arbiter for PMOD port c
	arbiter_scheduler pmod_port_c_arbiter (
		.clk(clk),
		.resetn(resetn),

		.ready_a(pmod_port_c_ready_a),
		.ready_b(pmod_port_c_ready_b),
		.ready_c(pmod_port_c_ready_c),
		.port_sel(pmod_port_c_port_sel)
	);
endmodule
