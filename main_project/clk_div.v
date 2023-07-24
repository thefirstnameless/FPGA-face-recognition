module clk_div(input clk,
               input rst_n,
               input [15:0] lcd_id,
               output reg lcd_pclk);
    
    reg clk_25m;
    reg clk_12_5m;
    reg div_4_cnt;
    //时钟 2 分频 输出 25MHz 时钟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_25m <= 1'b0;
        else
            clk_25m <= ~clk_25m;
    end
    
    
    //时钟 4 分频 输出 12.5MHz 时钟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_4_cnt <= 1'b0;
            clk_12_5m <= 1'b0;
        end
        else begin
            div_4_cnt <= div_4_cnt + 1'b1;
            if (div_4_cnt == 1'b1) begin
                clk_12_5m <= ~clk_12_5m;
            end
        end
    end
    
    always @(*) begin
        case(lcd_id)
            16'h4342 : lcd_pclk = clk_12_5m;
            16'h7084 : lcd_pclk = clk_25m;
            16'h7016 : lcd_pclk = clk;
            16'h4384 : lcd_pclk = clk_25m;
            16'h1018 : lcd_pclk = clk;
            default : lcd_pclk  = 1'b0;
        endcase
    end
    
endmodule
    
    
