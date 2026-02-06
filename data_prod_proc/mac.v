module mac(
    input wire clk,
    input wire reset_n,
    input wire signed [7:0] in_weight, 
    input wire [7:0] in_west,  
    input wire signed [31:0] in_north, 
    
    output reg [7:0] out_east,  
    output reg signed [31:0] out_south  
);

    always @(posedge clk) begin
        if (!reset_n) begin
            out_east <= 0;
            out_south <= 0;
        end else begin
            out_east <= in_west;
            out_south <= in_north + ($signed({1'b0, in_west}) * in_weight);

        if (in_west == 8'd10 && in_weight == 8'd4) begin
                $display("MAC SPY: In=10, W=4, North=%d, Result=%d (Expected 40)", 
                         in_north, ($signed({1'b0, in_west}) * in_weight));
            end
        end
    end
endmodule