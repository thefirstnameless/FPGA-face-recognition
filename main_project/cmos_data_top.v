module cmos_data_top(
input rst_n , //复位信号
input [15:0] lcd_id , //LCD 屏的 ID 号
input [10:0] h_disp , //LCD 屏水平分辨率
input [10:0] v_disp , //LCD 屏垂直分辨率 
//摄像头接口 
input cam_pclk , //cmos 数据像素时钟
input cam_vsync , //cmos 场同步信号
input cam_href , //cmos 行同步信号
 input [7:0] cam_data , 
 //用户接口
 output [10:0] h_pixel , //存入 ddr3 的水平分辨率
 output [10:0] v_pixel , //存入 ddr3 的屏垂直分辨率 
 output [27:0] ddr3_addr_max , //存入 DDR3 的最大读写地址
 output cmos_frame_vsync , //帧有效信号 
 output cmos_frame_href , //行有效信号
 output cmos_frame_valid , //数据有效使能信号
 output [15:0] cmos_frame_data //有效数据 
 );

 //wire define 
 wire [10:0] h_pixel; //存入 ddr3 的水平分辨率 
 wire [10:0] v_pixel; //存入 ddr3 的屏垂直分辨率 
 wire [15:0] lcd_id_a; //时钟同步后的 LCD 屏的 ID 号
 wire [27:0] ddr3_addr_max; //存入 DDR3 的最大读写地址 
 wire [15:0] wr_data_tailor; //经过裁剪的摄像头数据
 wire [15:0] wr_data; //没有经过裁剪的摄像头数据

 //*****************************************************
 //** main code
 //***************************************************** 
 
 assign cmos_frame_valid = (lcd_id_a == 16'h4342) ? data_valid_tailor : data_valid ; 
 assign cmos_frame_data = (lcd_id_a == 16'h4342) ? wr_data_tailor : wr_data ;
 
 //摄像头数据裁剪模块
 cmos_tailor u_cmos_tailor(
 .rst_n (rst_n), 
 .lcd_id (lcd_id),
 .lcd_id_a (lcd_id_a),
 .cam_pclk (cam_pclk),
 .cam_vsync (cmos_frame_vsync),
 .cam_href (cmos_frame_href),
 .cam_data (wr_data),
 .cam_data_valid (data_valid),
 .h_disp (h_disp),
 .v_disp (v_disp), 
 .h_pixel (h_pixel),
 .v_pixel (v_pixel),
 .ddr3_addr_max (ddr3_addr_max),
 .cmos_frame_valid (data_valid_tailor), 
 .cmos_frame_data (wr_data_tailor) 

 );

 //摄像头数据采集模块
 cmos_capture_data u_cmos_capture_data(

 .rst_n (rst_n),
 .cam_pclk (cam_pclk), 
 .cam_vsync (cam_vsync),
 .cam_href (cam_href),
 .cam_data (cam_data), 
 .cmos_frame_vsync (cmos_frame_vsync),
 .cmos_frame_href (cmos_frame_href),
 .cmos_frame_valid (data_valid), 
 .cmos_frame_data (wr_data) 
 );
 
 endmodule