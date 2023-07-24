module e2prom_rw (input clk,
                  input rst_n,
                  input i2c_ack,
                  input [7:0]i2c_data_r,
                  input i2c_done,
                  output reg [15:0]i2c_addr,
                  output reg [7:0]i2c_data_w,
                  output reg i2c_exec,        //I2C 触发执行信号
                  output reg i2c_rh_wl,       //I2C 读写控制信号
                  output reg rw_done,
                  output reg rw_result);
    parameter WR_WAIT_TIME = 14'd5000; //写入间隔时间
    parameter MAX_BYTE     = 16'd256 ; //读写测试的字节个�?
    
    //////////
    reg [1:0] flow_cnt;  //state contrl
    reg [13:0] wait_cnt; //延时
    
    /////先写再读，看看对不对
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i2c_addr   <= 16'd0 ;
            i2c_data_w <= 8'd0  ;
            i2c_exec   <= 1'd0  ;
            i2c_rh_wl  <= 1'd0  ;
            rw_done    <= 1'd0  ;
            rw_result  <= 1'd0  ;
            flow_cnt   <= 2'd0  ;
            wait_cnt   <= 14'd0 ;
        end
        else begin
            case (flow_cnt)
                2'd0: begin
                    wait_cnt <= wait_cnt +'d1 ;
                    if (wait_cnt == WR_WAIT_TIME -'d1) begin
                        wait_cnt <= 'd0 ;
                        if (i2c_addr == MAX_BYTE) begin
                            i2c_addr  <= 'd0 ;
                            i2c_rh_wl <= 1'd1 ;
                            flow_cnt  <= 2'd2 ;
                        end
                        else begin
                            flow_cnt <= 2'd1 ;
                            i2c_exec <= 1'd1 ;
                        end
                    end
                    
                end
                2'd1 : begin
                    if (i2c_done == 1'b1) begin //EEPROM 单次写入完成
                        flow_cnt   <= 2'd0;
                        i2c_addr   <= i2c_addr + 1'b1; //地址 0~255 分别写入.
                        i2c_data_w <= i2c_data_w + 1'b1; //.数据 0~255
                    end
                end
                2'd2 : begin
                    flow_cnt <= flow_cnt + 1'b1;
                    i2c_exec <= 1'b1;
                end
                2'd3 : begin
                    if (i2c_done == 1'b1) begin //EEPROM 单次读出完成
                        //读出的�?�错误或�? I2C 未应�?,读写测试失败
                        if ((i2c_addr[7:0] ! = i2c_data_r) || (i2c_ack == 1'b1)) begin
                            rw_done   <= 1'b1;
                            rw_result <= 1'b0;
                        end
                        else if (i2c_addr == MAX_BYTE - 1'b1) begin //读写测试成功
                            rw_done   <= 1'b1;
                            rw_result <= 1'b1;
                        end
                        else begin
                            flow_cnt <= 2'd2;
                            i2c_addr <= i2c_addr + 1'b1;
                        end
                    end
                end
                default:
            endcase
        end
        
        
    end
    
endmodule
