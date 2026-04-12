module missile_starter(
  input wire        rst_n,
  input wire        clk,
  output wire [9:0] m1_start_x,
  output wire [9:0] m22_start_x,
  output wire [9:0] m23_start_x,
  output wire [9:0] m33_start_x,
  output reg [3:0] m1_coefficient_x,
  output reg [3:0] m1_coefficient_y,
  output reg [3:0] m22_coefficient_x,
  output reg [3:0] m22_coefficient_y,
  output reg [3:0] m23_coefficient_x,
  output reg [3:0] m23_coefficient_y,
  output reg [3:0] m33_coefficient_x,
  output reg [3:0] m33_coefficient_y
);
  localparam LEFT_LEFT_QUARTER   = 10'd80;
  localparam LEFT_QUARTER        = 10'd160;
  localparam LEFT_RIGHT_QUARTER  = 10'd240;
  localparam RIGHT_LEFT_QUARTER  = 10'd400;
  localparam RIGHT_QUARTER       = 10'd480;
  localparam RIGHT_RIGHT_QUARTER = 10'd560;
  localparam SCREEN_WIDTH        = 10'd640;
  localparam MID_SCREEN_WIDTH    = 10'd320;

  wire [9:0] next;

  // Missile 1 always pressent
  reg [9:0] m1_x;

  // Second 2-waves-missiles missile
  reg [9:0] m22_x;

  // Second abd third 3-waves-missiles missiles
  reg [9:0] m23_x;
  reg [9:0] m33_x;

  assign m1_start_x = m1_x;
  assign m22_start_x = m22_x;
  assign m23_start_x = m23_x;
  assign m33_start_x = m33_x;

  random rnd (
    .clk(clk),
    .rst_n(rst_n),
    .result(next)
  );

  always @(posedge clk) begin
    if (!rst_n) begin
      m1_x   <= 0;
      m22_x  <= 0;
      m23_x  <= 0;
      m33_x  <= 0;
    end else begin
      if (next > SCREEN_WIDTH) begin
        m1_x <= next - SCREEN_WIDTH;
      end else begin
        m1_x <= next;

        if (next > MID_SCREEN_WIDTH) begin
          m22_x <= next - MID_SCREEN_WIDTH;
        end else begin
          m22_x <= m22_x + MID_SCREEN_WIDTH;
        end

        if (next > 10'd520) begin
          m23_x <= next - 10'd240;
          m33_x <= next - 10'd120;
        end else begin
          m23_x <= next + 10'd120;
          if (next > 10'd400) begin
            m33_x <= m33_x - 10'd240;
          end else begin
            m33_x <= m33_x + 10'd240;
          end
        end
      end
    end
  end

  always @(*) begin
      if (m1_x <= LEFT_LEFT_QUARTER) begin
        m1_coefficient_x = 2;
        m1_coefficient_y = 3;
      end

      if (m1_x > LEFT_LEFT_QUARTER && m1_x <= LEFT_QUARTER) begin
        m1_coefficient_x = 1;
        m1_coefficient_y = 2;
      end

      if (m1_x > LEFT_QUARTER && m1_x <= LEFT_RIGHT_QUARTER) begin
        m1_coefficient_x = 1;
        m1_coefficient_y = 3;
      end

      if (m1_x > LEFT_RIGHT_QUARTER && m1_x <= RIGHT_LEFT_QUARTER) begin
        m1_coefficient_x = 0;
        m1_coefficient_y = 2;
      end

      if (m1_x > RIGHT_LEFT_QUARTER && m1_x <= RIGHT_QUARTER) begin
        m1_coefficient_x = 1;
        m1_coefficient_y = 3;
      end

      if (m1_x > RIGHT_QUARTER && m1_x <= RIGHT_RIGHT_QUARTER) begin
        m1_coefficient_x = 1;
        m1_coefficient_y = 2;
      end

      if (m1_x > RIGHT_RIGHT_QUARTER && m1_x <= SCREEN_WIDTH) begin
        m1_coefficient_x = 2;
        m1_coefficient_y = 3;
      end

    // Missile 2 of 2
      if (m22_x <= LEFT_LEFT_QUARTER) begin
        m22_coefficient_x = 2;
        m22_coefficient_y = 3;
      end

      if (m22_x > LEFT_LEFT_QUARTER && m22_x <= LEFT_QUARTER) begin
        m22_coefficient_x = 1;
        m22_coefficient_y = 2;
      end

      if (m22_x > LEFT_QUARTER && m22_x <= LEFT_RIGHT_QUARTER) begin
        m22_coefficient_x = 1;
        m22_coefficient_y = 3;
      end

      if (m22_x > LEFT_RIGHT_QUARTER && m22_x <= RIGHT_LEFT_QUARTER) begin
        m22_coefficient_x = 0;
        m22_coefficient_y = 2;
      end

      if (m22_x > RIGHT_LEFT_QUARTER && m22_x <= RIGHT_QUARTER) begin
        m22_coefficient_x = 1;
        m22_coefficient_y = 3;
      end

      if (m22_x > RIGHT_QUARTER && m22_x <= RIGHT_RIGHT_QUARTER) begin
        m22_coefficient_x = 1;
        m22_coefficient_y = 2;
      end

      if (m22_x > RIGHT_RIGHT_QUARTER && m22_x <= SCREEN_WIDTH) begin
        m22_coefficient_x = 2;
        m22_coefficient_y = 3;
      end

    // Missile 2 of 3
      if (m23_x <= LEFT_LEFT_QUARTER) begin
        m23_coefficient_x = 2;
        m23_coefficient_y = 3;
      end

      if (m23_x > LEFT_LEFT_QUARTER && m23_x <= LEFT_QUARTER) begin
        m23_coefficient_x = 1;
        m23_coefficient_y = 2;
      end

      if (m23_x > LEFT_QUARTER && m23_x <= LEFT_RIGHT_QUARTER) begin
        m23_coefficient_x = 1;
        m23_coefficient_y = 3;
      end

      if (m23_x > LEFT_RIGHT_QUARTER && m23_x <= RIGHT_LEFT_QUARTER) begin
        m23_coefficient_x = 0;
        m23_coefficient_y = 2;
      end

      if (m23_x > RIGHT_LEFT_QUARTER && m23_x <= RIGHT_QUARTER) begin
        m23_coefficient_x = 1;
        m23_coefficient_y = 3;
      end

      if (m23_x > RIGHT_QUARTER && m23_x <= RIGHT_RIGHT_QUARTER) begin
        m23_coefficient_x = 1;
        m23_coefficient_y = 2;
      end

      if (m23_x > RIGHT_RIGHT_QUARTER && m23_x <= SCREEN_WIDTH) begin
        m23_coefficient_x = 2;
        m23_coefficient_y = 3;
      end

    // Missile 3 of 3
      if (m33_x <= LEFT_LEFT_QUARTER) begin
        m33_coefficient_x = 2;
        m33_coefficient_y = 3;
      end

      if (m33_x > LEFT_LEFT_QUARTER && m33_x <= LEFT_QUARTER) begin
        m33_coefficient_x = 1;
        m33_coefficient_y = 2;
      end

      if (m33_x > LEFT_QUARTER && m33_x <= LEFT_RIGHT_QUARTER) begin
        m33_coefficient_x = 1;
        m33_coefficient_y = 3;
      end

      if (m33_x > LEFT_RIGHT_QUARTER && m33_x <= RIGHT_LEFT_QUARTER) begin
        m33_coefficient_x = 0;
        m33_coefficient_y = 2;
      end

      if (m33_x > RIGHT_LEFT_QUARTER && m33_x <= RIGHT_QUARTER) begin
        m33_coefficient_x = 1;
        m33_coefficient_y = 3;
      end

      if (m33_x > RIGHT_QUARTER && m33_x <= RIGHT_RIGHT_QUARTER) begin
        m33_coefficient_x = 1;
        m33_coefficient_y = 2;
      end

      if (m33_x > RIGHT_RIGHT_QUARTER && m33_x <= SCREEN_WIDTH) begin
        m33_coefficient_x = 2;
        m33_coefficient_y = 3;
      end
  end


endmodule
