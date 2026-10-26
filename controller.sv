
module controller #(
    parameter WIDTH = 8,
    parameter HEIGHT = 8,
    parameter CLKRATE = 12000000,
    parameter FPS = 20
    
)(
    input logic clk,
    //pulses when its time to transmit the pixel
    output logic [0:0] transmit_pixel,
    //the x and y values for the current cell
    output logic [$clog2(WIDTH)-1:0] cell_x= '0,
    output logic [$clog2(HEIGHT)-1:0] cell_y= '0,
    // tells the code when to start a new frame
    output logic [0:0] frame_start,
    //starts data_fetch with a pulse of high
    output logic [0:0] fetch_start,
    //pulses to tell shift register to load new data
    output logic [0:0] load_sreg
);

    //the state equivlants
    localparam TRANSMIT_FRAME       = 1'b0;
    localparam IDLE                 = 1'b1;

    //transmit phase equivlants
    localparam [2:0] READ_CH_VALS   = 3'b001;
    localparam [2:0] WAIT           = 3'b010;
    localparam [2:0] LOAD_SREG      = 3'b011;
    localparam [2:0] TRANSMIT_PIXEL = 3'b100;

    //the cycle ends
    localparam [8:0] TRANSMIT_CYCLES    = 9'd360;       // = 24 bits / pixel x 15 cycles / bit cycles to allow for memory fetching
    localparam [31:0] IDLE_CYCLES       = (CLKRATE/FPS)-(64*(360+2)) ;  // = 375000 - 64 x (360 + 2) for 32 frames / second

    logic state = TRANSMIT_FRAME;
    logic next_state;

    logic [2:0] transmit_phase = READ_CH_VALS;
    logic [2:0] next_transmit_phase;

    //counters for the transmitting and idle states
    logic [8:0] transmit_counter = 9'd0;
    logic [31:0] idle_counter = '0;

    //completion signals
    logic transmit_pixel_done;
    logic idle_done;

    //Defines completion, the pixel is done transmitting when it hits transmit cycles
    assign transmit_pixel_done = (transmit_counter == TRANSMIT_CYCLES - 1);
    assign idle_done = (idle_counter == IDLE_CYCLES - 1);
    assign frame_start = idle_done;
    //begins data fetch 3 cycles before IDLE ends
    assign fetch_start = (transmit_phase == READ_CH_VALS);

    //at the end of the clk tick, set the state to the next state
    always_ff @(posedge clk) begin
        state <= next_state;
        transmit_phase <= next_transmit_phase;
    end

    //sets the state to the correct next state
    always_comb begin
        next_state = 1'bx;
        unique case (state)
            TRANSMIT_FRAME:
                if ((cell_y == HEIGHT-1 && cell_x == WIDTH-1) && (transmit_pixel_done))
                    next_state = IDLE;
                else
                    next_state = TRANSMIT_FRAME;

            IDLE:
                if (idle_done)
                    next_state = TRANSMIT_FRAME;
                else
                    next_state = IDLE;
        endcase
    end

    //
    always_comb begin
        next_transmit_phase = READ_CH_VALS;
        if (state == TRANSMIT_FRAME) begin
            case (transmit_phase)
                READ_CH_VALS:
                    next_transmit_phase = WAIT;
                WAIT:
                    next_transmit_phase = LOAD_SREG;
                LOAD_SREG:
                    next_transmit_phase = TRANSMIT_PIXEL;
                TRANSMIT_PIXEL:
                    next_transmit_phase = transmit_pixel_done ? READ_CH_VALS : TRANSMIT_PIXEL;
            endcase
        end
    end

    //increases cell_X
    always_ff @(posedge clk) begin
        if ((state == TRANSMIT_FRAME) && transmit_pixel_done) begin
            if (cell_y == HEIGHT-1 && cell_x == WIDTH-1) begin
                cell_y <= 0;
                cell_x <= 0;
            end
            // x scan for end
            else if (cell_x == WIDTH-1) begin
                cell_x <=0;
                cell_y <= cell_y + 1;
            end
            else begin
                cell_x <= cell_x + 1;
            end
        end
    end


    always_ff @(posedge clk) begin
        if (transmit_phase == TRANSMIT_PIXEL) begin
            transmit_counter <= transmit_counter + 1;
        end
        else begin
            transmit_counter <= 9'd0;
        end
    end

    always_ff @(posedge clk) begin
        if (state == IDLE) begin
            idle_counter <= idle_counter + 1;
        end
        else begin
            idle_counter <= 20'd0;
        end
    end

    // defines the transmit pixel signal
    assign transmit_pixel = (transmit_phase == TRANSMIT_PIXEL);

    //load the shift register
    assign load_sreg = (transmit_phase == LOAD_SREG);
endmodule
