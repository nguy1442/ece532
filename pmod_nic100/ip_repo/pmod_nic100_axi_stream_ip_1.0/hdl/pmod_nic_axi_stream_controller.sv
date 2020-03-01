
`timescale 1 ns / 1 ps

module pmod_nic100_axi_stream_controller #
(
	parameter integer DATA_WIDTH = 32
)
(
	// AXI4Stream Slave signals
	// Ready to accept data in
	output wire  S_AXIS_TREADY,
	// Data in
	input wire [DATA_WIDTH-1 : 0] S_AXIS_TDATA,
	// Byte qualifier
	//input wire [(DATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
	// Indicates boundary of last packet
	input wire  S_AXIS_TLAST,
	// Data is in valid
	input wire  S_AXIS_TVALID,

	// AXI4Master signals
    // Ready to accept data in
    input wire  M_AXIS_TREADY,
    // Data out
    output wire [DATA_WIDTH-1 : 0] M_AXIS_TDATA,
    // Byte qualifier
    //output wire [(DATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
    // Indicates boundary of last packet
    output wire  M_AXIS_TLAST,
    // Data is out valid
    output wire  M_AXIS_TVALID,

	// AXI4Stream sink: Clock
	input wire  AXIS_ACLK,
	// AXI4Stream sink: Reset
	input wire  AXIS_ARESETN,

	// SPI signals
	output reg wr_valid,
    output reg [7:0] wr_data,
    input wire wr_done,
    input wire wr_got_byte,
    input wire rd_valid,
    output reg rd_stop,
    input wire [7:0] rd_data

);

	//State machine
	enum {
        init0,  init1,  init2,  init3,  init4,  
        init5,  init6,  init7,  init8,  init9,  
        init10, init11, init12, init13, init14, 
        init15, init16, init17, init18, init19,
        init20, init21, init22, init23, init24,
        init25, init26, init27, init28, init29, 
        init30, init31, init32, init33, init34,
        init35, init36, init37, init38, init39,
        init40, init41, init42, init43, init44,
        init45, init46, init47, init48, init49,
        init48a, init48aa, init48aaa, init48aaaa,
        init50, init51, init52, init53, init54,
        init55, init56, init57, init58, init59,
        ctrl_idle,
        rx0,  rx1,  rx2,  rx3,  rx4,
        rx5,  //rx6,
        rx7,  rx8,  rx9,
        rx10, rx11, rx12, rx13, rx14,
        rx15, rx16, rx17, rx18, rx19,
        rx20, rx21, rx22, rx23, rx24,
        rx25, rx26, rx27, rx28, 
        tx0,  tx1,  tx2,  tx3,  tx4,
        tx5,  tx6,  tx7,  tx8,  tx9,  
        tx10, tx11, tx12, tx13, tx14, 
        tx15, tx16, tx17, tx18, tx19, 
        tx20
    } mst_exec_state, mst_exec_state_next;

	integer i, j;
	reg [15:0] buffer;
	reg [15:0] next_packet_ptr = 16'h3000;
	reg [15:0] rsv;
	reg [15:0] packet_size;
	reg [15:0] temp_latch;
	
	// NIC100 PMOD Instructions
	localparam WCRU      = 8'b00100010;
	localparam RCRU      = 8'b00100000;
	localparam BFSU      = 8'b00100100;
	localparam RUDADATA  = 8'b00110000;
	localparam WUDADATA  = 8'b00110010;
	localparam SETTXRTS  = 8'b11010100;
	localparam SETPKTDEC = 8'b11001100;
	localparam WRXRDPT   = 8'b01100100;
	localparam RRXDATA   = 8'b00101100;

	// Addresses
	// Refer to TABLE 3-2: ENC424J600/624J600 SFR MAP (BASE REGISTER MAP, 8-BIT PSP INTERFACE)
	localparam EUDASTL   = 8'h16;
	localparam ESTATL    = 8'h1a;
    localparam ESTATH    = 8'h1b;
    localparam ECON1L    = 8'h1e;
    localparam ECON1H    = 8'h1f;
    localparam ECON2L    = 8'h6e;
    localparam ECON2H    = 8'h6f;
    localparam ETXSTL    = 8'h00;
    localparam ETXWIREL  = 8'h14;
    localparam MACON2L   = 8'h42;
    localparam MAMXFLL   = 8'h4a;
    localparam EIEL      = 8'h72;
    localparam EIEH      = 8'h73;
    localparam EUDARDPTL = 8'h8E;
    localparam EUDAWRPTL = 8'h90;
    localparam PKTCNT    = ESTATL;
    localparam EIRL      = 8'h1c;
    localparam ERXSTL    = 8'h04;
    localparam ERXTAILL  = 8'h06;
    localparam MAADR3L   = 8'h60;
    localparam ERXFCONL  = 8'h34;

    // Masks
    localparam TXCRCEN = 8'b00010000; // MACON2L
    localparam PADCFG  = 8'b11100000; // MACON2L
    localparam CLKRDY  = 8'b00010000; // ESTATH
    localparam ETHRST  = 8'b00010000; // ECON2L
    localparam RXEN    = 8'b00000001; // ECON1L
    localparam TXMAC   = 8'b00100000; // ECON2H
    localparam TXIE    = 8'b00001000; // EIEL
    localparam TXABTIE = 8'b00000100; // EIEL
    localparam INTIE   = 8'b10000000; // EIEH
    localparam PKTDEC  = 8'b00000001; // ECON1H
    localparam PKTIF   = 8'b01000000; // EIRL

    // Default control register values
    // Note: CRC is always added and padding is added for packets less than 64 bytes
    localparam MACON2L_d = 8'hb2;

    reg [31:0] axis_tdata;
    reg axis_tvalid;
    reg axis_tlast;
    
	reg axis_tready;

	// sink has accepted all the streaming data and stored in FIFO
	reg writes_done;
	// I/O Connections assignments

	assign S_AXIS_TREADY = axis_tready;
	
	assign M_AXIS_TDATA = axis_tdata;
	assign M_AXIS_TLAST = axis_tlast;
	assign M_AXIS_TVALID = axis_tvalid;

	// Control state machine implementation
	always @(posedge AXIS_ACLK) begin
		if(!AXIS_ARESETN) begin
			mst_exec_state <= init0;
	    end
		else begin
			mst_exec_state <= mst_exec_state_next;
		end
	end

	// Next state logic
	always @(*) begin
		mst_exec_state_next = mst_exec_state;

		case(mst_exec_state)
            /*
             * 1. Write 1234h to EUDAST
             * 2. Read EUDAST to see if it now equals 1234h. If it does not, the SPI/PSP interface
             *    may not be ready yet, so return to setp 1 and try again
             */
			init0: begin
				mst_exec_state_next = init1;
			end
			init1: begin
				if(wr_got_byte)
					mst_exec_state_next = init2;
			end
			init2: begin
				if(wr_got_byte)
					mst_exec_state_next = init3;
			end
			init3: begin
				if(wr_got_byte)
					mst_exec_state_next = init4;
			end
			init4: begin
				if(wr_got_byte)
					mst_exec_state_next = init5;
			end
			init5: begin
				if(wr_done)
					mst_exec_state_next = init6;
			end
			init6: begin
				mst_exec_state_next = init7;
			end
			init7: begin
				if(wr_got_byte)
					mst_exec_state_next = init8;
			end
			init8: begin
				if(wr_got_byte)
					mst_exec_state_next = init9;
			end
			init9: begin
				if(rd_valid)
					mst_exec_state_next = init10;
			end
			init10: begin
				if(rd_valid)
					mst_exec_state_next = init11;
			end
			init11: begin
				if(buffer != 16'h3412) begin
					mst_exec_state_next = init0;
				end
				else begin
					mst_exec_state_next = init12;
				end
			end

            /*
             * 3. Poll CLKRDY (ESTAT<12>) and wait for it to become set
             */
			init12: begin
				mst_exec_state_next = init13;
			end
			init13: begin
				if(wr_got_byte)
					mst_exec_state_next = init14;
			end
			init14: begin
				if(wr_got_byte)
					mst_exec_state_next = init15;
			end
			init15: begin
				if(rd_valid)
					mst_exec_state_next = init16;
			end
			init16: begin
				if(buffer[4])
					mst_exec_state_next = init17;
				else
					mst_exec_state_next = init12;
			end

            /*
             * 4. Issue a System Reset command by setting ETHRST (ECON2<4>)
             */
			init17: begin
				mst_exec_state_next = init18;
			end
			init18: begin
				if(wr_got_byte)
					mst_exec_state_next = init19;
			end
			init19: begin
				if(wr_got_byte)
					mst_exec_state_next = init20;
			end
			init20: begin
				if(wr_got_byte)
					mst_exec_state_next = init21;
			end
			init21: begin
				if(wr_done)
					mst_exec_state_next = init22;
			end

	        /*
			 * In software, wait at least 25us for the Reset to take place and the SPI/PSP
			 * interface to begin operating again
			 */
			init22: begin
				if(i == 0)
					mst_exec_state_next = init23;
			end

            /*
             * Read EUDAST to confirm that the System Reset took place. EUDAST should have reverted
             * back to its Reset default of 0000h
             */
			init23: begin
				mst_exec_state_next = init24;
			end
			init24: begin
				if(wr_got_byte)
					mst_exec_state_next = init25;
			end
			init25: begin
				if(wr_got_byte)
					mst_exec_state_next = init26;
			end
			init26: begin
				if(rd_valid)
					mst_exec_state_next = init27;
			end
			init27: begin
				if(rd_valid)
					mst_exec_state_next = init28;
			end
			init28: begin
				if(buffer == 16'h0000)
					mst_exec_state_next = init29;
				else
					mst_exec_state_next = init23;
			end

		    /*
			 * Wait at least 256us for the PHY registers and PHY status to become available
			 */
			init29: begin
				if(i == 0)
					mst_exec_state_next = init30;
			end

            /*
             * The ENCX24J600 is now ready to accept further commands
             */

			init30: begin
				mst_exec_state_next = init31;
			end
			init31: begin
				if(wr_got_byte)
					mst_exec_state_next = init32;
			end
			init32: begin
				if(wr_got_byte)
					mst_exec_state_next = init33;
			end
			init33: begin
				if(rd_valid)
					mst_exec_state_next = init34;
			end
			init34: begin
				if(buffer == MACON2L_d)
					mst_exec_state_next = init35;
				else
					mst_exec_state_next = init30;
			end

			init35: begin
				mst_exec_state_next = init36;
			end
			init36: begin
				if(wr_got_byte)
					mst_exec_state_next = init37;
			end
			init37: begin
				if(wr_got_byte)
					mst_exec_state_next = init38;
			end
			init38: begin
				if(wr_got_byte)
					mst_exec_state_next = init39;
			end
			init39: begin
				if(wr_got_byte)
					mst_exec_state_next = init40;
			end
			init40: begin
				if(wr_done)
					mst_exec_state_next = init41;
			end

			init41: begin
				mst_exec_state_next = init42;
			end
			init42: begin
				if(wr_got_byte)
					mst_exec_state_next = init43;
			end
			init43: begin
				if(wr_got_byte)
					mst_exec_state_next = init44;
			end
			init44: begin
				if(wr_got_byte)
					mst_exec_state_next = init45;
			end
			init45: begin
				if(wr_got_byte)
					mst_exec_state_next = init46;
			end
			init46: begin
				if(wr_got_byte)
					mst_exec_state_next = init47;
			end
			init47: begin
				if(wr_got_byte)
					mst_exec_state_next = init48;
			end
			init48: begin
				if(wr_done)
					mst_exec_state_next = init48a;
			end

			init48a: begin
				mst_exec_state_next = init48aa;
			end
			init48aa: begin
				if(wr_got_byte)
					mst_exec_state_next = init48aaa;
			end
			init48aaa: begin
				if(wr_got_byte && (i == 0))
					mst_exec_state_next = init48aaaa;
			end
			init48aaaa: begin
				if(wr_done)
					mst_exec_state_next = init54;
			end

            /*
             * Set RX filters (ERXFCON) to enable Promiscuous mode
             *
             * To accept all incoming frames regardless of content (Promiscuous mode), set the
             * CRCEN, RUNTEN, UCEN, NOTMEEN and MCEN bits. Disable all other filters.
             */
			init54: begin
				mst_exec_state_next = init55;
			end
			init55: begin
				if(wr_got_byte)
					mst_exec_state_next = init56;
			end
			init56: begin
				if(wr_got_byte)
					mst_exec_state_next = init57;
			end
			init57: begin
				if(wr_got_byte)
					mst_exec_state_next = init58;
			end
			init58: begin
				if(wr_got_byte)
					mst_exec_state_next = init59;
			end
			init59: begin
				if(wr_done)
					mst_exec_state_next = init49;
			end

			init49: begin
				mst_exec_state_next = init50;
			end
			init50: begin
				if(wr_got_byte)
					mst_exec_state_next = init51;
			end
			init51: begin
				if(wr_got_byte)
					mst_exec_state_next = init52;
			end
			init52: begin
				if(wr_got_byte)
					mst_exec_state_next = init53;
			end
			init53: begin
				if(wr_done)
					mst_exec_state_next = ctrl_idle;
			end

			ctrl_idle: begin
				if(S_AXIS_TVALID) begin
					mst_exec_state_next = tx0;
				end
				else if(M_AXIS_TREADY) begin
					mst_exec_state_next = rx0;
				end
			end

			tx0: begin
				mst_exec_state_next = tx1;
			end
			tx1: begin
				if(wr_got_byte)
					mst_exec_state_next = tx2;
			end
			tx2: begin
				if(wr_got_byte)
					mst_exec_state_next = tx3;
			end
			tx3: begin
				if(wr_got_byte)
					mst_exec_state_next = tx4;
			end
			tx4: begin
				if(wr_got_byte)
					mst_exec_state_next = tx5;
			end
			tx5: begin
				if(wr_done)
					mst_exec_state_next = tx6;
			end

			tx6: begin
				mst_exec_state_next = tx7;
			end
			tx7: begin
				if(wr_got_byte && S_AXIS_TVALID && S_AXIS_TLAST)
					mst_exec_state_next = tx8;
			end
			tx8: begin
				if(wr_got_byte)
					mst_exec_state_next = tx9;
			end
			tx9: begin
				if(wr_done)
					mst_exec_state_next = tx10;
			end

			tx10: begin
				mst_exec_state_next = tx11;
			end
			tx11: begin
				if(wr_got_byte)
					mst_exec_state_next = tx12;
			end
			tx12: begin
				if(wr_got_byte)
					mst_exec_state_next = tx13;
			end
			tx13: begin
				if(wr_got_byte)
					mst_exec_state_next = tx14;
			end
			tx14: begin
				if(wr_got_byte)
					mst_exec_state_next = tx15;
			end
			tx15: begin
				if(wr_got_byte)
					mst_exec_state_next = tx16;
			end
			tx16: begin
				if(wr_got_byte)
					mst_exec_state_next = tx17;
			end
			tx17: begin
				if(wr_done)
					mst_exec_state_next = tx18;
			end

			tx18: begin
				mst_exec_state_next = tx19;
			end
			tx19: begin
				if(wr_got_byte)
					mst_exec_state_next = tx20;
			end
			tx20: begin
				if(wr_done)
					mst_exec_state_next = ctrl_idle;
			end

            // Check if there is a packet recieved
            rx0: begin
                mst_exec_state_next = rx1;
            end
            rx1: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx2;
            end
            rx2: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx3;
            end
            rx3: begin
                if(rd_valid)
                    mst_exec_state_next = rx4;
            end
            rx4: begin
                if(buffer == 16'h0000)
                    mst_exec_state_next = ctrl_idle;
                else
                    mst_exec_state_next = rx5;
            end

            // Move the read pointer
            rx5: begin
                mst_exec_state_next = rx7;
            end
            rx7: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx8;
            end
            rx8: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx9;
            end
            rx9: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx10;
            end
            rx10: begin
                if(wr_done)
                    mst_exec_state_next = rx11;
            end
            
            // Start reading the packet. First comes two bytes to be ignored
            rx11: begin
                mst_exec_state_next = rx12;
            end
            rx12: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx13;
            end
            rx13: begin
                if(rd_valid)
                    mst_exec_state_next = rx14;
            end
            rx14: begin
                if(rd_valid)
                    mst_exec_state_next = rx15;
            end
            rx15: begin
                if(rd_valid)
                    mst_exec_state_next = rx16;
            end
            rx16: begin
                if(rd_valid)
                    mst_exec_state_next = rx17;
            end
            rx17: begin
                if(rd_valid & (i == 1))
                    mst_exec_state_next = rx18;
            end
            rx18: begin
                if(rd_valid & (i[15:0] == rsv - 1 - 4))
                    mst_exec_state_next = rx19;
            end
            rx19: begin
                mst_exec_state_next = rx20;
            end
            
            // Update the tail pointer to next_packet_ptr - 2
            rx20: begin
                mst_exec_state_next = rx21;
            end
            rx21: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx22;
            end
            rx22: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx23;
            end
            rx23: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx24;
            end
            rx24: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx25;
            end
            rx25: begin
                if(wr_done)
                    mst_exec_state_next = rx26;
            end
            
            // Decrement PKTCNT
            rx26: begin
                mst_exec_state_next = rx27;
            end
            rx27: begin
                if(wr_got_byte)
                    mst_exec_state_next = rx28;
            end
            rx28: begin
                if(wr_done)
                    mst_exec_state_next = ctrl_idle;
            end
            
			default: mst_exec_state_next = mst_exec_state;
		endcase
	end

	// Data path signals
	always@(posedge AXIS_ACLK) begin
		if(!AXIS_ARESETN) begin
			wr_data <= 8'd0;
			wr_valid <= 1'b0;
			rd_stop <= 1'b1;
			i <= 0;
			j <= 0;
			buffer <= 16'd0;
			next_packet_ptr <= 16'h3000;
			rsv <= 1'b0;
			packet_size <= 16'd0;
			axis_tready <= 1'b0;
			axis_tdata <= 32'd0;
			axis_tvalid <= 1'b0;
			axis_tlast <= 1'b0;
			temp_latch <= 16'd0;
	    end
		else begin
			case(mst_exec_state)
                /*
                 * 1. Write 1234h to EUDAST
                 * 2. Read EUDAST to see if it now equals 1234h. If it does not, the SPI/PSP interface
                 *    may not be ready yet, so return to setp 1 and try again
				 */
				init0: begin
					wr_valid <= 1'b1;
					wr_data <= WCRU;
				end
				init1: begin
					if(wr_got_byte)
						wr_data <= EUDASTL;
				end
				init2: begin
					if(wr_got_byte)
						wr_data <= 8'h12;
				end
				init3: begin
					if(wr_got_byte)
						wr_data <= 8'h34;
				end
				init4: begin
					if(wr_got_byte)
						wr_valid <= 1'b0;
				end
				init6: begin
					wr_valid <= 1'b1;
					wr_data <= RCRU;
				end
				init7: begin
					if(wr_got_byte) begin
						wr_data <= EUDASTL;
					end
				end
				init8: begin
					if(wr_got_byte) begin
						wr_valid <= 1'b0;
					end
				end
				init9: begin
					rd_stop <= 1'b0;
					if(rd_valid) begin
						buffer[7:0] <= rd_data;
					end
				end
				init10: begin
					if(rd_valid) begin
						buffer[15:8] <= rd_data;
						rd_stop <= 1'b1;
					end
				end

                /*
                 * 3. Poll CLKRDY (ESTAT<12>) and wait for it to become set
                 */
				init12: begin
					wr_valid <= 1'b1;
					wr_data <= RCRU;
				end
				init13: begin
					if(wr_got_byte)
						wr_data <= ESTATH;
				end
				init14: begin
					if(wr_got_byte) begin
						wr_valid <= 1'b0;
						rd_stop <= 1'b0;
					end
				end
				init15: begin
					if(rd_valid) begin
						buffer[7:0] <= rd_data;
						rd_stop <= 1'b1;
					end
				end

                /*
                 * 4. Issue a System Reset command by setting ETHRST (ECON2<4>)
                 */
				init17: begin
					wr_valid <= 1'b1;
					wr_data <= BFSU;
				end
				init18: begin
					if(wr_got_byte)
						wr_data <= ECON2L;
				end
				init19: begin
					if(wr_got_byte)
						wr_data <= ETHRST;
				end
				init20: begin
					if(wr_got_byte)
						wr_valid <= 1'b0;
				end
				init21: begin
					if(wr_done)
						i <= 250;
				end

				/*
				 * In software, wait at least 25us for the Reset to take place and the SPI/PSP
				 * interface to begin operating again
				 */
				init22: begin
					i <= i - 1;
				end

                /*
                 * Read EUDAST to confirm that the System Reset took place. EUDAST should have reverted
                 * back to its Reset default of 0000h
                 */
				init23: begin
					wr_valid <= 1'b1;
					wr_data <= RCRU;
				end
				init24: begin
					if(wr_got_byte)
						wr_data <= EUDASTL;
				end
				init25: begin
					if(wr_got_byte)
						wr_valid <= 1'b0;
				end
				init26: begin
					rd_stop <= 1'b0;
					if(rd_valid)
						buffer[7:0] <= rd_data;
				end
				init27: begin
					if(rd_valid) begin
						buffer[15:8] <= rd_data;
						rd_stop <= 1'b1;
					end
				end
				init28: begin
					if(buffer == 16'h0000)
						i <= 2560;
				end

				/*
				 * Wait at least 256us for the PHY registers and PHY status to become available
				 */
				init29: begin
					i <= i - 1;
				end

                /*
                 * The ENCX24J600 is now ready to accept further commands
                 */

				init30: begin
					wr_valid <= 1'b1;
					wr_data <= RCRU;
				end
				init31: begin
					if(wr_got_byte)
						wr_data <= MACON2L;
				end
				init32: begin
					if(wr_got_byte) begin
						wr_valid <= 1'b0;
						rd_stop <= 1'b0;
					end
				end
				init33: begin
					if(rd_valid) begin
						buffer[7:0] <= rd_data;
						rd_stop <= 1'b1;
					end
				end

				init35: begin
					wr_valid <= 1'b1;
					wr_data <= WCRU;
				end
				init36: begin
					if(wr_got_byte)
						wr_data <= MAMXFLL;
				end
				init37: begin
					if(wr_got_byte)
						wr_data <= 8'hdc;
				end
				init38: begin
					if(wr_got_byte)
						wr_data <= 8'h05;
				end
				init39: begin
					if(wr_got_byte)
						wr_valid <= 1'b0;
				end

				init41: begin
					wr_valid <= 1'b1;
					wr_data <= WCRU;
				end
				init42: begin
					if(wr_got_byte)
						wr_data <= ERXSTL;
				end
				init43: begin
					if(wr_got_byte)
						wr_data <= next_packet_ptr[7:0]; // ERXSTL = 0x00
				end
				init44: begin
					if(wr_got_byte)
						wr_data <= next_packet_ptr[15:8]; // ERXSTH = 0x30
				end
				init45: begin
					if(wr_got_byte)
						wr_data <= 8'hfe; // ERXTAILL = 0xfe
				end
				init46: begin
					if(wr_got_byte)
						wr_data <= 8'h5f; // ERXTAILH = 0x5f
				end
				init47: begin
					if(wr_got_byte)
						wr_valid <= 1'b0;
				end

				init48a: begin
					wr_valid <= 1'b1;
					wr_data <= WCRU;
				end
				init48aa: begin
					if(wr_got_byte) begin
						wr_data <= MAADR3L;
						i <= 6;
					end
				end
				init48aaa: begin
					if(wr_got_byte) begin
						if(i == 0)
							wr_valid <= 1'b0;

						wr_data <= 8'hab;
						i <= i - 1;
					end
				end

                /*
                 * Set RX filters (ERXFCON) to enable Promiscuous mode
                 *
                 * To accept all incoming frames regardless of content (Promiscuous mode), set the
                 * CRCEN, RUNTEN, UCEN, NOTMEEN and MCEN bits. Disable all other filters.
                 *
                 * When receiving frames, ENC424J600/624J600
                 * devices accept and write the CRC field to the receive
                 * buffer. Frames with invalid CRC values can be
                 * discarded by the CRC Error Rejection filter, described
                 * in Section 10.3 "CRC Error Rejection Filter".
                 */
                init54: begin
                    wr_valid <= 1'b1;
                    wr_data <= WCRU;
                end
                init55: begin
                    if(wr_got_byte)
                       wr_data <= ERXFCONL;
                end
                init56: begin
                    if(wr_got_byte)
                        wr_data <= 8'b01011110; // ERXFCONL = 8'b01011110
                end
                init57: begin
                    if(wr_got_byte)
                        wr_data <= 8'h00; // ERXFCONH = 0
                end
                init58: begin
                    if(wr_got_byte)
                        wr_valid <= 1'b0;
                end

				// Enable packet reception
				init49: begin
					wr_valid <= 1'b1;
					wr_data <= BFSU;
				end
				init50: begin
					if(wr_got_byte)
						wr_data <= ECON1L;
				end
				init51: begin
					if(wr_got_byte)
						wr_data <= RXEN;
				end
				init52: begin
					if(wr_got_byte)
						wr_valid <= 1'b0;
				end

				// Initialize SRAM write pointers
				tx0: begin
					wr_valid <= 1'b1;
					wr_data <= WCRU;
				end
				tx1: begin
					if(wr_got_byte)
						wr_data <= EUDAWRPTL;
				end
				tx2: begin
					if(wr_got_byte)
						wr_data <= 8'h00; // EUDAWRPTL = 00
				end
				tx3: begin
					if(wr_got_byte)
						wr_data <= 8'h00; // EUDAWRPTH = 00
				end
				tx4: begin
					if(wr_got_byte)
						wr_valid <= 1'b0;
				end
				tx5: begin
					if(wr_done)
						packet_size <= 0;
				end

				// Write out packet data to NIC100 Pmod
				tx6: begin
					wr_valid <= 1'b1;
					wr_data <= WUDADATA;
				end
				tx7: begin
					if(wr_got_byte && S_AXIS_TVALID) begin
						wr_data <= S_AXIS_TDATA[7:0];
						packet_size <= packet_size + 1;
						axis_tready <= 1'b1;
					end
					else begin
						axis_tready <= 1'b0;
					end
				end
				tx8: begin
				    axis_tready <= 1'b0;
				    
					if(wr_got_byte)
						wr_valid <= 1'b0;
				end

				// Initialize transmission pointers
				tx10: begin
					wr_valid <= 1'b1;
					wr_data <= WCRU;
				end
				tx11: begin
				    if(wr_got_byte)
					   wr_data <= ETXSTL;
				end
				tx12: begin
					if(wr_got_byte)
						wr_data <= 8'h00; // ETXSTL = 0
				end
				tx13: begin
					if(wr_got_byte)
						wr_data <= 8'h00; // ETXSTH = 0
				end
				tx14: begin
					if(wr_got_byte)
						wr_data <= packet_size[7:0]; // ETXLENL
				end
				tx15: begin
					if(wr_got_byte)
						wr_data <= packet_size[15:8]; // ETXLENH
				end
				tx16: begin
					if(wr_got_byte)
						wr_valid <= 1'b0;
				end

				// Start the transmission
				tx18: begin
					wr_valid <= 1'b1;
					wr_data <= SETTXRTS;
				end
				tx19: begin
					if(wr_got_byte)
						wr_valid <= 1'b0;
				end
				
				// Check if there is a packet recieved
				rx0: begin
				    wr_valid <= 1'b1;
                    wr_data <= RCRU;
                end
                rx1: begin
                    if(wr_got_byte)
                        wr_data <= PKTCNT;
                end
                rx2: begin
                    if(wr_got_byte) begin
                        wr_valid = 1'b0;
                        rd_stop <= 1'b0;
                    end
                end
                rx3: begin
                    if(rd_valid) begin
                        buffer[7:0] <= rd_data;
                        buffer[15:8] <= 8'h00;
                        rd_stop <= 1'b1;
                    end
                end

                // Move the read pointer
                rx5: begin
                    wr_valid <= 1'b1;
                    wr_data <= WRXRDPT;
                end
                rx7: begin
                    if(wr_got_byte)
                        wr_data <= next_packet_ptr[7:0];
                end
                rx8: begin
                    if(wr_got_byte)
                        wr_data <= next_packet_ptr[15:8];
                end
                rx9: begin
                    if(wr_got_byte)
                        wr_valid = 1'b0;
                end

                // Start reading the packet. First comes two bytes to be ignored
                rx11: begin
                    wr_valid <= 1'b1;
                    wr_data <= RRXDATA;
                end
                rx12: begin
                    if(wr_got_byte) begin
                        wr_valid <= 1'b0;
                        rd_stop <= 1'b0;
                    end
                end
                rx13: begin
                    if(rd_valid)
                        next_packet_ptr[7:0] <= rd_data;
                end
                rx14: begin
                    if(rd_valid)
                        next_packet_ptr[15:8] <= rd_data;
                end
                rx15: begin // RSV is packet length
                    if(rd_valid)
                        rsv[7:0] <= rd_data;
                end
                rx16: begin
                    if(rd_valid) begin
                        rsv[15:8] <= rd_data;
                        i <= 4;
                    end
                end
                rx17: begin // Ignore next 4 bytes
                    if(rd_valid) begin
                        if(i == 1)
                            i <= 0;
                        else
                            i <= i - 1;
                    end
                end
                rx18: begin
                    if(rd_valid) begin
                        axis_tdata <= {24'd0,rd_data};
                        axis_tvalid <= 1'b1;
                        
                        if(i[15:0] == rsv - 1 - 4) begin // ignore last 4 bytes (CRC)
                            axis_tlast <= 1'b1;
                            rd_stop <= 1'b1;
                        end
                        i <= i + 1;
                    end
                    else begin
                        axis_tvalid <= 1'b0;
                        axis_tlast <= 1'b0;
                    end
                end
                rx19: begin
                    axis_tvalid <= 1'b0;
                    axis_tlast <= 1'b0;
                end
                
                // Update the tail pointer to next_packet_ptr - 2
                rx20: begin
                    wr_valid <= 1'b1;
                    wr_data <= WCRU;
                end
                rx21: begin
                    if(wr_got_byte)
                        wr_data <= ERXTAILL;
                end
                rx22: begin
                    if(wr_got_byte) begin
                        temp_latch = next_packet_ptr - 2;
                        wr_data <= temp_latch[7:0];
                    end
                end
                rx23: begin
                    if(wr_got_byte)
                        wr_data <= temp_latch[15:8];
                end
                rx24: begin
                    if(wr_got_byte)
                        wr_valid <= 1'b0;
                end
                
                // Decrement PKTCNT
                rx26: begin
                    wr_valid <= 1'b1;
                    wr_data <= SETPKTDEC;
                end
                rx27: begin
                    if(wr_got_byte)
                        wr_valid <= 1'b0;
                end
			endcase
		end
	end	
endmodule
