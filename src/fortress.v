module fortress (
    input  wire       rst_n,
    input  wire       clk,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [1:0] remaining_hits,
    input wire  [5:0] RGB_Color,
    output reg        active,
    output reg [1:0]  R,
    output reg [1:0]  G,
    output reg [1:0]  B
);
  localparam SCREEN_MID_WIDTH           = 10'd320;
  localparam SCREEN_HEIGHT              = 10'd480;
  localparam FORTRESS_BLOCK_MID_WIDTH   = 5'd24;
  localparam FORTRESS_BLOCK_MID_HEIGHT  = 5'd12;

  always @(posedge clk) begin
    if (!rst_n) begin
      active <= 1'b0;
      R      <= 2'b00;
      G      <= 2'b00;
      B      <= 2'b00;
    end else begin
      if (remaining_hits > 0) begin
        if (x >= (SCREEN_MID_WIDTH - FORTRESS_BLOCK_MID_WIDTH - (FORTRESS_BLOCK_MID_WIDTH << 1)) &&
            x <= (SCREEN_MID_WIDTH + FORTRESS_BLOCK_MID_WIDTH + (FORTRESS_BLOCK_MID_WIDTH << 1))) begin

            // Left block
            if (x >= (SCREEN_MID_WIDTH - FORTRESS_BLOCK_MID_WIDTH - (FORTRESS_BLOCK_MID_WIDTH << 1)) &&
                x < SCREEN_MID_WIDTH - FORTRESS_BLOCK_MID_WIDTH && remaining_hits == 2'b11) begin
              if (y >= SCREEN_HEIGHT - (FORTRESS_BLOCK_MID_HEIGHT << 1) && y <= SCREEN_HEIGHT) begin
                active <= 1'b1;
                R <= RGB_Color[5:4];
                G <= RGB_Color[3:2];
                B <= RGB_Color[1:0];
              end else begin
                active <= 1'b0;
              end
            end else begin
              active <= 1'b0;
            end

            // center block
            if (x >= SCREEN_MID_WIDTH - FORTRESS_BLOCK_MID_WIDTH &&
                x < SCREEN_MID_WIDTH + FORTRESS_BLOCK_MID_WIDTH && remaining_hits >= 2'b01) begin
              if (y >= SCREEN_HEIGHT - (FORTRESS_BLOCK_MID_HEIGHT << 2) && y <= SCREEN_HEIGHT) begin
                active <= 1'b1;
                R <= RGB_Color[5:4];
                G <= RGB_Color[3:2];
                B <= RGB_Color[1:0];
              end else begin
                active <= 1'b0;
              end
            end

            // right block
            if (x >= SCREEN_MID_WIDTH + FORTRESS_BLOCK_MID_WIDTH &&
                x <= (SCREEN_MID_WIDTH + FORTRESS_BLOCK_MID_WIDTH + (FORTRESS_BLOCK_MID_WIDTH << 1)) && remaining_hits >= 2'b10) begin
              if (y >= SCREEN_HEIGHT - (FORTRESS_BLOCK_MID_HEIGHT << 1) && y <= SCREEN_HEIGHT) begin
                active <= 1'b1;
                R <= RGB_Color[5:4];
                G <= RGB_Color[3:2];
                B <= RGB_Color[1:0];
              end else begin
                active <= 1'b0;
              end
            end

        end else begin
          active <= 1'b0;
        end
      end
    end
  end

endmodule
