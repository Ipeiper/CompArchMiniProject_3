`include "GOL.sv"
`include "memswitch.sv"
`include "datafetch.sv"
`include "ws2812b.sv"
`include "controller.sv"

module top (
    input logic clk,
    output logic _48b,
    output logic _45a
    
);
//the width and height of the board, and therefore LED
localparam WIDTH = 8;
localparam HEIGHT = 8;
//Frames per second
localparam FPS = 5;
//clock rate in hertz
localparam CLKRATE = 12000000;
//the look that we want the pixels to have, adjusts brightness
localparam PIXEL_LOOK = 8'b00010000;
//the default state of the memory
localparam DEFMEMSTATE = 0;

//pixel data values for RGB
logic [23:0] led_data;

//matrix variables
//red
logic [$clog2(HEIGHT)-1:0]read_address_r_m;
logic [WIDTH-1:0]read_data_r_m;
//green
logic [$clog2(HEIGHT)-1:0]read_address_g_m;
logic [WIDTH-1:0]read_data_g_m;
//blue
logic [$clog2(HEIGHT)-1:0]read_address_b_m;
logic [WIDTH-1:0]read_data_b_m;

//Game of Life variables
//red
logic [$clog2(HEIGHT)-1:0]read_address_r_c;
logic [WIDTH-1:0]read_data_r_c;
logic [$clog2(HEIGHT)-1:0]write_address_r;
logic [WIDTH-1:0]write_data_r;
//green
logic [$clog2(HEIGHT)-1:0]read_address_g_c;
logic [WIDTH-1:0]read_data_g_c;
logic [$clog2(HEIGHT)-1:0]write_address_g;
logic [WIDTH-1:0]write_data_g;
//blue
logic [$clog2(HEIGHT)-1:0]read_address_b_c;
logic [WIDTH-1:0]read_data_b_c;
logic [$clog2(HEIGHT)-1:0]write_address_b;
logic [WIDTH-1:0]write_data_b;

//write enables
logic [0:0] write_enable_r ;
logic [0:0] write_enable_g ;
logic [0:0] write_enable_b ;

//tells all the units when to start a new frame
logic [0:0] frame_start;

//tells datafetch when to start
logic [0:0] fetch_start;

//ws2812b Driver output
logic driver_out;

//tells the driver when to transmit pixels
logic transmit_pixel;

//the x and y position as defined by the controller for the led
logic [$clog2(WIDTH)-1:0]cell_x;
logic [$clog2(HEIGHT)-1:0]cell_y;

//tells the shift register when to shift
logic [0:0]shift;
//the data within the shift register
logic [23:0]sreg;
//when to load the new data into the shift register
logic [0:0]load_sreg;

// GAME OF LIFE RED
//calculation
GOL #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
)GOL_R(
    .clk(clk),
    .read_address(read_address_r_c),
    .read_data(read_data_r_c),
    .write_address(write_address_r),
    .write_data(write_data_r),
    .write_enable(write_enable_r),
    .frame_start(frame_start)
);

//memswitch red
memswitch #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .DEFMEMSTATE(DEFMEMSTATE),
    .INIT_FILE_A("GOL_r.txt"),
    .INIT_FILE_B("GOL_r.txt")
) memswitch_r (
    .clk(clk),
    .read_address_1(read_address_r_c),
    .read_data_1(read_data_r_c),
    .read_address_2(read_address_r_m),
    .read_data_2(read_data_r_m),
    .write_address(write_address_r),
    .write_data(write_data_r),
    .write_enable(write_enable_r),
    .frame_start(frame_start)
);

// game of life green
GOL #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
)GOL_G(
    .clk(clk),
    .read_address(read_address_g_c),
    .read_data(read_data_g_c),
    .write_address(write_address_g),
    .write_data(write_data_g),
    .write_enable(write_enable_g),
    .frame_start(frame_start)
);

//memswitch green
memswitch #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .DEFMEMSTATE(DEFMEMSTATE),
    .INIT_FILE_A("GOL_g.txt"),
    .INIT_FILE_B("GOL_g.txt")
) memswitch_g (
    .clk(clk),
    .read_address_1(read_address_g_c),
    .read_data_1(read_data_g_c),
    .read_address_2(read_address_g_m),
    .read_data_2(read_data_g_m),
    .write_address(write_address_g),
    .write_data(write_data_g),
    .write_enable(write_enable_g),
    .frame_start(frame_start)
);

// game of life blue
GOL #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
)GOL_B(
    .clk(clk),
    .read_address(read_address_b_c),
    .read_data(read_data_b_c),
    .write_address(write_address_b),
    .write_data(write_data_b),
    .write_enable(write_enable_b),
    .frame_start(frame_start)
);

//memswitch blue calculation
memswitch #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .DEFMEMSTATE(DEFMEMSTATE),
    .INIT_FILE_A("GOL_b.txt"),
    .INIT_FILE_B("GOL_b.txt")
) memswitch_b (
    .clk(clk),
    .read_address_1(read_address_b_c),
    .read_data_1(read_data_b_c),
    .read_address_2(read_address_b_m),
    .read_data_2(read_data_b_m),
    .write_address(write_address_b),
    .write_data(write_data_b),
    .write_enable(write_enable_b),
    .frame_start(frame_start)
);

//ws2812b, LED driver
ws2812b led_driver(
    .clk(clk),
    .serial_in(sreg[23]),
    .transmit(transmit_pixel),
    .ws2812b_out(driver_out),
    .shift(shift)
);

//controler that controls the tranmission timings
controller #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .CLKRATE(CLKRATE),
    .FPS(FPS)
) controller(
    .clk(clk),
    .transmit_pixel(transmit_pixel),
    .cell_x(cell_x),
    .cell_y(cell_y),
    .frame_start(frame_start),
    .fetch_start(fetch_start),
    .load_sreg(load_sreg)
);

//fetches data from memshift for the led_matrix and controller
datafetch #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .PIXEL_LOOK(PIXEL_LOOK)
)datafetch(
    .clk(clk),
    .fetch_start(fetch_start),
    .cell_x(cell_x),
    .cell_y(cell_y),
    .read_data_r(read_data_r_m),
    .read_data_g(read_data_g_m),
    .read_data_b(read_data_b_m),
    .read_address_r(read_address_r_m),
    .read_address_g(read_address_g_m),
    .read_address_b(read_address_b_m),
    .led_data(led_data)
);

//shift register
always_ff @(posedge clk) begin
    if (load_sreg) begin
        sreg <= led_data;
    end
    else if (shift) begin
        sreg <= { sreg[22:0], 1'b0 };
    end
end

//actually assigns led_matrix
assign _48b = driver_out;
assign _45a = ~driver_out;

endmodule
