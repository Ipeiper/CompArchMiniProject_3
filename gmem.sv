// memory module for game of life state
module gmem #(
    parameter INIT_FILE = "",
    parameter WIDTH = 8,
    parameter HEIGHT = 8
)(
    input logic clk,
    input logic [$clog2(HEIGHT)-1:0] read_address_1,
    output logic [WIDTH-1:0] read_data_1,
    input logic [$clog2(HEIGHT)-1:0] read_address_2,
    output logic [WIDTH-1:0] read_data_2,
    input logic write_enable,
    input logic [$clog2(HEIGHT)-1:0] write_address,
    input logic [WIDTH-1:0] write_data
);

    logic [WIDTH-1:0] mem [0:HEIGHT-1];

    initial if (INIT_FILE) begin
        $readmemh(INIT_FILE, mem);
    end

    always_ff @(posedge clk) begin

        if (write_enable) begin
            mem[write_address] <= write_data;
        end
        read_data_1 <= mem[read_address_1];
        read_data_2 <= mem[read_address_2];
    end
endmodule