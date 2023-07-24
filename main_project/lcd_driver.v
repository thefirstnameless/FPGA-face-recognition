module lcd_driver(input lcd_pclk,           //SHIZHONG
                  input rst_n,              //fuwei
                  input [15:0] lcd_id,      //ID
                  input [15:0] pixel_data,  //xiangsu shuju
                  output wire data_req,
                  output [10:0] pixel_xpos, //dangqianxiangsu hengzuobiao
                  output [10:0] pixel_ypos, //dangqianxiangsu zongzuobiao
                  output reg [10:0] h_disp, //LCD shuipingfenbianlv
                  output reg [10:0] v_disp, //LCD chuizhifenbianlv
                  output wire out_vsync,
                  output lcd_de,            //LCD shineng
                  output lcd_hs,            //LCD hangtongbuxinhao
                  output lcd_vs,            //LCD changtongbuxinhao
                  output lcd_bl,            //LCD beiguangkongzhi xinhao
                  output lcd_clk,           //LCD xiangsu shizhong
                  output wire [15:0] lcd_rgb,    //LCD RGB888 data
                  output lcd_rst);
    
    //parameter define
    // 4.3' 480*272
    parameter H_SYNC_4342  = 11'd41;
    parameter H_BACK_4342  = 11'd2;
    parameter H_DISP_4342  = 11'd480;
    parameter H_FRONT_4342 = 11'd2;
    parameter H_TOTAL_4342 = 11'd525;
    
    parameter V_SYNC_4342  = 11'd10;
    parameter V_BACK_4342  = 11'd2;
    parameter V_DISP_4342  = 11'd272;
    parameter V_FRONT_4342 = 11'd2;
    parameter V_TOTAL_4342 = 11'd286;
    
    // 4.3' 800*480
    parameter H_SYNC_4384  = 11'd128;
    parameter H_BACK_4384  = 11'd88;
    parameter H_DISP_4384  = 11'd800;
    parameter H_FRONT_4384 = 11'd40;
    parameter H_TOTAL_4384 = 11'd1056;
    
    parameter V_SYNC_4384  = 11'd2;
    parameter V_BACK_4384  = 11'd33;
    parameter V_DISP_4384  = 11'd480;
    parameter V_FRONT_4384 = 11'd10;
    parameter V_TOTAL_4384 = 11'd525;
    
    // 7' 800*480
    parameter H_SYNC_7084  = 11'd128;
    parameter H_BACK_7084  = 11'd88;
    parameter H_DISP_7084  = 11'd800;
    parameter H_FRONT_7084 = 11'd40;
    parameter H_TOTAL_7084 = 11'd1056;
    
    parameter V_SYNC_7084  = 11'd2;
    parameter V_BACK_7084  = 11'd33;
    parameter V_DISP_7084  = 11'd480;
    parameter V_FRONT_7084 = 11'd10;
    parameter V_TOTAL_7084 = 11'd525;
    
    // 7' 1024*600
    parameter H_SYNC_7016  = 11'd20;
    parameter H_BACK_7016  = 11'd140;
    parameter H_DISP_7016  = 11'd1024;
    parameter H_FRONT_7016 = 11'd160;
    parameter H_TOTAL_7016 = 11'd1344;
    
    parameter V_SYNC_7016  = 11'd3;
    parameter V_BACK_7016  = 11'd20;
    parameter V_DISP_7016  = 11'd600;
    parameter V_FRONT_7016 = 11'd12;
    parameter V_TOTAL_7016 = 11'd635;
    
    // 10' 1280*800
    parameter H_SYNC_1018  = 11'd10;
    parameter H_BACK_1018  = 11'd80;
    parameter H_DISP_1018  = 11'd1280;
    parameter H_FRONT_1018 = 11'd70;
    parameter H_TOTAL_1018 = 11'd1440;
    
    parameter V_SYNC_1018  = 11'd3;
    parameter V_BACK_1018  = 11'd10;
    parameter V_DISP_1018  = 11'd800;
    parameter V_FRONT_1018 = 11'd10;
    parameter V_TOTAL_1018 = 11'd823;
    
    //reg define
    reg [10:0] h_sync;
    reg [10:0] h_back;
    reg [10:0] h_total;
    reg [10:0] v_sync;
    reg [10:0] v_back;
    reg [10:0] v_total;
    reg [10:0] h_cnt;
    reg [10:0] v_cnt;
    
    //wire define
    wire lcd_en;
    
    //----------------------START------------------------//
    
    //DE mode
    assign lcd_hs  = 1'b1;
    assign lcd_vs  = 1'b1;
    assign lcd_rst = 1'b1;
    assign lcd_bl  = 1'b1;
    assign lcd_clk = lcd_pclk;
    assign lcd_de  = lcd_en;
    
    assign lcd_en = ((h_cnt >= h_sync + h_back)&&(h_cnt < h_sync + h_back + h_disp)
    &&(v_cnt >= v_sync + v_back)&&(v_cnt < v_sync + v_back + v_disp)) 
    ? 1'b1 : 1'b0;

    assign data_req = ((h_cnt >= h_sync + h_back - 1'b1)&&(h_cnt < h_sync + h_back + h_disp - 1'b1)
    &&(v_cnt >= v_sync + v_back)&&(v_cnt < v_sync + v_back + v_disp))
    ? 1'b1 : 1'b0;

    //zuobiao

    assign pixel_xpos = data_req ? (h_cnt - (h_sync + h_back - 1'b1)) : 11'd0;
    assign pixel_ypos = data_req ? (v_cnt - (v_sync + v_back - 1'b1)) : 11'd0;

    assign out_vsync = ((h_cnt <= 100) && (v_cnt == 1)) ? 1'b1 : 1'b0;

    //rgb888 data output
    assign lcd_rgb = lcd_en ? pixel_data : 24'd0;

    always @(posedge lcd_pclk ) begin
        case(lcd_id)
            16'h4342:begin
                h_sync <= H_SYNC_4342;
                h_back <= H_BACK_4342;
                h_disp <= H_DISP_4342;
                h_total <= H_TOTAL_4342;
                v_sync <= V_SYNC_4342;
                v_back <= V_BACK_4342;
                v_disp <= V_DISP_4342;
                v_total <= V_TOTAL_4342; 
            end 
            16'h4384:begin
                h_sync <= H_SYNC_4384;
                h_back <= H_BACK_4384;
                h_disp <= H_DISP_4384;
                h_total <= H_TOTAL_4384;
                v_sync <= V_SYNC_4384;
                v_back <= V_BACK_4384;
                v_disp <= V_DISP_4384;
                v_total <= V_TOTAL_4384; 
            end
            16'h7084:begin
                h_sync <= H_SYNC_7084;
                h_back <= H_BACK_7084;
                h_disp <= H_DISP_7084;
                h_total <= H_TOTAL_7084;
                v_sync <= V_SYNC_7084;
                v_back <= V_BACK_7084;
                v_disp <= V_DISP_7084;
                v_total <= V_TOTAL_7084; 
            end
            16'h7016:begin
                h_sync <= H_SYNC_7016;
                h_back <= H_BACK_7016;
                h_disp <= H_DISP_7016;
                h_total <= H_TOTAL_7016;
                v_sync <= V_SYNC_7016;
                v_back <= V_BACK_7016;
                v_disp <= V_DISP_7016;
                v_total <= V_TOTAL_7016; 
            end
            16'h1018:begin
                h_sync <= H_SYNC_1018;
                h_back <= H_BACK_1018;
                h_disp <= H_DISP_1018;
                h_total <= H_TOTAL_1018;
                v_sync <= V_SYNC_1018;
                v_back <= V_BACK_1018;
                v_disp <= V_DISP_1018;
                v_total <= V_TOTAL_1018; 
            end
            default:begin
                h_sync <= H_SYNC_4342;
                h_back <= H_BACK_4342;
                h_disp <= H_DISP_4342;
                h_total <= H_TOTAL_4342;
                v_sync <= V_SYNC_4342;
                v_back <= V_BACK_4342;
                v_disp <= V_DISP_4342;
                v_total <= V_TOTAL_4342; 
            end
        endcase
    end
    
    //hang cnt
    always @(posedge lcd_pclk or negedge rst_n) begin
        if(!rst_n)
            h_cnt <= 11'd0;
        else begin
            if(h_cnt == h_total - 1'b1)
                h_cnt <= 11'd0;
            else
                h_cnt <= h_cnt + 1'b1;
        end
    end

    //chang cnt
    always @(posedge lcd_pclk or negedge rst_n) begin
        if(!rst_n)
            v_cnt <= 11'd0;
        else begin
            if(h_cnt == h_total - 1'b1) begin
                if(v_cnt == v_total - 1'b1)
                    v_cnt <= 11'd0;
                else
                    v_cnt <= v_cnt + 1'b1;
            end
        end
    end

endmodule
