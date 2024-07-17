module video_top (
  input  logic        clk_i,
  input  logic        rst_n_i,

  input  logic        start_cam_i,

  // To camera I/O
  input  logic [7:0]  data_i,

  inout  logic        sda_io,
  output logic        scl_o,

  input  logic        vsync_i,
  input  logic        href_i,
  input  logic        pclk_i,
  output logic        xclk_o,

  // To VGA I/O
  output logic        hsync_o,
  output logic        vsync_o,
  output logic [3:0]  red_o,
  output logic [3:0]  green_o,
  output logic [3:0]  blue_o,

  // Debug
  output logic [15:0] LED
);

logic write_fb_s;

logic [18:0] vga_addr_s;
logic [18:0] cam_addr_s;

logic [15:0] cam_data_s;
logic [11:0] fb_data_s;
logic [11:0] vga_data_s;

camera_controller camera_controller_0 (
  .*,
  .fb_addr_o (cam_addr_s),
  .fb_data_o (cam_data_s),
  .fb_wr_o   (write_fb_s)
);

frame_buffer frame_buffer_0 (
  .clka (clk_i),
  .wea  (write_fb_s),
  .addra(cam_addr_s),
  .dina (fb_data_s),

  .clkb (clk_i),
  .addrb(vga_addr_s),
  .doutb(vga_data_s)
);

vga_controller vga_controller_0 (
  .*,
  .fb_addr_o(vga_addr_s),
  .fb_data_i(vga_data_s)
);

// RGB 444
always_comb begin
  fb_data_s[11:8] = cam_data_s[11: 8];
  fb_data_s[ 7:4] = cam_data_s[ 7: 4];
  fb_data_s[ 3:0] = cam_data_s[ 3: 0];
end
endmodule