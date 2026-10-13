`default_nettype none

module tt_um_d01_counter (
    input  wire [7:0] ui_in,    // Dedicated inputs: d_in[7:0]
    output wire [7:0] uo_out,   // Dedicated outputs: count[7:0]
    input  wire [7:0] uio_in,   // IOs: [0]=load, [1]=up_down, [2]=en
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path
    input  wire       ena,      // always 1 when selected
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire [7:0] d_in = ui_in;
  wire load    = uio_in[0];
  wire up_down = uio_in[1];
  wire en      = uio_in[2];

  reg [7:0] count_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count_reg <= 8'h00;
    end else if (!en) begin
      count_reg <= count_reg;
    end else if (load) begin
      count_reg <= d_in;
    end else if (up_down) begin
      count_reg <= count_reg + 8'd1;
    end else begin
      count_reg <= count_reg - 8'd1;
    end
  end

  assign uo_out  = count_reg;
  assign uio_out = 8'b0000_0000;
  assign uio_oe  = 8'b0000_0000;

  wire _unused = &{ena, uio_in[7:3], 1'b0};

endmodule
