module tb;

logic clk_i;
logic rst_n_i;

logic start_cam_i;

logic [7:0] data_i;

wire sda_io;
wire scl_o;

logic vsync_i;
logic hsync_i;
logic pclk_i;
logic xclk_o;

logic [15:0] LED;

initial begin
  clk_i = 0;
  forever #5ns clk_i = ~clk_i;
end

camera_controller dut (.*);

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
