module random (
    input  wire         clk,
    input  wire         rst_n,
    output reg [9:0]    result
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 10'h3FF;
        end else begin
            result <= {result[8:0], result[9] ^ result[6]};
        end
    end

endmodule
