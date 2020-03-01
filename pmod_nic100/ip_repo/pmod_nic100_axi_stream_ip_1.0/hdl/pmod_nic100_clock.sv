module pmod_nic100_clock (
    input ss,
    output reg pmod_sck,
    input clk,
    input rst
);

    reg clk_ena;
    
    always @(posedge clk) begin
        if(rst == 1'b0) begin
            clk_ena <= 1'b0;
        end
        else begin
            if(ss == 1'b0)
                clk_ena <= 1'b1;
            else
                clk_ena <= 1'b0;
        end
    end

    always @(clk) begin
        pmod_sck = ~clk & clk_ena;
    end
endmodule
