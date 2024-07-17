module camera_controller (
  input  logic                  clk_i,
  input  logic                  rst_n_i,

  output logic [18:0]           fb_addr_o,
  output logic [15:0]           fb_data_o,
  output logic                  fb_wr_o,

  // To camera I/O
  input  logic [7:0]            data_i,
  inout  logic                  sda_io,
  output logic                  scl_o,
  input  logic                  vsync_i,
  input  logic                  href_i,
  input  logic                  pclk_i,
  output logic                  xclk_o,

  // Debug
  output logic [15:0]           LED
);

localparam nbyte2send_lp = 76;

typedef enum logic[2:0] { I2C_IDLE, I2C_SEND, I2C_DONE, I2C_STALL, I2C_SLEEP } i2c_st_t;
typedef enum logic[2:0] { IDLE, VSYNC, BYTE[2], REGISTER   } cam_st_t;

i2c_st_t     i2c_st_s;

logic [6:0]  rom_addr_s;
logic [23:0] rom_data_s;

logic [23:0] i2c_data_s;
logic [1:0]  i2c_nbytes_s;
logic        i2c_send_s;
logic        i2c_done_s;
logic        i2c_ready_s;

logic        i2c_init_done_s;

logic        i2c_10ms_stall_s;
logic        i2c_10ms_done_s;

logic        db_start_cam_s;

logic        vsync_reg_s;
logic        vsync_negedge_s;
logic        vsync_high_s;

logic        href_reg_s;
logic        href_high_s;

logic        pclk_reg_s;
logic        pclk_posedge_s;

cam_st_t     st_s;

logic [15:0] buffer_short_s;
logic        push_to_fifo_s;
logic        fifo_full_s;

logic        send_color_s;
logic        can_send_color_s;

logic [47:0] counter_s;
logic        got_a_pedge_s;

blk_mem_gen_0 i2c_rom_0 (
  .clka  (clk_i),
  .addra (rom_addr_s),
  .douta (rom_data_s)
);

clk_divider #(
  .divider_g (4)
)
clk_divider_0 (
  .clk_i   (clk_i),
  .rst_n_i (rst_n_i),
  .reset_i (1'b0),
  .hold_i  (1'b0),
  .clk_o   (xclk_o)
);

i2c #(
  .divider_g   (260),
  .start_hold_g(70),
  .stop_hold_g (70),
  .free_hold_g (1300),
  .data_hold_g (2),
  .nbytes_g    (3)
) i2c_master_0 (
  .clk_i    (clk_i),
  .rst_n_i  (rst_n_i),

  .send_i   (i2c_send_s),
  .nbytes_i (i2c_nbytes_s),
  .data_i   (rom_data_s),
  .data_o   (i2c_data_s),
  .done_o   (i2c_done_s),
  .ready_o  (i2c_ready_s),

  .scl_o    (scl_o),
  .sda_io   (sda_io)
);

timer #(
  .clk_periods_g (1_000_000) // 10ms = 1_000_000 x 10ns
)
timer_0 (
  .*,
  .count_i (i2c_10ms_stall_s),
  .done_o  (i2c_10ms_done_s)
);

always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    rom_addr_s <= 'd0;
  end else begin
    if (i2c_st_s == I2C_DONE) begin
      if (
        ( (rom_addr_s > 'd0) && i2c_ready_s ) || 
        ( rom_addr_s == 'd0                 )
      ) begin
        rom_addr_s <= rom_addr_s + 'd1;
      end
    end
  end 
end

// This is edge detection logic
always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    vsync_reg_s <= 'd0;
    href_reg_s  <= 'd0;
    pclk_reg_s  <= 'd0;
  end else begin
    vsync_reg_s <= vsync_i;
    href_reg_s  <= href_i;
    pclk_reg_s  <= pclk_i;
  end
end
assign vsync_negedge_s = vsync_reg_s & !vsync_i;
assign vsync_high_s    = vsync_reg_s &  vsync_i;
assign href_high_s     =  href_reg_s &   href_i;
assign pclk_posedge_s  = !pclk_reg_s &   pclk_i;

// Collect incoming RGB short from camera
always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    buffer_short_s <= 'd0;
  end else begin
    case(st_s)
      BYTE0: begin
        if (pclk_posedge_s && href_high_s) begin
          buffer_short_s[15:8] <= data_i;
        end
      end

      BYTE1: begin
        if (pclk_posedge_s && href_high_s) begin
          buffer_short_s[7:0] <= data_i;
        end
      end

      default: begin
        buffer_short_s <= buffer_short_s;
      end
    endcase
  end
end

always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    fb_addr_o <= 'd0;
  end else begin
    if(st_s == VSYNC) begin
      fb_addr_o <= 'd0;
    end else if (st_s == REGISTER) begin
      if (fb_addr_o < 'd307200) begin
        fb_addr_o <= fb_addr_o + 'd1;
      end else begin
        fb_addr_o <= 'd0;
      end
    end
  end
end

// I2C initialization FSM
always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    i2c_st_s <= I2C_IDLE;
  end else begin
    case(i2c_st_s)
      I2C_IDLE: begin
        i2c_st_s <= I2C_SEND;
      end
      
      I2C_SEND: begin
        if (i2c_done_s) begin
          i2c_st_s <= I2C_DONE;
        end
      end
      
      I2C_DONE: begin
        if (rom_addr_s == 'd0) begin
          i2c_st_s <= I2C_STALL;
        end else if (rom_addr_s < nbyte2send_lp) begin
          i2c_st_s <= i2c_ready_s ? I2C_SEND : I2C_DONE;
        end else begin
          i2c_st_s <= I2C_SLEEP;
        end
      end

      I2C_STALL: begin
        i2c_st_s <= i2c_10ms_done_s ? I2C_SEND : I2C_STALL;
      end

      I2C_SLEEP: begin
        i2c_st_s <= i2c_st_s;
      end

      default: begin
        i2c_st_s <= I2C_IDLE;
      end
    endcase
  end
end

// I2C initialization FSM
always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    st_s <= IDLE;
  end else begin
    case(st_s)
      IDLE: begin
        if (i2c_init_done_s) begin
          st_s <= VSYNC;
        end
      end
      
      VSYNC: begin
        st_s <= vsync_negedge_s ? BYTE0 : VSYNC;
      end
      
      BYTE0: begin
        if (!vsync_high_s) begin
          st_s <= (pclk_posedge_s && href_high_s) ? BYTE1 : BYTE0;
        end else begin
          st_s <= VSYNC;
        end
      end
      
      BYTE1: begin
        if (!vsync_high_s) begin
          st_s <= (pclk_posedge_s && href_high_s) ? REGISTER : BYTE1;
        end else begin
          st_s <= VSYNC;
        end
      end

      REGISTER: begin
        st_s <= BYTE0;
      end

      default: begin
        st_s <= IDLE;
      end
    endcase
  end
end

assign i2c_send_s       = (i2c_st_s == I2C_SEND);
assign i2c_nbytes_s     = 3'd3;
assign i2c_init_done_s  = (i2c_st_s == I2C_SLEEP);
assign i2c_10ms_stall_s = (i2c_st_s == I2C_STALL);

assign fb_wr_o   = (st_s == REGISTER);
assign fb_data_o = buffer_short_s;

assign LED[0]    = (st_s == REGISTER);
assign LED[1]    = (st_s == BYTE1);
assign LED[2]    = (st_s == BYTE0);
assign LED[3]    = (st_s == VSYNC);
assign LED[4]    = (st_s == IDLE);
assign LED[15:5] = 'd0;
endmodule