module debounce #(
  delay_g = 50_000_000
)(
  input  logic clk_i,
  input  logic rst_n_i,
  input  logic signal_i,

  output logic pedge_o
);
typedef enum logic[0:0] {S[2]} state_t;

state_t st_s;
logic   count_s;
logic   done_s;

logic   buffer_s;
logic   signal_pedge_s;

timer #(
  delay_g
) 
timer_0 (.*, .count_i(count_s), .done_o(done_s));

always_ff @(posedge clk_i) begin
  buffer_s <= signal_i;
end

always_ff @(posedge clk_i) begin
  if(!rst_n_i) begin
    st_s <= S0;
  end else begin
    case(st_s)
      S0: begin
        if(signal_pedge_s) begin
          st_s <= S1; 
        end
      end
      
      S1: begin
        if (done_s) begin
          st_s <= S0;
        end
      end
      
      default: st_s <= S0;
    endcase
  end
end

assign signal_pedge_s = ~buffer_s & signal_i;
assign count_s        = (st_s == S1);
assign pedge_o        = signal_pedge_s && (st_s == S0);

endmodule