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

  localparam [5:0] SPRITE_WIDTH  = 6'd18;
  localparam [4:0] SPRITE_HEIGHT = 5'd24;

  localparam [2:0] PIXEL_WIDTH_SHIFT  = 3'd4;
  localparam [2:0] PIXEL_HEIGHT_SHIFT = 3'd3;

  localparam [15:0] COLOR_EFFECT_DELAY = 16'h0A00;

  reg [9:0] left_x;
  reg [9:0] top_y;
  reg [9:0] rel_x;
  reg [9:0] rel_y;
  reg [6:0] bmp_col;
  reg [4:0] bmp_row;
  reg [5:0] RGB_Color;
  reg [15:0] effect_counter;

  always @(posedge clk) begin
    if (!rst_n) begin
      active          <= 1'b0;
      R               <= 2'b00;
      G               <= 2'b00;
      B               <= 2'b00;
      RGB_Color       <= 6'b00_0001;
      effect_counter  <= 16'h0000;
    end else begin
      if (effect_counter + 1'b1 > COLOR_EFFECT_DELAY) begin
        effect_counter <= 16'h0000;
        if (RGB_Color + 1'b1 == 6'b00_0011) begin
          RGB_Color <= 6'b00_0100;
        end else begin
          RGB_Color <= RGB_Color + 1'b1;
        end
      end else begin
        effect_counter <= effect_counter + 1'b1;
      end

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
          R <= RGB_Color[5:4];
          G <= RGB_Color[3:2];
          B <= RGB_Color[1:0];
        end
      end
    end
  end

  function automatic start_banner_pixel;
    input [4:0] row;
    input [6:0] col;
    reg   [17:0] row_bitmap;
    begin
      case (row)
        5'd0:   row_bitmap = 18'b00_0000_0000_0000_0000;
        5'd1:   row_bitmap = 18'b00_0111_1111_1111_1000;
        5'd2:   row_bitmap = 18'b00_0111_1111_1111_1000;
        5'd3:   row_bitmap = 18'b11_1111_1111_1111_1111;
        5'd4:   row_bitmap = 18'b10_0111_1111_1111_1001;
        5'd5:   row_bitmap = 18'b10_0111_1111_1111_1001;
        5'd6:   row_bitmap = 18'b10_0111_1111_1111_1001;
        5'd7:   row_bitmap = 18'b10_0011_1111_1111_0001;
        5'd8:   row_bitmap = 18'b01_0011_1111_1111_0010;
        5'd9:   row_bitmap = 18'b01_0011_1111_1111_0010;
        5'd10:  row_bitmap = 18'b00_1011_1111_1111_0100;
        5'd11:  row_bitmap = 18'b00_0111_1111_1111_1000;
        5'd12:  row_bitmap = 18'b00_0011_1111_1111_0000;
        5'd13:  row_bitmap = 18'b00_0001_1111_1110_0000;
        5'd14:  row_bitmap = 18'b00_0000_1111_1100_0000;
        5'd15:  row_bitmap = 18'b00_0000_0111_1000_0000;
        5'd16:  row_bitmap = 18'b00_0000_0011_0000_0000;
        5'd17:  row_bitmap = 18'b00_0000_0011_0000_0000;
        5'd18:  row_bitmap = 18'b00_0000_0011_0000_0000;
        5'd19:  row_bitmap = 18'b00_0000_0111_1000_0000;
        5'd20:  row_bitmap = 18'b00_0000_1111_1100_0000;
        5'd21:  row_bitmap = 18'b00_0001_1111_1110_0000;
        5'd22:  row_bitmap = 18'b00_0111_1111_1111_1000;
        5'd23:  row_bitmap = 18'b00_0000_0000_0000_0000;
      endcase

      start_banner_pixel = row_bitmap[17 - col];
    end
  endfunction

endmodule