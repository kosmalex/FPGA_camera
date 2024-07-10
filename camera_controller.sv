module camera_controller
(
  input  logic        clk,clk_100,rst_n,
  input  logic        clk_100,
  input  logic        rst_n,

  input  logic [3:0]  key, //key[1:0] for brightness control , key[3:2] for contrast control
  
  //asyn_fifo IO
  input  logic        rd_en,
  output logic [9:0]  data_count_r,
  output logic [15:0] dout,
  
  //camera pinouts
  input  logic        cmos_pclk,
  input  logic        cmos_href,
  input  logic        cmos_vsync,
  input  logic [7:0]  cmos_db,
  inout  logic        cmos_sda,
  inout  logic        cmos_scl, //i2c comm logics
  output logic        cmos_xclk,
  
  //Debugging
  output logic [3:0]  led
);
  `include "camera_i2c_impl.svh"
   
  dcm_24MHz m1
  (// Clock in ports
  .clk(clk),      // IN
  // Clock out ports
  .cmos_xclk(cmos_xclk),     // OUT
  // Status and control signals
  .RESET(RESET),// IN
  .LOCKED(LOCKED));      // OUT
   
  asyn_fifo #(.DATA_WIDTH(16),.FIFO_DEPTH_WIDTH(10)) m2 //1024x16 FIFO mem
  (
    .rst_n(rst_n),
    .clk_write(clk_100),
    .clk_read(clk_100), //clock input from both domains
    .write(wr_en),
    .read(rd_en), 
    .data_write(pixel_q), //input FROM write clock domain
    .data_read(dout), //output TO read clock domain
    .full(full),
    .empty(), //full=sync to write domain clk , empty=sync to read domain clk
    .data_count_r(data_count_r) //asserted if fifo is equal or more than than half of its max capacity
    );
  
  debounce_explicit m3
  (
    .clk(clk_100),
    .rst_n(rst_n),
    .sw({!key[0]}),
    .db_level(),
    .db_tick(key0_tick)
    );
   
  debounce_explicit m4
  (
    .clk(clk_100),
    .rst_n(rst_n),
    .sw({!key[1]}),
    .db_level(),
    .db_tick(key1_tick)
    );
   
   debounce_explicit m5
  (
    .clk(clk_100),
    .rst_n(rst_n),
    .sw({!key[2]}),
    .db_level(),
    .db_tick(key2_tick)
    );
   
   debounce_explicit m6
  (
    .clk(clk_100),
    .rst_n(rst_n),
    .sw({!key[3]}),
    .db_level(),
    .db_tick(key3_tick)
    );
  
endmodule
