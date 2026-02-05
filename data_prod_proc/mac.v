module mac(
    input clk,
    input reset_n,
    input en_weight,
    input signed [31:0] in_north,
    input [7:0]  in_west,
    input signed [7:0] in_weight,
    output reg signed [31:0] out_south,
    output reg [7:0] out_east, 
    output reg signed [7:0] out_weight
);

    reg signed [7:0] weight;

    always @(posedge clk) begin
        if (~reset_n) begin
            weight <= 8'sb0;
            out_east <= 8'b0;
            out_south <= 32'sb0;
            out_weight <= 8'sb0;
        end else begin 
            if (en_weight) begin
                weight <= in_weight;
                out_weight <= in_weight;
            end else begin
                out_east <= in_west;
                out_south <= in_north + ($signed({1'b0, in_west}) * weight); // ensures incoming pixel is treated as signed +ve by padding with a leading 0 [MSB]
            end
        end
    end

endmodule