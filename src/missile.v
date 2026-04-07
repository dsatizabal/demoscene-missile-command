module missile (
    input  wire       rst_n,
    input  wire       clk,
    input  wire       frames_clk,
    input  wire       lines_clk,
    input  wire [9:0] initial_x,
    input  wire [3:0] coefficient_x,
    input  wire [3:0] coefficient_y,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       fire,
    input  wire [1:0] R_next,
    input  wire [1:0] G_next,
    input  wire [1:0] B_next,
    output reg        active,
    output wire       in_flight,
    output reg        impact,
    output reg [1:0]  R,
    output reg [1:0]  G,
    output reg [1:0]  B
);

  localparam [15:0] FRAMES_DELAY   = 16'h00A0;
  localparam [15:0] LINE_THICKNESS = 16'd2;

  reg [9:0]  init_x;
  reg [9:0]  current_x;
  reg [9:0]  current_y;
  reg [3:0]  coeff_x;
  reg [3:0]  coeff_y;
  reg [15:0] frames_counter;
  reg        flying;
  reg        reverse_x;

  assign in_flight = flying;

  // Registered geometry / hit evaluation
  reg        x_in_range_r;
  reg        y_in_range_r;
  reg [9:0]  dx_r;
  reg [15:0] lhs_r;
  reg [15:0] rhs_r;
  reg [15:0] diff_r;
  reg        line_hit_r;
  reg        collision_hit_r;

  // Registered request from pixel/render domain to motion domain
  reg        stop_request_r;
  reg        impact_request_r;

  // Motion / missile state
  always @(posedge lines_clk) begin
    if (!rst_n) begin
      init_x           <= 10'd0;
      current_x        <= 10'd0;
      current_y        <= 10'd0;
      coeff_x          <= 4'd0;
      coeff_y          <= 4'd0;
      frames_counter   <= 16'd0;
      flying           <= 1'b0;
      reverse_x        <= 1'b0;
      impact           <= 1'b0;
    end else begin
      if (fire && !flying) begin
        init_x         <= initial_x;
        current_x      <= initial_x;
        current_y      <= 10'd0;
        coeff_x        <= coefficient_x;
        coeff_y        <= coefficient_y;
        frames_counter <= 16'd0;
        flying         <= 1'b1;
        reverse_x      <= (initial_x > 10'd320);
        impact         <= 1'b0;
      end else if (flying) begin
        // stop request from render/collision logic
        if (stop_request_r) begin
          flying <= 1'b0;
          if (impact_request_r)
            impact <= 1'b1;
        end else if (frames_counter + 16'd1 < FRAMES_DELAY) begin
          frames_counter <= frames_counter + 16'd1;
        end else begin
          frames_counter <= 16'd0;

          if (current_y + {6'b00_0000, coeff_y} < 10'd480) begin
            current_y <= current_y + {6'b00_0000, coeff_y};
          end else begin
            current_y <= 10'd479;
            flying    <= 1'b0;
          end

          if (reverse_x) begin
            if (current_x > coeff_x) begin
              current_x <= current_x - coeff_x;
            end else begin
              current_x <= 10'd0;
              flying    <= 1'b0;
            end
          end else begin
            if (current_x + {6'b00_0000, coeff_x} < 10'd640) begin
              current_x <= current_x + {6'b00_0000, coeff_x};
            end else begin
              current_x <= 10'd639;
              flying    <= 1'b0;
            end
          end
        end
      end
    end
  end

  // Sequential geometry evaluation + pixel rendering
  always @(posedge clk) begin
    if (!rst_n) begin
      active          <= 1'b0;
      R               <= 2'b00;
      G               <= 2'b00;
      B               <= 2'b00;

      x_in_range_r    <= 1'b0;
      y_in_range_r    <= 1'b0;
      dx_r            <= 10'd0;
      lhs_r           <= 16'd0;
      rhs_r           <= 16'd0;
      diff_r          <= 16'd0;
      line_hit_r      <= 1'b0;
      collision_hit_r <= 1'b0;

      stop_request_r   <= 1'b0;
      impact_request_r <= 1'b0;
    end else begin
      active          <= 1'b0;
      R               <= 2'b00;
      G               <= 2'b00;
      B               <= 2'b00;

      x_in_range_r    <= 1'b0;
      y_in_range_r    <= 1'b0;
      dx_r            <= 10'd0;
      lhs_r           <= 16'd0;
      rhs_r           <= 16'd0;
      diff_r          <= 16'd0;
      line_hit_r      <= 1'b0;
      collision_hit_r <= 1'b0;

      if (flying) begin
        if (!reverse_x)
          x_in_range_r <= (x >= init_x) && (x <= current_x);
        else
          x_in_range_r <= (x <= init_x) && (x >= current_x);

        y_in_range_r <= (y <= current_y);

        if ((!reverse_x && (x >= init_x) && (x <= current_x) && (y <= current_y)) ||
            ( reverse_x && (x <= init_x) && (x >= current_x) && (y <= current_y))) begin

          if (!reverse_x)
            dx_r <= x - init_x;
          else
            dx_r <= init_x - x;

          if (!reverse_x)
            lhs_r <= (x - init_x) * coeff_y;
          else
            lhs_r <= (init_x - x) * coeff_y;

          rhs_r <= y * coeff_x;

          if ((!reverse_x && (((x - init_x) * coeff_y) >= (y * coeff_x))) ||
              ( reverse_x && (((init_x - x) * coeff_y) >= (y * coeff_x)))) begin
            if (!reverse_x)
              diff_r <= ((x - init_x) * coeff_y) - (y * coeff_x);
            else
              diff_r <= ((init_x - x) * coeff_y) - (y * coeff_x);
          end else begin
            if (!reverse_x)
              diff_r <= (y * coeff_x) - ((x - init_x) * coeff_y);
            else
              diff_r <= (y * coeff_x) - ((init_x - x) * coeff_y);
          end

          if (
              ((!reverse_x) && (
                ((((x - init_x) * coeff_y) >= (y * coeff_x)) &&
                 ((((x - init_x) * coeff_y) - (y * coeff_x)) <= LINE_THICKNESS)) ||
                ((((x - init_x) * coeff_y) < (y * coeff_x)) &&
                 (((y * coeff_x) - ((x - init_x) * coeff_y)) <= LINE_THICKNESS))
              )) ||
              ((reverse_x) && (
                ((((init_x - x) * coeff_y) >= (y * coeff_x)) &&
                 ((((init_x - x) * coeff_y) - (y * coeff_x)) <= LINE_THICKNESS)) ||
                ((((init_x - x) * coeff_y) < (y * coeff_x)) &&
                 (((y * coeff_x) - ((init_x - x) * coeff_y)) <= LINE_THICKNESS))
              ))
             ) begin
            line_hit_r <= 1'b1;
          end
        end

        collision_hit_r <= 1'b0;

        if (line_hit_r && !collision_hit_r) begin
          if ((R_next == 2'b11) && (G_next == 2'b11) && (B_next == 2'b11) &&
              (y >= current_y - coeff_y)) begin
            stop_request_r <= 1'b1;
          end

          if ((R_next == 2'b01) && (G_next == 2'b01) && (B_next == 2'b01) &&
              (y >= current_y - coeff_y)) begin
            stop_request_r   <= 1'b1;
            impact_request_r <= 1'b1;
          end

          active <= 1'b1;
          R      <= 2'b11;
          G      <= 2'b11;
          B      <= 2'b00;
        end
      end
    end
  end

endmodule
