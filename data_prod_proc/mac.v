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
        end
    end
endmodule