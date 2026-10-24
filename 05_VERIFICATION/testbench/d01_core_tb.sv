module d01_core_tb;
    logic clk, rst_n, enable, up;
    logic [7:0] count, count_ref;

    d01_core dut(
        .clk(clk), .rst_n(rst_n), .enable(enable),
        .up(up), .count(count)
    );

    d01_reference ref_i(
        .clk(clk), .rst_n(rst_n), .enable(enable),
        .up(up), .count_ref(count_ref)
    );

    always #5 clk = ~clk;

    task automatic check;
        @(posedge clk); #1;
        assert(count === count_ref)
            else $fatal(1, "D01 mismatch got=%0d ref=%0d",
                        count, count_ref);
    endtask

    initial begin
        // Tao file waveform
        $dumpfile("d01_core.vcd");
        $dumpvars(0, d01_core_tb);

        clk=0; rst_n=0; enable=0; up=1;
        repeat(2) check(); rst_n=1;
        repeat(2) check();
        enable=1; up=1; repeat(5) check();
        up=0; repeat(3) check();

        dut.count=8'hFE;
        ref_i.count_ref=8'hFE;
        up=1;
        check(); check();

        dut.count=8'h01;
        ref_i.count_ref=8'h01;
        up=0;
        check(); check();

        enable=1; up=1; rst_n=0; check();

        $display("D01 core verification PASS");
        $finish;
    end
endmodule
