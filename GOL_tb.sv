`timescale 10ns/10ns
`include "top.sv"

module GOL_tb;

    logic clk = 0;
    logic _48b, _45a;

    top u0 (
        .clk            (clk), 
        ._48b           (_48b), 
        ._45a           (_45a)
    );

    initial begin
        $dumpfile("GOL.vcd");
        $dumpvars(0, GOL_tb);
        #100000000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule

