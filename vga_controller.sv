module vga_controller #(
  COLOR_WIDTH_g    = 4,
  DATA_WIDTH_g     = 16,
  H_PIXELS_g       = 640, //800,
  H_FRONT_g        = 16,//40,
  H_SYNC_g         = 96,//128,
  H_BACK_g         = 48,//88,
  V_LINES_g        = 480, //600,
  V_FRONT_g        = 11,//1,
  V_SYNC_g         = 2,//4,
  V_BACK_g         = 31//23
)(
  input  logic                     clk_i,
  input  logic                     rst_n_i,

  output logic [18:0]              fb_addr_o,
  input  logic [11:0]              fb_data_i,

  output logic                     hsync_o,
  output logic                     vsync_o,
  output logic [COLOR_WIDTH_g-1:0] red_o,
  output logic [COLOR_WIDTH_g-1:0] green_o,
  output logic [COLOR_WIDTH_g-1:0] blue_o
);

localparam H_SUM_g = H_PIXELS_g + H_FRONT_g + H_SYNC_g + H_BACK_g;
localparam V_SUM_g = V_LINES_g + V_FRONT_g + V_SYNC_g + V_BACK_g;

logic        pclk_s;
logic        pclk_reg_s;
logic        pclk_pedge_s;

logic        draw_en_s;

logic [10:0] cntRow_s;
logic [10:0] cntColumn_s;
logic        get_color_s;
logic [15:0] color_data_s;
logic        empty_s;

clk_divider #(
  .divider_g (4)
)
clk_divider_0 (
  .clk_i   (clk_i),
  .rst_n_i (rst_n_i),
  .reset_i (1'b0),
  .hold_i  (1'b0),
  .clk_o   (pclk_s)
);

always_ff @(posedge clk_i) begin
  pclk_reg_s <= pclk_s;
end
assign pclk_posedge_s = ~pclk_reg_s & pclk_s;

//counter for every collumn
always_ff @(posedge clk_i) begin
  if (!rst_n_i) 
    cntColumn_s <= 0;
  else begin
    if (pclk_posedge_s) begin
      cntColumn_s <= cntColumn_s + 1;
      if (cntColumn_s == H_SUM_g-1)
        cntColumn_s <= 0;
    end
  end
end

//counter for every row
always_ff @(posedge clk_i) begin
  if (!rst_n_i) 
    cntRow_s <= 0;
  else begin
    if (pclk_posedge_s) begin
      if (cntColumn_s == H_SUM_g-1) begin
        cntRow_s <= cntRow_s + 1;
        if (cntRow_s == V_SUM_g-1)
          cntRow_s <= 0;
      end
    end
  end
end

always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    fb_addr_o <= 'd0;
  end else begin
    if (!vsync_o) begin
      fb_addr_o <= 'd0;
    end else if (draw_en_s) begin
      if (fb_addr_o < 'd307200) begin
        fb_addr_o <= fb_addr_o + 'd1;
      end else begin
        fb_addr_o <= 'd0;
      end
    end
  end
end

always_ff @(posedge clk_i) begin
  if(!rst_n_i)
    hsync_o <= 'd1;
  else 
    hsync_o <= !(cntColumn_s >= H_PIXELS_g + H_FRONT_g-1 && cntColumn_s <H_PIXELS_g+H_FRONT_g+H_SYNC_g-1);
end

always_ff @(posedge clk_i) begin
  if(!rst_n_i)
    vsync_o <= 'd1;
  else
    vsync_o <= !(cntRow_s >= V_LINES_g + V_FRONT_g-1 && cntRow_s <V_LINES_g+V_FRONT_g+V_SYNC_g-1);
end

always_ff @(posedge clk_i) begin
  if(!rst_n_i) begin
    red_o <= 4'b0000;
    green_o <= 4'b0000;
    blue_o<= 4'b0000;
  end
  else begin
    if (draw_en_s) begin
      red_o   <= fb_data_i[11:8];
      green_o <= fb_data_i[ 7:4];
      blue_o  <= fb_data_i[ 3:0];
    end
    else begin
      red_o <= 4'b0000;
      green_o <= 4'b0000;
      blue_o<= 4'b0000;
    end
  end
end

assign draw_en_s = (cntColumn_s>=0 && cntColumn_s <H_PIXELS_g) && (cntRow_s>=0 && cntRow_s <V_LINES_g) ? pclk_posedge_s : 1'b0;

endmodule