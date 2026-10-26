module datafetch #(
    parameter WIDTH = 8,
    parameter HEIGHT = 8,
    parameter PIXEL_LOOK = 8'b11111111

)(
    input logic clk,
    //when datafetch should start, also known as 4 ticks before transmitting
    input logic fetch_start,
    input logic [$clog2(WIDTH)-1:0]cell_x,
    input logic [$clog2(HEIGHT)-1:0]cell_y,
    //data we are reading
    input logic [WIDTH-1:0]read_data_r,
    input logic [WIDTH-1:0]read_data_g,
    input logic [WIDTH-1:0]read_data_b,
    //addresses of the data we are reading
    output logic [$clog2(HEIGHT)-1:0]read_address_r,
    output logic [$clog2(HEIGHT)-1:0]read_address_g,
    output logic [$clog2(HEIGHT)-1:0]read_address_b,
    //The combined data of all the colors for the specific cell
    output logic [23:0]led_data
);

// connects the cell y value directly to the address for each of the three colors
assign read_address_r = cell_y;
assign read_address_g = cell_y;
assign read_address_b = cell_y;

// makes led_data the combination of all the color data points read at cell_x
// where if the cell is alive it is represented by PXIEL_LOOK, and if it is dead its an 8'b set of 0s
assign led_data = {read_data_g[cell_x] ? PIXEL_LOOK : 8'b0,
                   read_data_r[cell_x] ? PIXEL_LOOK : 8'b0,
                   read_data_b[cell_x] ? PIXEL_LOOK : 8'b0};

endmodule
