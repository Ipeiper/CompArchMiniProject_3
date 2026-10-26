`include "gmem.sv"

module memswitch #(
    //Parameters
    parameter WIDTH = 8,
    parameter HEIGHT = 8,
    parameter [0:0]DEFMEMSTATE = 1'b0,
    parameter INIT_FILE_A = "",
    parameter INIT_FILE_B = ""
)(
    input logic clk,
    // the abstracted memory controls
    input logic [$clog2(HEIGHT)-1:0] read_address_1,
    output logic [WIDTH-1:0] read_data_1,
    input logic [$clog2(HEIGHT)-1:0] read_address_2,
    output logic [WIDTH-1:0] read_data_2,
    input logic [$clog2(HEIGHT)-1:0] write_address,
    input logic [WIDTH-1:0] write_data,
    input logic [0:0] write_enable,
    //tells the program when to change states and run
    input logic [0:0]frame_start
);
    // 0 means  A is read, B is write
    // 1 means  B is read, A is write
    logic [0:0]mem_state = DEFMEMSTATE;
    //memory unit A
    //address and data
    logic [WIDTH-1:0]mem_a_read_data_1;
    logic [WIDTH-1:0]mem_a_read_data_2;
    // toggles whether the memory unit is doing reading or writing
    logic [0:0]mem_a_write_enable;
    //memory unit itself
    gmem  #(
        .INIT_FILE      (INIT_FILE_A),
        .WIDTH          (WIDTH),
        .HEIGHT         (HEIGHT)
    ) A (
        .clk              (clk),
        .read_address_1   (read_address_1),
        .read_data_1      (mem_a_read_data_1),
        .read_address_2   (read_address_2),
        .read_data_2      (mem_a_read_data_2),
        .write_enable     (mem_a_write_enable),
        .write_address    (write_address),
        .write_data       (write_data)
    );
    //memory unit b
    //address and data
    logic [WIDTH-1:0]mem_b_read_data_1;
    logic [WIDTH-1:0]mem_b_read_data_2;
    // toggles whether the memory unit is doing reading or writing
    logic [0:0]mem_b_write_enable;
    //unit itself
    gmem  #(
        .INIT_FILE      (INIT_FILE_B),
        .WIDTH          (WIDTH),
        .HEIGHT         (HEIGHT)
    ) B (
        .clk              (clk),
        .read_address_1   (read_address_1),
        .read_data_1      (mem_b_read_data_1),
        .read_address_2   (read_address_2),
        .read_data_2      (mem_b_read_data_2),
        .write_enable     (mem_b_write_enable),
        .write_address    (write_address),
        .write_data       (write_data)
    );
    //routing the signals based on the current state of mem_state
    always_comb begin
        if(~mem_state) begin
            read_data_1=mem_a_read_data_1;
            read_data_2=mem_a_read_data_2;
        end
        else begin
            read_data_1=mem_b_read_data_1;
            read_data_2=mem_b_read_data_2;
        end
    end
    always_ff @(posedge clk)begin
        if(frame_start) begin
            mem_state<=~mem_state;
        end
    end
//makes sure that the correct read and write permissions are applied
assign mem_a_write_enable = mem_state & write_enable;
assign mem_b_write_enable = ~mem_state & write_enable;
endmodule
