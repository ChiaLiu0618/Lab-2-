module CC(
    //Input Port
    input clk, rst_n,   //asynchronous active-low reset
	input in_valid,
	input [1:0] mode,
    input signed [7:0] xi, yi,

    //Output Port
    output reg out_valid,
	output reg [7:0] xo, yo
    );

//==============================================//
//            FSM State Declaration             //
//==============================================//
reg [2:0] state, next_state;
parameter IN_1 = 3'd0, IN_2 = 3'd1, IN_3 = 3'd2, IN_4 = 3'd3, TRAP_REND = 3'd4, CIRC_LINE = 3'd5, AREA_COMP = 3'd6;

//==============================================//
//                 reg declaration              //
//==============================================//
reg signed [7:0] a1, a2, b1, b2, c1, c2, d1, d2;
reg signed [7:0] in_x [0:3], in_y [0:3];

reg stop_call;
reg out_valid_0, out_valid_1, out_valid_2;

reg signed [20:0] radius_sqr;
reg signed [20:0] distance_sqr;
reg [1:0] relation;

reg signed [15:0] Area;

//==============================================//
//             Current State Block              //
//==============================================//
always @(*) begin
    case(state)
        IN_1: next_state = in_valid ? IN_2 : IN_1;
        IN_2: next_state = IN_3;
        IN_3: next_state = IN_4;
        IN_4: begin
            case(mode)
                2'b00: next_state = TRAP_REND;
                2'b01: next_state = CIRC_LINE;
                2'b10: next_state = AREA_COMP;
                default: next_state = IN_4;
            endcase
        end
        TRAP_REND: next_state = stop_call ? IN_1 : TRAP_REND;
        CIRC_LINE: next_state = IN_1;
        AREA_COMP: next_state = IN_1;
        default: next_state = IN_1;
    endcase
end


//==============================================//
//              Next State Block                //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= IN_1;
    else state <= next_state;
end

//==============================================//
//                  Input Block                 //
//==============================================//
    //first input
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin 
        a1 <= 8'b0;
        a2 <= 8'b0;
    end
    else if(in_valid & (state==IN_1)) begin
        a1 <= xi;
        a2 <= yi;
    end
    else begin
        a1 <= a1;
        a2 <= a2;
    end
end 

    //second input
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin 
        b1 <= 8'b0;
        b2 <= 8'b0;
    end
    else if(in_valid & (state==IN_2)) begin
        b1 <= xi;
        b2 <= yi;
    end
    else begin
        b1 <= b1;
        b2 <= b2;
    end
end 

    //third input
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin 
        c1 <= 8'b0;
        c2 <= 8'b0;
    end
    else if(in_valid & (state==IN_3)) begin
        c1 <= xi;
        c2 <= yi;
    end
    else begin
        c1 <= c1;
        c2 <= c2;
    end
end 

    //fourth input
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin 
        d1 <= 8'b0;
        d2 <= 8'b0;
    end
    else if(in_valid & (state==IN_4)) begin
        d1 <= xi;
        d2 <= yi;
    end
    else begin
        d1 <= d1;
        d2 <= d2;
    end
end 
//==============================================//
//              Calculation Block1              //
//==============================================//
    //mode 0
reg signed [8:0] i, j;
wire signed [8:0] x_sect_left, x_sect_right;
reg signed [16:0] width;
wire signed [8:0] height;
wire signed [16:0] x_frame_left, x_frame_left_next, x_frame_right_next, width_next;
reg signed [8:0] serial_out_x, serial_out_y;

assign x_sect_left = a1 - c1;
assign x_sect_right = b1 - d1;
assign height = a2 - c2;

reg signed [8:0] x_standard_left, x_standard_right;
reg signed [8:0] x_section_left, x_section_right;
reg signed [8:0] y_coordinate, y_coordinate_next, y_coordinate_next_right;
reg signed [8:0] height_signed, height_signed_right;

always @(*) begin
    if(a1 >= c1) begin
        x_standard_left = c1;
        x_section_left = x_sect_left;
        y_coordinate = j;
        y_coordinate_next = j + 1;
        height_signed = height;
    end
    else begin
        x_standard_left = a1;
        x_section_left = -x_sect_left;
        y_coordinate = j + c2 - a2;
        y_coordinate_next = j + 1 + c2 - a2;
        height_signed = - height;
    end
end

slope_increment s0(
    .x_standard(x_standard_left),
    .sect(x_section_left), 
    .y_coordinate(y_coordinate), 
    .height(height_signed),
    .frame(x_frame_left)
);

slope_increment s1(
    .x_standard(x_standard_left),
    .sect(x_section_left), 
    .y_coordinate(y_coordinate_next), 
    .height(height_signed),
    .frame(x_frame_left_next)
);

always @(*) begin
    if(b1 >= d1) begin
        x_standard_right = d1;
        x_section_right = x_sect_right;
        y_coordinate_next_right = j + 1;
        height_signed_right = height;
    end
    else begin
        x_standard_right = b1;
        x_section_right = -x_sect_right;
        y_coordinate_next_right = j + 1 + c2 - b2;
        height_signed_right = -height;
    end
end

slope_increment s2(
    .x_standard(x_standard_right),
    .sect(x_section_right), 
    .y_coordinate(y_coordinate_next_right), 
    .height(height_signed_right),
    .frame(x_frame_right_next)
);

assign width_next = x_frame_right_next - x_frame_left_next;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) width <=1;
    else if(state == IN_4) width <= xi - c1;
    else begin
        if(state == TRAP_REND) begin
            if((i==width) & (j==height)) width <= 1;  //end of mode
            else if(i == width) width <= width_next;   //end of row
            else width <= width;
        end
        
    end
end

    
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        serial_out_x <= 8'b0;
        serial_out_y <= 8'b0;
        i <= 0;
        j <= 0;
        stop_call <= 0;
    end
    else if(state == TRAP_REND) begin
        if((i==width) & (j==height)) begin  //end of mode
            stop_call <= 1;
            i <= 0;
            j <= 0;
            serial_out_x <= x_frame_left + i;
            serial_out_y <= c2 + j;
        end
        else begin
            stop_call <= 0;
            if(i == width) begin    //end of row
                i <= 0;
                j <= j + 1;
                serial_out_x <= x_frame_left + i;
                serial_out_y <= c2 + j;
            end
            else begin
                i <= i + 1;
                j <= j;
                serial_out_x <= x_frame_left + i;
                serial_out_y <= c2 + j;
            end 
        end
    end
    else begin
        stop_call <= 0;
        serial_out_x <= 8'b0;
        serial_out_y <= 8'b0;
        i <= 0;
        j <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid_0 <= 0;
    else if(state == TRAP_REND) begin
        if(stop_call) out_valid_0 <= 0;
        else out_valid_0 <= 1;
    end
    else out_valid_0 <= 0;
end

//==============================================//
//               Shared Multiplier              //
//==============================================//
// Shared Multiplier
reg signed [7:0] area_mult_a, area_mult_b, area_mult_c, area_mult_d;
wire signed [15:0] area_mult_result1, area_mult_result2;

assign area_mult_result1 = area_mult_a * area_mult_b;
assign area_mult_result2 = area_mult_c * area_mult_d;

always @(*) begin
    casez({state, mode})
        {IN_2, 2'b10}: begin
            area_mult_a = a1;
            area_mult_b = yi;
            area_mult_c = xi;
            area_mult_d = a2;
        end
        {IN_3, 2'b10}: begin
            area_mult_a = b1;
            area_mult_b = yi;
            area_mult_c = xi;
            area_mult_d = b2;
        end
        {IN_4, 2'b10}: begin
            area_mult_a = c1;
            area_mult_b = yi;
            area_mult_c = xi;
            area_mult_d = c2;
        end
        {AREA_COMP, 2'b??}: begin
            area_mult_a = d1;
            area_mult_b = a2;
            area_mult_c = a1;
            area_mult_d = d2;
        end
        {IN_2, 2'b01}: begin
            area_mult_a = a1;
            area_mult_b = a2 - yi;
            area_mult_c = xi - a1;
            area_mult_d = a2;
        end
        {IN_3, 2'b01}: begin
            area_mult_a = b2 - a2;
            area_mult_b = b2 - a2;
            area_mult_c = a1 - b1;
            area_mult_d = a1 - b1;
        end
        {IN_4, 2'b01}: begin
            area_mult_a = c1;
            area_mult_b = b2 - a2;
            area_mult_c = a1 - b1;
            area_mult_d = c2;
        end
        {CIRC_LINE, 2'b??}: begin
            area_mult_a = d2 - c2;
            area_mult_b = d2 - c2;
            area_mult_c = d1 - c1;
            area_mult_d = d1 - c1;
        end
        default: begin
            area_mult_a = 0;
            area_mult_b = 0;
            area_mult_c = 0;
            area_mult_d = 0;
        end
    endcase
end

reg signed [15:0] addA, addB, addC, addD, addE, addF, addG, addH;
reg signed [24:0] addI;

// SECOND
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addA <= 0;
        addB <= 0;
    end
    else if(state == IN_2) begin
        addA <= area_mult_result1;
        addB <= area_mult_result2;
    end
end

// THIRD
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addC <= 0;
        addD <= 0;
    end
    else if(state == IN_3) begin
        addC <= area_mult_result1;
        addD <= area_mult_result2;
    end
end

// FOURTH
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addE <= 0;
        addF <= 0;
    end
    else if(state == IN_4) begin
        addE <= area_mult_result1;
        addF <= area_mult_result2;
    end
end

// FIFTH
always @(*) begin
    if((state == AREA_COMP) || (state == CIRC_LINE)) begin
        addG = area_mult_result1;
        addH = area_mult_result2;
    end
    else begin
        addG = 0;
        addH = 0;
    end
end

always @(*) begin
    case(state)
        CIRC_LINE: addI = addE + addF + addA + addB;
        AREA_COMP: addI = addA - addB + addC - addD + addE - addF + addG - addH;
        default: addI = 0;
    endcase
end

//==============================================//
//              Calculation Block2              //
//==============================================//
    //mode 1 

always @(*) begin
    if(state == CIRC_LINE) begin
        radius_sqr = addG + addH;
        distance_sqr = (addI * addI) / (addC + addD);
    end
    else begin
        radius_sqr = 0;
        distance_sqr = 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        relation <= 2'b0;
        out_valid_1 <= 0;
    end
    else if(state == CIRC_LINE) begin
        if(distance_sqr > radius_sqr) relation <= 2'b0;
        else if(distance_sqr < radius_sqr) relation <= 2'b01;
        else relation <= 2'b10;
        out_valid_1 <= 1;
    end
    else begin
        relation <= 2'b0;
        out_valid_1 <= 0;
    end
end

//==============================================//
//              Calculation Block3              //
//==============================================//
    //mode 2
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Area <= 16'b0;
        out_valid_2 <= 0;
    end
    else if(state == AREA_COMP) begin
        Area <= addI / 2;
        out_valid_2 <= 1;
    end
    else begin
        Area <= 16'b0;
        out_valid_2 <= 0;
    end
end


//==============================================//
//                Output Block                  //
//==============================================//
wire signed [15:0] n_Area;
assign n_Area = -Area;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        xo <= 8'b0;
        yo <= 8'b0;
    end
    else begin
        case({out_valid_0, out_valid_1, out_valid_2})
            3'b100: begin
                xo <= serial_out_x;
                yo <= serial_out_y;
            end
            3'b010: begin
                xo <= 8'b0;
                yo <= {6'b0, relation};
            end
            3'b001: begin
                if(Area>=0) begin
                    xo <= Area[15:8];
                    yo <= Area[7:0];
                end
                else begin
                    xo <= n_Area[15:8];
                    yo <= n_Area[7:0];
                end
            end
            default: begin
                xo <= 8'b0;
                yo <= 8'b0;
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 0;
    else out_valid <= out_valid_0 | out_valid_1 | out_valid_2;
end


endmodule 

module slope_increment(
                    input signed [8:0] x_standard,
                    input signed [8:0] sect, 
                    input signed [8:0] y_coordinate, 
                    input signed [8:0] height,
                    output signed [16:0] frame
                    );
                    
assign frame = x_standard + (sect * y_coordinate) / height;
endmodule

