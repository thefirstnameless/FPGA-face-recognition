module rd_id(input clk,
             input rst_n,
             input [23:0] lcd_rgb,
             output reg [15:0] lcd_id);
    
    reg rd_flag;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            rd_flag <= 1'b0;
            lcd_id  <= 16'd0;
            end else
            begin
            if (rd_flag == 1'b0)begin
                rd_flag <= 1'b1;
                case({lcd_rgb[7],lcd_rgb[15],lcd_rgb[23]})
                    3'b000:lcd_id  <= 16'h4342;
                    3'b001:lcd_id  <= 16'h7084;
                    3'b010:lcd_id  <= 16'h7016;
                    3'b100:lcd_id  <= 16'h4384;
                    3'b101:lcd_id  <= 16'h1018;
                    default:lcd_id <= 16'd0;
                endcase
            end
        end
    end
    
    
endmodule
