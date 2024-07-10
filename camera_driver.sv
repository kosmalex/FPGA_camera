module camera_controller #(
  divider_g = 100_000_000
)(
  input  logic       clk_i,
  input  logic       rst_n_i,

  input  logic       start_cam_i, // This needs a debouncer which is on your laptop

  // To camera I/O
  input  logic [7:0] data_i,

  inout  logic       sda_io,
  input  logic       scl_o,

  input  logic       vsync_i,
  input  logic       hsync_i,
  input  logic       pclk_i,
  output logic       xclk_o
);

typedef enum logic[1:0] { I2C_IDLE, I2C_SEND, I2C_DONE, I2C_SLEEP } i2c_st_t;
typedef enum logic[1:0] { IDLE, VSYNC, BYTE[2], REGISTER} cam_st_t;

i2c_st_t     i2c_st_s;

logic [7:0]  rom_addr_s;
logic [23:0] rom_data_s;

logic [23:0] i2c_data_s;
logic [1:0]  i2c_nbytes_s;
logic        i2c_send_s;
logic        i2c_done_s;
logic        i2c_ready_s;

logic        i2c_init_done_s;

logic        pedge_start_cam_s;

cam_st_t     st_s;

blk_mem_gen_0 i2c_rom_0 (
  .clka  (clk_i),
  .addra (rom_addr_s),
  .douta (rom_data_s)
);

i2c_0 i2c_master_0 (
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

clk_wiz_0 xclk_gen_0
(
  .clk_i     (clk_i),
  .cam_clk_o (xclk_o)
);

always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    rom_addr_s <= 'd0;
  end else begin
    if ((i2c_st_s == I2C_DONE) && i2c_ready_s) begin
      rom_addr_s <= rom_addr_s + 'd1;
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
        if (pedge_start_cam_s) begin
          i2c_st_s <= I2C_SEND;
        end
      end
      
      I2C_SEND: begin
        if (i2c_done_s) begin
          i2c_st_s <= I2C_DONE;
        end
      end
      
      I2C_DONE: begin
        if(rom_addr_s < 'd77)  begin
          i2c_st_s <= i2c_ready_s ? I2C_SEND : I2C_DONE;
        end else begin
          i2c_st_s <= I2C_SLEEP;
        end
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
        st_s <= BYTE0;
      end
      
      BYTE0: begin
        st_s <= BYTE1;
      end
      
      BYTE1: begin
        st_s <= REGISTER;
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

assign i2c_send_s        = (st_s == I2C_SEND);
assign i2c_nbytes_s      = 3'd3;

assign pedge_start_cam_s = start_cam_i; // Make pedge detector

assign i2c_init_done_s   = (i2c_st_s == I2C_SLEEP);

endmodule