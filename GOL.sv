// Game Of Life(GOL) runs one full tick of the game of life
module GOL #(
    //parameters
    // size dimensions of the game
    parameter WIDTH=8,
    parameter HEIGHT=8
)(
    input logic clk,
    // The abstracted version of the two memory units that get switched through memswitch
    output logic [$clog2(HEIGHT)-1:0]read_address,
    input logic [WIDTH-1:0]read_data,
    output logic [$clog2(HEIGHT)-1:0]write_address,
    output logic [WIDTH-1:0]write_data,
    output logic [0:0] write_enable,
    //pulsed clock that starts the frame calculations
    input logic [0:0]frame_start



);

//Defines several facts about the cell being currently calculated
logic [$clog2(WIDTH)-1:0] cell_x = '0;
logic [$clog2(HEIGHT)-1:0] cell_y = '0;
//counts the number of mem address we are on
logic [1:0] mem_num= 2'b00;

//Address Variables
//These define the addresses of the rows that we read from the memory unit for the purposes of calculating neighbors
// the addresses for the 3 rows numbered from top to bottom
logic [$clog2(HEIGHT)-1:0] address_1 = 0;
logic [$clog2(HEIGHT)-1:0] address_2 = 0;
logic [$clog2(HEIGHT)-1:0] address_3 = 0;
//The horizontal index for each of the three coloums numbered from left to right
logic [$clog2(WIDTH)-1:0] index_1 = 0;
logic [$clog2(WIDTH)-1:0] index_2 = 0;
logic [$clog2(WIDTH)-1:0] index_3 = 0;
//the data stored within the memory unit as the addresses of the same number
logic [WIDTH-1:0] data_1 = 0;
logic [WIDTH-1:0] data_2 = 0;
logic [WIDTH-1:0] data_3 = 0;
//CALCULATION VARIABLES
//cell_status: represents the state of the current cell, dead or alive
logic [0:0] cell_status = 0;
//neighbors added
logic [3:0] neigh_add = 0;
//the output of the cell calcultaion
logic [0:0] cell_out = 0;
//output data for write_data
logic [WIDTH-1:0] data_out = 0;

// states of the FSM
localparam [3:0]IDLE =     4'b0000;
localparam [3:0]ADDRESS =  4'b0001;
localparam [3:0]QUERY =    4'b0010;
localparam [3:0]WAIT =     4'b0011;
localparam [3:0]LISTEN =   4'b0100;
localparam [3:0]PREP =     4'b0101;
localparam [3:0]CALCULATE= 4'b0110;
localparam [3:0]WRITE =    4'b0111;
localparam [3:0]SCAN =     4'b1001;

// controls the state of the FSM
logic [3:0]state = IDLE;

//helper funciton to fix my pain
function automatic [WIDTH-1:0] replace_cell_cur (
    //row of data thats being changed and returned
    input logic [WIDTH-1:0] data,
    //index of the current cell
    input int index,
    //value of the current cell
    input logic cell_out
);
    replace_cell_cur = data;
    replace_cell_cur[index] = cell_out;

endfunction

//this creates the row as we go along
logic [WIDTH-1:0] row_base;
logic [WIDTH-1:0] row_new; 
// if cell_x is 0, then its a new row and is therefore 0
assign row_base = (cell_x == 0) ? 0 : data_out;
//make the new row be the base row with the new value added in using replace_cell_cur
assign row_new = replace_cell_cur(row_base,cell_x,cell_out);

// main case statement that drives GOL logic
always_ff @(posedge clk) begin
    unique case (state)
        IDLE: begin // Idle state that happens when no calculations are running waits to hear frame_start to move to the first scan
            if (frame_start == 1) begin
                state <= ADDRESS;
            end
        end
        ADDRESS: begin // finds the y addresses and the x indexes for the cell and its neighbors
            //y search
            //cell 1,2,3
            if (cell_y == 0) begin
                address_1 <= HEIGHT-1;
            end
            else begin
                address_1 <= cell_y-1;
            end
            //cell 4,5,6
            address_2 <= cell_y;
            //cell 7,8,9
            if (cell_y == HEIGHT - 1) begin
                address_3 <= 0;
            end
            else begin
                address_3<=cell_y+1;
            end
            //x search
            //cell 1,4,7
            if (cell_x == 0) begin
                index_1 <= WIDTH-1;
            end
            else begin
                index_1 <= cell_x-1;
            end
            //cell 2,5,8
            index_2 <= cell_x;
            //cell 3,6,9
            if (cell_x == WIDTH - 1) begin
                index_3 <= 0;
            end
            else begin
                index_3<=cell_x+1;
            end
            //Ending
            state <= QUERY;
        end
        QUERY: begin // asks the memory for the data at the address
        //QUERY and LISTEN are paired, in that they bounce back and forth 3 times to read all three addresses before progressing
            if (mem_num == 0) begin
                read_address <= address_1;
                state <= WAIT;
            end
            else if (mem_num==1) begin
                read_address <= address_2;
                state <= WAIT;
            end
            else if (mem_num==2) begin
                read_address <= address_3;
                state <= WAIT;
            end
        end
        WAIT: begin //waits a clock tick to let the memory do its thing
            state<=LISTEN;
        end
        LISTEN: begin // listens for the data from that address
            if (mem_num == 0) begin
                data_1 <= read_data;
                mem_num<=1;
                state <= QUERY;
            end
            else if (mem_num==1) begin
                data_2 <= read_data;
                mem_num<=2;
                state <= QUERY;
            end
            else if (mem_num==2) begin
                data_3 <= read_data;
                mem_num<=0;
                state <= PREP;
            end
        end
        PREP:begin //prep data for calculation
            //Data prep
            //preps row 1
            neigh_add <= data_1[index_1]+data_1[index_2]+data_1[index_3]
            //preps row 2, excluding the current square
                       + data_2[index_1]+data_2[index_3]
            //preps row 3
                       + data_3[index_1]+data_3[index_2]+data_3[index_3];
            //Cell_status is the state of the current cell, dead or alive
            cell_status<=data_2[index_2];
            state<=CALCULATE;
        end
        CALCULATE: begin // prepares the data into cell_status and then runs the GOL calculation using cell_status
            //Calculation
            // if cell is alive and neighbors are 2 or 3 then alive
            if (cell_status && (neigh_add==2 || neigh_add == 3) ) begin
                cell_out <= 1'b1;
            end
            //if cell is dead but neighbors are 3 the ncell is alive
            else if (~cell_status && neigh_add == 3) begin
                cell_out<=1'b1;
            end
            // if neither condition is filled then cell is dead
            else begin
                cell_out<=1'b0;
            end
            state <= WRITE;
        end
        WRITE: begin // writes the value to the currently assigned memory through
            //zeros calculation values
            neigh_add <= 0;
            cell_status <=0;
            //enables writing
            write_enable <=1;
            //write address assignment
            write_address <= address_2;
            //write data assignment
            write_data <= row_new;
            data_out <= row_new;
            state <= SCAN;
        end
        SCAN: begin //finds the current x and y values for the cell, when it is on the final one currently, turns off the loop be setting state to idle
            write_enable <= 0;
            if (cell_y == HEIGHT-1 && cell_x == WIDTH-1) begin
                cell_y <= 0;
                cell_x <= 0;
                //turns off frame calculation
                state <= IDLE;
            end
            // x scan for end
            else if (cell_x == WIDTH-1) begin
                cell_x <=0;
                cell_y <= cell_y + 1;
                state <= ADDRESS;
            end
            else begin
                cell_x <= cell_x + 1;
                state <= ADDRESS;
            end
        end
        default: state <= IDLE;
    endcase
end
//end of GOL
endmodule
