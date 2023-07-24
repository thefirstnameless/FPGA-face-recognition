module lcd_display(input lcd_clk,
                   input sys_rst_n,
                   input [15:0] lcd_id,
                   input [10:0] pixel_xpos,
                   input [10:0] pixel_ypos,
                   input [15:0] cmos_data,
                   input [10:0] h_disp,
                   input [10:0] v_disp,
                   output [15:0] lcd_data,
                   output data_req);
    
    parameter V_CMOS_DISP = 11'd480;
    parameter H_CMOS_DISP = 11'd640;
    
    localparam BLACK = 16'd0;
    
    //reg define
    reg data_val;
    
    wire [10:0] display_border_pos_l;
    wire [10:0] display_border_pos_r;
    wire [10:0] display_border_pos_t;
    wire [10:0] display_border_pos_b;
    
    /*--------TOP SECRET--------*/
    //----------最高機密---------//
    /*----------WARNING---------*/
    
    assign display_border_pos_l = (h_disp - H_CMOS_DISP)/2-1;
    assign display_border_pos_r = H_CMOS_DISP + (h_disp - H_CMOS_DISP)/2-1;
    assign display_border_pos_t = (v_disp - V_CMOS_DISP)/2;
    assign display_border_pos_b = V_CMOS_DISP + (v_disp - V_CMOS_DISP)/2;

    assign data_req = ((pixel_xpos >= display_border_pos_l) &&
                      (pixel_xpos < display_border_pos_r) &&
                      (pixel_ypos > display_border_pos_t) &&
                      (pixel_ypos <= display_border_pos_b)
                      ) ? 1'b1 : 1'b0;

    assign lcd_data = data_val ? cmos_data : BLACK;

    always @(posedge lcd_clk or negedge sys_rst_n) begin
        if(!sys_rst_n)
            data_val <= 1'b0;
        else
            data_val <= data_req; 
    end 

endmodule
