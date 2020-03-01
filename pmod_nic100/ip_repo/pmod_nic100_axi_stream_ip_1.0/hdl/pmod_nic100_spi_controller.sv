`timescale 1ns / 1ps

module pmod_nic100_spi_controller(
    input wire wr_valid,
    input wire [7:0] wr_data,
    output reg wr_done,
    output reg wr_got_byte,
    
    output reg rd_valid,
    input wire rd_stop,
    output reg [7:0] rd_data,
    
    output reg ss,
    output reg pmod_mosi,
    input wire pmod_miso,
    
    input wire clk,
    input wire rst
);

    enum {
        idle, reading, writing, delay
    } comms_state, comms_state_next;
    
    integer i;
    reg running;
    reg [7:0] tmp;
    
    // State machine
    always @(posedge clk) begin
        if(rst == 1'b0)
            comms_state <= idle;
        else
            comms_state <= comms_state_next;
    end
    
    always @(*) begin
        comms_state_next = comms_state;
        
        case(comms_state)
            idle: begin
                if(wr_valid)
                    comms_state_next = writing;
                else if(rd_stop == 1'b0)
                    comms_state_next = reading;
                else if(running)
                    comms_state_next = delay;
            end
            reading: begin
                if(rd_stop)
                    comms_state_next = idle;
            end
            writing: begin
                if(i == 0)
                    comms_state_next = idle;
            end
            delay: begin
                if(i == 0)
                    comms_state_next = idle;
            end
            default: comms_state_next = comms_state;
        endcase
    end
    
    // Data path signals
    always @(posedge clk) begin
        if(rst == 1'b0) begin
            wr_done <= 1'b0;
            wr_got_byte <= 1'b0;
            
            rd_valid <= 1'b0;
            rd_data <= 8'd0;
            
            ss <= 1'b1;
            pmod_mosi <= 1'b0;
            
            i <= 0;
            tmp <= 8'd0;
            running <= 1'b0;
        end
        else begin
            case(comms_state)
                idle: begin
                    wr_done <= 1'b0;
                    rd_valid <= 1'b0;
                    
                    if(wr_valid) begin
                        ss <= 1'b0;
                        if(running) begin
                            pmod_mosi <= wr_data[7];
                            i <= 6;
                        end
                        else
                            i <= 7;
                            
                        tmp <= wr_data;
                        wr_got_byte <= 1'b1;
                        running <= 1'b1;
                    end
                    else if(rd_stop == 1'b0) begin
                        ss <= 1'b0;
                        i <= 7;
                        running <= 1'b1;
                    end
                    else begin
                        if(running == 1'b1)
                            i <= 1;

                        running <= 1'b0;
                    end
                end
                reading: begin
                    tmp[i] = pmod_miso;
                    if(rd_stop)
                        ss <= 1'b1;
                    else if(i == 0) begin
                        rd_valid <= 1'b1;
                        rd_data <= tmp;
                        i <= 7;
                    end
                    else begin
                        i <= i - 1;
                        rd_valid <= 1'b0;
                    end
                end
                writing: begin
                    wr_got_byte <= 1'b0;
                    pmod_mosi <= tmp[i];
                    
                    if(i == 0)
                        wr_done <= 1'b1;
                    else
                        i <= i - 1;
                end
                delay: begin
                    ss <= 1'b1;
                    
                    if(i != 0)
                        i <= i - 1;
                end
            endcase
        end
    end
endmodule
