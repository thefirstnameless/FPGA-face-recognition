

module i2c_dri #(parameter SLAVE_ADDR = 7'b1_010_000, //EEPROM从机地址
                 parameter CLK_FREQ = 26'd50_000_000, //模块输入的时钟频�?
                 parameter I2C_FREQ = 18'd250_000)
                (input i2c_exec,                       //I2C 触发执行信号
                 input [7:0]i2c_data_w,               //I2C 要写的数�??
                 input bit_ctrl,                      //器件地址位控�??(16b/8b)
                 input [15:0]i2c_addr,                //I2C 器件内地�??
                 input i2c_rh_wl,                     //I2C 读写控制信号
                 input clk,
                 input rst_n,
                 output i2c_done,                     //I2C �??次操作完�??
                 output dri_clk,
                 output i2c_ack,                      //I2C 应答标志
                 output scl,
                 inout sda,
                 output [7:0]i2c_data_r,              //I2C 要读的数�??
                 );
    //
    parameter [6:0]SLAVE_ADDR = 7'b1_010_000   ;  //EEPROM从机地址
    parameter BIT_CTRL        = 1'b1 ; //字地�?位控制参�?(16b/8b)
    
    parameter st_idle    = 3'b000;   //空闲
    parameter st_sladdr  = 3'b001;//发�?�控制命�??
    parameter st_addr16  = 3'b011;//先发送前八位地址
    parameter st_addr8   = 3'b010;//在发送后八位地址
    parameter st_data_wr = 3'b100;//从e2p写数�??
    parameter st_addr_rd = 3'b101;//读数据给e2p之前先给地址
    parameter st_data_rd = 3'b111;//读数据给e2p
    parameter st_stop    = 3'b110;//停止
    
    //
    
    reg sda_dir;  //设置sda方向，当sda_out输出信息时，sda_dir拉高
    reg sda_out;  //sda输出信号
    wire sda_in;   //输入信号
    reg [7:0] cur_state; //当前状�??
    reg [7:0] next_state; //下个状�??
    reg        st_done;  //zhuangtai完成标zhi?
    
    reg        wr_flag;   //临时寄存输入控制I2C的读写信�?
    reg [15:0] addr_t;    //临时寄存输入I2C的dizhi信号
    reg [7:0]  data_wr_t;  //临时寄存输入I2C的数据信�?

    reg [7:0]  data_r;  //临时存储E2PROM读入的数�?
    reg [7:0] cnt;  //状�?�内部计数器 
    
reg [2:0]current_state,next_state;

    //时钟分频
    wire [8:0]clk_div_coe;
    wire clk_cnt;
    wire clk_div;
    assign clk_div_coe = ((CLK_FREQ / I2C_FREQ)-2) / 2 ;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 'd0 ;
            clk_div <= 'd0 ;
        end
        else if (clk_cnt == ([8:0]clk_div_coe - 1)) begin
            clk_div <= ~clk_div ;
            clk_cnt <= 'd0 ;
        end
        else begin
            clk_cnt <= clk_cnt + 'd1 ;
        end
    end
//下面是三段式

    always @(posedge clk_div or negedge rst_n) begin  //第一段
        if (!rst_n) begin
            current_state <= st_idle ;
        end
        else begin
            current_state <= next_state ;
        end
    end
    
    always @(*) begin                               //第二段
        case (current_state)
            st_idle   : begin
                if (i2c_exec) begin
                    next_state = st_sladdr ;
                end
                else begin
                    next_state = st_idle ;
                end
            end
            st_sladdr :begin
                if (st_done)begin
                    if (bit_ctrl) begin
                        next_state = st_addr16 ;
                    end
                    else begin
                        next_state = st_addr8 ;
                    end
                    else begin
                        next_state = st_sladdr ;
                    end
                end
            end
            st_addr16 :begin
                if (st_done) begin
                    next_state = st_addr8 ;
                end
                else begin
                    next_state = st_addr16 ;
                end
            end
            st_addr8  :begin
                if (st_done) begin
                    if (wr_flag) begin
                        next_state = st_addr_rd ;
                    end
                    else begin
                        next_state = st_data_wr ;
                    end
                    else begin
                        next_state = st_addr8 ;
                    end
                end
            end
            st_data_wr: begin
                if (st_done) begin
                    next_state = st_stop ;
                end
                else begin
                    next_state = st_data_wr ;
                end
            end
            st_addr_rd:begin
                if (st_done) begin
                    next_state = st_data_rd ;
                end
                else begin
                    next_state = st_addr_rd ;
                end
            end
            st_data_rd:begin
                if (st_done) begin
                    next_state = st_stop ;
                end
                else begin
                    next_state = st_data_rd ;
                end
            end
            st_stop   : begin
                if (st_done) begin
                    next_state = st_idle ;
                end
                else begin
                    next_state = st_stop ;
                end
            end
            default: next_state = st_idle ;
        endcase
    end
    reg [7:0]st_cnt;

    //sda三态门处理
assign sda = sda_dir ? sda_out : 1'bz;  //sda_dir为高时，sda作为sda_out输出 sda_dir为低时，sda输出高阻
assign sda_in = sda; 

    always @(posedge clk_div or negedge rst_n) begin
        if (!rst_n) begin
            //接输出的
            i2c_done <= 'd0;
            sda_out <= 'd1;
            i2c_ack <= 'd0;
            scl     <= 'd1;
            sda_dir    <= 'd1;
            i2c_data_r <='d0;
            //输入接近来的
            wr_flag <= 'd0  ; 
            addr_t  <= 'd0  ;  
            data_wr_t <= 'd0;    
            //自己内部规定用的寄存器
            data_r <= 'd0 ;
            cnt <= 'd0 ;
            st_done <= 'd0 ;
        end
        else begin
            st_done <= 'd0 ;
            cnt <= cnt + 'd1 ;
            case (current_state)
                st_idle   :begin
                    i2c_done <= 'd0;
                    sda_out <= 'd1;
                    i2c_ack <= 'd0;
                    scl     <= 'd1;
                    sda_dir    <= 'd1;
                    i2c_data_r <='d0;

if (i2c_exec) begin
            wr_flag <= i2c_rh_wl  ; 
            addr_t  <= i2c_addr  ;  
            data_wr_t <= i2c_data_w; 
end

                end
                st_sladdr :begin
                    case (cnt)
                    7'd1 : sda_out <= 1'b0;         //反正也是自己规定的div_clk
                    7'd2 : scl <= 1'b0;
                    7'd3 : sda_out <= SLAVE_ADDR[6];
                    7'd4 : scl <= 1'b1;
                    7'd6 : scl <= 1'b0;
                    7'd7 : sda_out <= SLAVE_ADDR[5];
                    7'd8 : scl <= 1'b1;
                    7'd10: scl <= 1'b0;
                    7'd11: sda_out <= SLAVE_ADDR[4];
                    7'd12: scl <= 1'b1;
                    7'd14: scl <= 1'b0;
                    7'd15: sda_out <= SLAVE_ADDR[3];
                    7'd16: scl <= 1'b1;
                    7'd18: scl <= 1'b0;
                    7'd19: sda_out <= SLAVE_ADDR[2];
                    7'd20: scl <= 1'b1;
                    7'd22: scl <= 1'b0;
                    7'd23: sda_out <= SLAVE_ADDR[1];
                    7'd24: scl <= 1'b1;
                    7'd26: scl <= 1'b0;
                    7'd27: sda_out <= SLAVE_ADDR[0];
                    7'd28: scl <= 1'b1;
                    7'd30: scl <= 1'b0;
                    7'd31: sda_out <= 1'b0;  //7位器件地址后接一位写符号
                    7'd32: scl <= 1'b1;
                    7'd34: scl <= 1'b0;
                    7'd35: begin
                        sda_dir <= 1'b0;  //主机释放sda，sda作为输入接口
                        sda_out <= 1'b1;  //此时sda_out赋值无意义,只是防止出现未知X
                    end
                    7'd36: scl <= 1'b1;
                    7'd37: begin
                        st_done <= 1'b1;  //一次传输完成
                        if(sda_in == 1'b1)  //如果从机未应答，则拉高i2c_ack
                            i2c_ack <= 1'b1;
                    end
                    7'd38: begin
                        scl <= 1'b0;
                        cnt <= 7'd0;
                    end
                    default: ; 
                    endcase
                end
                st_addr16 :begin
                    case (cnt)
                    7'd0 : begin
                        sda_out <= addr_t[15];//因为cnt<=0和cur_state<=st_addr16一起
                        sda_dir <= 1'b1;  
                        end
                    7'd1 : scl <= 1'b1;
                    7'd3 : scl <= 1'b0;
                    7'd4 : sda_out <= addr_t[14];
                    7'd5 : scl <= 1'b1;
                    7'd7 : scl <= 1'b0;
                    7'd8 : sda_out <= addr_t[13];
                    7'd9 : scl <= 1'b1;
                    7'd11: scl <= 1'b0;
                    7'd12: sda_out <= addr_t[12];
                    7'd13: scl <= 1'b1;
                    7'd15: scl <= 1'b0;
                    7'd16: sda_out <= addr_t[11];
                    7'd17: scl <= 1'b1;
                    7'd19: scl <= 1'b0;
                    7'd20: sda_out <= addr_t[10];
                    7'd21: scl <= 1'b1;
                    7'd23: scl <= 1'b0;
                    7'd24: sda_out <= addr_t[9];
                    7'd25: scl <= 1'b1;
                    7'd27: scl <= 1'b0;
                    7'd28: sda_out <= addr_t[8];
                    7'd29: scl <= 1'b1;
                    7'd31: scl <= 1'b0; 
                    7'd32: begin
                        sda_dir <= 1'd0;
                        sda_out <= 1'd1;
                    end
                    7'd33: scl <= 1'b1; 
                    7'd34: begin
                        st_done <= 1'd1 ;
                        if (sda_in) begin
                            i2c_ack <= 1'd1;
                        end
                    end
                    7'd35: begin
                        scl <= 1'b0;
                        cnt <= 7'd0;
                    end 
                    default: ; 
                    
                    endcase
                end
                st_addr8  :begin
                    case (cnt)
                    7'd0 : begin
                        sda_out <= addr_t[7];//因为cnt<=0和cur_state<=st_addr16一起
                        sda_dir <= 1'b1;  
                        end
                    7'd1 : scl <= 1'b1;
                    7'd3 : scl <= 1'b0;
                    7'd4 : sda_out <= addr_t[6];
                    7'd5 : scl <= 1'b1;
                    7'd7 : scl <= 1'b0;
                    7'd8 : sda_out <= addr_t[5];
                    7'd9 : scl <= 1'b1;
                    7'd11: scl <= 1'b0;
                    7'd12: sda_out <= addr_t[4];
                    7'd13: scl <= 1'b1;
                    7'd15: scl <= 1'b0;
                    7'd16: sda_out <= addr_t[3];
                    7'd17: scl <= 1'b1;
                    7'd19: scl <= 1'b0;
                    7'd20: sda_out <= addr_t[2];
                    7'd21: scl <= 1'b1;
                    7'd23: scl <= 1'b0;
                    7'd24: sda_out <= addr_t[1];
                    7'd25: scl <= 1'b1;
                    7'd27: scl <= 1'b0;
                    7'd28: sda_out <= addr_t[0];
                    7'd29: scl <= 1'b1;
                    7'd31: scl <= 1'b0; 
                    7'd32: begin
                        sda_dir <= 1'd0;
                        sda_out <= 1'd1;
                    end
                    7'd33: scl <= 1'b1; 
                    7'd34: begin
                        st_done <= 1'd1 ;
                        if (sda_in) begin
                            i2c_ack <= 1'd1;
                        end
                    end
                    7'd35: begin
                        scl <= 1'b0;
                        cnt <= 7'd0;
                    end 
                        default:
                    endcase
                end
                st_data_wr:begin
                             
                case (cnt)
                    7'd0 : begin
                        sda_out <= data_wr_t[7];//因为cnt<=0和cur_state<=st_addr16一起
                        sda_dir <= 1'b1;  
                        end
                    7'd1 : scl <= 1'b1;
                    7'd3 : scl <= 1'b0;
                    7'd4 : sda_out <= data_wr_t[6];
                    7'd5 : scl <= 1'b1;
                    7'd7 : scl <= 1'b0;
                    7'd8 : sda_out <= data_wr_t[5];
                    7'd9 : scl <= 1'b1;
                    7'd11: scl <= 1'b0;
                    7'd12: sda_out <= data_wr_t[4];
                    7'd13: scl <= 1'b1;
                    7'd15: scl <= 1'b0;
                    7'd16: sda_out <= data_wr_t[3];
                    7'd17: scl <= 1'b1;
                    7'd19: scl <= 1'b0;
                    7'd20: sda_out <= data_wr_t[2];
                    7'd21: scl <= 1'b1;
                    7'd23: scl <= 1'b0;
                    7'd24: sda_out <= data_wr_t[1];
                    7'd25: scl <= 1'b1;
                    7'd27: scl <= 1'b0;
                    7'd28: sda_out <= data_wr_t[0];
                    7'd29: scl <= 1'b1;
                    7'd31: scl <= 1'b0; 
                    7'd32: begin
                        sda_dir <= 1'd0;
                        sda_out <= 1'd1;
                    end
                    7'd33: scl <= 1'b1; 
                    7'd34: begin
                        st_done <= 1'd1 ;
                        if (sda_in) begin
                            i2c_ack <= 1'd1;
                        end
                    end
                    7'd35: begin
                        scl <= 1'b0;
                        cnt <= 7'd0;
                    end  
                    default: 
                endcase
                end
                //end
                st_addr_rd:begin
                case (cnt)
                    7'd0 :begin
                        sda_dir <= 1'b1;
                        sda_out <= 1'b1;  //sda_out保持高电平
                    end
                    7'd1 : scl <= 1'b1;
                    7'd2 : sda_out <= 1'b0;  //scl为高时，sda_out 产生下降沿，传输重新开始 ////////////////?不是很明白这一块
                    7'd3 : scl <= 1'b0;
                    7'd4 : sda_out <= SLAVE_ADDR[6];
                    7'd5 : scl <= 1'b1;
                    7'd7 : scl <= 1'b0;
                    7'd8 : sda_out <= SLAVE_ADDR[5];
                    7'd9 : scl <= 1'b1;
                    7'd11: scl <= 1'b0;
                    7'd12: sda_out <= SLAVE_ADDR[4];
                    7'd13: scl <= 1'b1;
                    7'd15: scl <= 1'b0;
                    7'd16: sda_out <= SLAVE_ADDR[3];
                    7'd17: scl <= 1'b1;
                    7'd19: scl <= 1'b0;
                    7'd20: sda_out <= SLAVE_ADDR[2];
                    7'd21: scl <= 1'b1;
                    7'd23: scl <= 1'b0;
                    7'd24: sda_out <= SLAVE_ADDR[1];
                    7'd25: scl <= 1'b1;
                    7'd27: scl <= 1'b0;
                    7'd28: sda_out <= SLAVE_ADDR[0];
                    7'd29: scl <= 1'b1;
                    7'd31: scl <= 1'b0;
                    7'd32: sda_out <= 1'b1;  //7位器件地址后接一位读符号
                    7'd33: scl <= 1'b1;
                    7'd35: scl <= 1'b0;
                    7'd36: begin
                        sda_dir <= 1'b0;  //主机释放sda，sda作为输入接口
                        sda_out <= 1'b1;  //此时sda_out赋值无意义,只是防止出现未知X
                    end
                    7'd37: scl <= 1'b1;
                    7'd38: begin
                        st_done <= 1'b1;  //一次传输完成
                        if(sda_in == 1'b1)  //如果从机未应答，则拉高i2c_ack
                            i2c_ack <= 1'b1;
                    end
                    7'd39: begin
                        scl <= 1'b0;
                        cnt <= 7'd0;
                    end 
                    default: 
                endcase
                end
                st_data_rd:begin
                    case (cnt)
                    7'd0 : begin
                    sda_out <= 1'b0;         //反正也是自己规定的div_clk
                    end
                    7'd1: scl <= 1'b0;
                    7'd2: sda_out <= SLAVE_ADDR[6];
                    7'd3: scl <= 1'b1;
                    7'd4: scl <= 1'b0;
                    7'd5: sda_out <= SLAVE_ADDR[5];
                    7'd7: scl <= 1'b1;
                    7'd8: scl <= 1'b0;
                    7'd9: sda_out <= SLAVE_ADDR[4];
                    7'd: scl <= 1'b1;
                    7'd: scl <= 1'b0;
                    7'd: sda_out <= SLAVE_ADDR[3];
                    7'd: scl <= 1'b1;
                    7'd: scl <= 1'b0;
                    7'd: sda_out <= SLAVE_ADDR[2];
                    7'd: scl <= 1'b1;
                    7'd: scl <= 1'b0;
                    7'd: sda_out <= SLAVE_ADDR[1];
                    7'd: scl <= 1'b1;
                    7'd: scl <= 1'b0;
                    7'd: sda_out <= SLAVE_ADDR[0];
                    7'd: scl <= 1'b1;
                    7'd: scl <= 1'b0;
                    7'd: sda_out <= 1'b0;  //7位器件地址后接一位写符号
                    7'd: scl <= 1'b1;
                    7'd: scl <= 1'b0;
                    7'd: begin
                        sda_dir <= 1'b0;  //主机释放sda，sda作为输入接口
                        sda_out <= 1'b1;  //此时sda_out赋值无意义,只是防止出现未知X
                    end
                    7'd36: scl <= 1'b1;
                    7'd37: begin
                        st_done <= 1'b1;  //一次传输完成
                        if(sda_in == 1'b1)  //如果从机未应答，则拉高i2c_ack
                            i2c_ack <= 1'b1;
                    end
                    7'd38: begin
                        scl <= 1'b0;
                        cnt <= 7'd0;
                    end
                    default: ; 
                    endcase
                end
                st_stop   :begin
                case(cnt)
                    7'd0:begin
                        sda_dir <= 1'b1;
                        sda_out <= 1'b0;  //拉低sda_out，下一时钟产生上升沿结束I2C
                    end
                    7'd1: scl <= 1'b1;
                    7'd2: sda_out <= 1'b1;  //scl为高电平时，sda_out产生下降沿结束I2C
                    7'd15: st_done <= 1'b1;
                    7'd16: begin
                        cnt <= 7'd0;
                        i2c_done <= 1'b1;   //向上层模块传递I2C结束信号
                    end
                    default: ;
                endcase 
                default:
                end
            endcase

            end
    end
    
endmodule
