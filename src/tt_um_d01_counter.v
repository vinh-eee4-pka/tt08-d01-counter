`default_nettype none

module tt_um_d01_counter (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered or selected
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire en      = ui_in[0];
  wire up_down = ui_in[1];
  wire load    = ui_in[2];
  
  wire [7:0] d_in = uio_in;

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

  wire _unused = &{ena, ui_in[7:3], 1'b0};

endmodule
