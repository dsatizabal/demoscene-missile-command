module winner_banner (
    input  wire       rst_n,
    input  wire       clk,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [9:0] pos_x,
    input  wire [9:0] pos_y,
    input  wire       paint_banner,
    output reg        active,
    output reg [1:0]  R,
    output reg [1:0]  G,
    output reg [1:0]  B
);

  localparam [5:0] SPRITE_WIDTH  = 6'd13;
  localparam [4:0] SPRITE_HEIGHT = 5'd22;

  localparam [2:0] PIXEL_WIDTH_SHIFT  = 3'd4;
  localparam [2:0] PIXEL_HEIGHT_SHIFT = 3'd3;


  reg [9:0] left_x;
  reg [9:0] top_y;
  reg [9:0] rel_x;
  reg [9:0] rel_y;
  reg [6:0] bmp_col;
  reg [4:0] bmp_row;

  always @(posedge clk) begin
    if (!rst_n) begin
      active          <= 1'b0;
      R               <= 2'b00;
      G               <= 2'b00;
      B               <= 2'b00;
    end else begin
      active <= 1'b0;
      R      <= 2'b00;
      G      <= 2'b00;
      B      <= 2'b00;

      left_x = pos_x - ((SPRITE_WIDTH  << PIXEL_WIDTH_SHIFT)  >> 1);
      top_y  = pos_y - ((SPRITE_HEIGHT << PIXEL_HEIGHT_SHIFT) >> 1);

      if ((x >= left_x) && (x < (left_x + (SPRITE_WIDTH  << PIXEL_WIDTH_SHIFT))) &&
          (y >= top_y)  && (y < (top_y  + (SPRITE_HEIGHT << PIXEL_HEIGHT_SHIFT))) &&
          paint_banner) begin

        rel_x = x - left_x;
        rel_y = y - top_y;

        bmp_col = rel_x >> PIXEL_WIDTH_SHIFT;
        bmp_row = rel_y >> PIXEL_HEIGHT_SHIFT;

        if (start_banner_pixel(bmp_row, bmp_col)) begin
          active <= 1'b1;
          R <= 2'b11;
          G <= 2'b11;
          B <= 2'b00;
        end
      end
    end
  end

  function automatic start_banner_pixel;
    input [4:0] row;
    input [6:0] col;
    reg   [12:0] row_bitmap;
    begin
      case (row)
        5'd0:   row_bitmap = 13'b0_0000_0100_0000;
        5'd1:   row_bitmap = 13'b0_0000_0100_0000;
        5'd2:   row_bitmap = 13'b0_0000_1110_0000;
        5'd3:   row_bitmap = 13'b0_0111_1111_1100;
        5'd4:   row_bitmap = 13'b0_0011_1111_1000;
        5'd5:   row_bitmap = 13'b0_0001_1111_0000;
        5'd6:   row_bitmap = 13'b0_0000_1110_0000;
        5'd7:   row_bitmap = 13'b0_0000_1110_0000;
        5'd8:   row_bitmap = 13'b0_0001_1011_0000;
        5'd9:   row_bitmap = 13'b0_0010_0000_1000;
        5'd10:  row_bitmap = 13'b1_0000_0000_0001;
        5'd11:  row_bitmap = 13'b1_1000_0000_0011;
        5'd12:  row_bitmap = 13'b0_1100_0000_0110;
        5'd13:  row_bitmap = 13'b0_0110_0000_1100;
        5'd14:  row_bitmap = 13'b1_0011_0001_1001;
        5'd15:  row_bitmap = 13'b1_1001_1011_0011;
        5'd16:  row_bitmap = 13'b0_1100_1110_0110;
        5'd17:  row_bitmap = 13'b0_0110_0100_1100;
        5'd18:  row_bitmap = 13'b0_0011_0001_1000;
        5'd19:  row_bitmap = 13'b0_0001_1011_0000;
        5'd20:  row_bitmap = 13'b0_0000_1110_0000;
        5'd21:  row_bitmap = 13'b0_0000_0100_0000;
      endcase

      start_banner_pixel = row_bitmap[12 - col];
    end
  endfunction

endmodule