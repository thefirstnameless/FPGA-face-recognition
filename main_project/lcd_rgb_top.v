module lcd_rgb_top (input sys_clk,
                    input sys_rst_n,
                    input sys_init_done,
                    output lcd_clk,
                    output lcd_hs,
                    output lcd_vs,
                    output lcd_de,
                    inout [23:0] lcd_rgb,
                    output lcd_bl,
                    output lcd_rst,
                    output lcd_pclk,
                    output [15:0] lcd_id,
                    output wire out_vsync,
                    output wire [9:0] pixel_xpos,
                    output wire [9:0] pixel_ypos,
                    output wire [10:0] h_disp,
                    output wire [10:0] v_disp,
                    input [15:0] data_in,
                    output data_req);
    
    //wire define
    wire [15:0] lcd_data_w;
    wire data_req_w;
    wire data_req_big;
    wire data_req_small;
    wire [15:0] lcd_data;
    wire [15:0] lcd_rgb_565;
    wire [23:0] lcd_rgb_o;
    wire [23:0] lcd_rgb_i;
    
    /*--------TOP SECRET--------*/
    //----------最高機密---------//
    /*----------WARNING---------*/
    
    assign data_req = (lcd_id == 16'h4342) ? data_req_small : data_req_big;
    
    assign lcd_data = (lcd_id == 16'h4342) ? data_in : lcd_data_w;
    
    assign lcd_rgb_o = {lcd_rgb_565[15:11],3'b000,lcd_rgb_565[10:5],2'b00,lcd_rgb_565[4:0],3'b000};
    
    assign lcd_rgb   = lcd_de ? lcd_rgb_o : {24{1'bz}};
    assign lcd_rgb_i = lcd_rgb;
    
    //div clk module
    
    clk_div u_clk_div(
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .lcd_id(cld_id),
    .clk_pclk(lcd_clk)
    );
    
    rd_id u_rd_id(
    .clk (sys_clk),
    .rst_n (sys_rst_n),
    .lcd_rgb (lcd_rgb_i),
    .lcd_id (lcd_id)
    );
    
    //lcd driver module
    lcd_driver u_lcd_driver(
    .lcd_clk (lcd_clk),
    .sys_rst_n (sys_rst_n & sys_init_done),
    .lcd_id (lcd_id),
    
    .lcd_hs (lcd_hs),
    .lcd_vs (lcd_vs),
    .lcd_de (lcd_de),
    .lcd_rgb (lcd_rgb_565),
    .lcd_bl (lcd_bl),
    .lcd_rst (lcd_rst),
    .lcd_pclk (lcd_pclk),
    
    .pixel_data (lcd_data),
    .data_req (data_req_small),
    .out_vsync (out_vsync),
    .h_disp (h_disp),
    .v_disp (v_disp),
    .pixel_xpos (pixel_xpos),
    .pixel_ypos (pixel_ypos)
    );
    
    //lcd display module
    lcd_display u_lcd_display(
    .lcd_clk (lcd_clk),
    .sys_rst_n (sys_rst_n & sys_init_done),
    .lcd_id (lcd_id),
    
    .pixel_xpos (pixel_xpos),
    .pixel_ypos (pixel_ypos),
    .h_disp (h_disp),
    .v_disp (v_disp),
    .cmos_data (data_in),
    .lcd_data (lcd_data_w),
    .data_req (data_req_big)
    );
endmodule
