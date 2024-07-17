module tb;

logic clk_i;
logic rst_n_i;

logic start_cam_i;

logic [7:0] data_i;

wire sda_io;
wire scl_o;

logic vsync_i;
logic href_i;
logic pclk_i;
logic xclk_o;

logic        hsync_o;
logic        vsync_o;
logic [3:0]  red_o;
logic [3:0]  green_o;
logic [3:0]  blue_o;


logic [15:0] LED;

initial begin
  clk_i = 0;
  forever #5ns clk_i = ~clk_i;
end

initial begin
  pclk_i = 0;
  forever #20ns pclk_i = !pclk_i;
end

initial begin
  vsync_i = 1;
  forever begin
    #200000ns vsync_i = 1'd1;
    #20000ns vsync_i = 1'd0;
  end
end

initial begin
  href_i = 'd0;
  forever begin
    #2000ns href_i = 1'd0;
    #20ns href_i = 1'd1;
  end
end

video_top dut (.*);

initial begin
  rst_n_i <= 1;
  repeat(4) @(posedge clk_i);
  rst_n_i <= 0;
  start_cam_i <= 1'b0;
  repeat(10) @(posedge clk_i);
  rst_n_i <= 1;
  repeat(2) @(posedge clk_i);

  start_cam_i <= 1'b1;
  repeat(2) @(posedge clk_i);
  start_cam_i <= 1'b0;
  repeat(1) @(posedge clk_i);

  $stop();
end

endmodule
