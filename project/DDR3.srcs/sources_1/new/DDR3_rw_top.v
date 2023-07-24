module ddr3_rw (input ui_clk,                    //用户时钟
                input ui_clk_sync_rst,           //复位, 高有�?
                input init_calib_complete,       //DDR3 初始化完�?
                input app_rdy,                   //MIG 命令接收准备好标�?
                input app_wdf_rdy,               //MIG 数据接收准备�?
                input app_rd_data_valid,         //读数据有�?
                input [255:0] app_rd_data,       //用户读数�?
                output reg [27:0] app_addr,      //DDR3 地址
                output app_en,                   //MIG IP 发�?�命令使�?
                output app_wdf_wren,             //用户写数据使�?
                output app_wdf_end,              //突发写当前时钟最后一个数�?
                output [2:0] app_cmd,            //MIG IP 核操作命令，读或者写
                output reg [255:0] app_wdf_data, //用户写数�?
                output reg [1 :0] state,         //读写状�??
                output reg [23:0] rd_addr_cnt,   //用户读地�?计数
                output reg [23:0] wr_addr_cnt,   //用户写地�?计数
                output reg [20:0] rd_cnt,        //实际读地�?标记
                output reg error_flag,           //读写错误标志
                output reg led);                 //读写测试结果指示�?
    
    //parameter define
    parameter TEST_LENGTH = 1000;
    parameter L_TIME      = 25'd25_000_000;
    parameter IDLE        = 2'd0; //空闲状�??
    parameter WRITE       = 2'd1; //写状�?
    parameter WAIT        = 2'd2; //读到写过度等�?
    parameter READ        = 2'd3; //读状�?
    
    //reg define
    reg [24:0] led_cnt; //led 计数
    
    //wire define
    wire error; //读写错误标记
    wire rst_n; //复位，低有效
    
    //*****************************************************
    //** main code
    //*****************************************************
    assign rst_n = ~ui_clk_sync_rst;
    //读信号有效，且读出的数不是写入的数时，将错误标志位拉�?
    assign error = (app_rd_data_valid && (rd_cnt! = app_rd_data));
    
    //在写状�?�MIG IP 命令接收和数据接收都准备�?,或�?�在读状态命令接收准备好，此时拉高使能信号，
    assign app_en = ((state == WRITE && (app_rdy && app_wdf_rdy))
    ||(state == READ && app_rdy)) ? 1'b1:1'b0;
    
    //在写状�??,命令接收和数据接收都准备好，此时拉高写使�?
    assign app_wdf_wren = (state == WRITE && (app_rdy && app_wdf_rdy)) ? 1'b1:1'b0;
    
    //由于 DDR3 芯片时钟和用户时钟的分频选择 4:1，突发长度为 8，故两个信号相同
    assign app_wdf_end = app_wdf_wren;
    
    //处于读的时�?�命令�?�为 1，其他时候命令�?�为 0
    assign app_cmd = (state == READ) ? 3'd1 :3'd0;
    
    //DDR3 读写逻辑实现
    always @(posedge ui_clk or negedge rst_n) begin
        if ((~rst_n)||(error_flag)) begin
            state        <= IDLE;
            app_wdf_data <= 128'd0;
            wr_addr_cnt  <= 24'd0;
            rd_addr_cnt  <= 24'd0;
            app_addr     <= 28'd0;
            end
        else if (init_calib_complete)begin //MIG IP 核初始化完成
            case(state)
                IDLE:begin
                    state        <= WRITE;
                    app_wdf_data <= 256'd0;
                    wr_addr_cnt  <= 24'd0;
                    rd_addr_cnt  <= 24'd0;
                    app_addr     <= 28'd0;
                end
                WRITE:begin
                    if (wr_addr_cnt == TEST_LENGTH - 1 &&(app_rdy && app_wdf_rdy))
                        state <= WAIT; //写到设定的长度跳到等待状�?
                    else if (app_rdy && app_wdf_rdy)begin //写条件满�?
                        app_wdf_data <= app_wdf_data + 1; //写数据自�?
                        wr_addr_cnt  <= wr_addr_cnt + 1; //写地�?自加
                        app_addr     <= app_addr + 8; //DDR3 地址�? 8
                    end
                    else begin //写条件不满足，保持当前�??
                        app_wdf_data <= app_wdf_data;
                        wr_addr_cnt  <= wr_addr_cnt;
                        app_addr     <= app_addr;
                    end
                end
                WAIT:begin
                    state       <= READ; //下一个时钟，跳到读状�?
                    rd_addr_cnt <= 24'd0; //读地�?复位
                    app_addr    <= 28'd0; //DDR3 读从地址 0 �?�?
                end
                READ:begin //读到设定的地�?长度
                    if (rd_addr_cnt == TEST_LENGTH - 1 && app_rdy)
                        state <= IDLE; //则跳到空闲状�?
                    else if (app_rdy)begin //�? MIG 已经准备�?,则开始读
                        rd_addr_cnt <= rd_addr_cnt + 1'd1; //用户地址每次加一
                        app_addr    <= app_addr + 8; //DDR3 地址�? 8
                    end
                    else begin //�? MIG 没准备好,则保持原�?
                        rd_addr_cnt <= rd_addr_cnt;
                        app_addr    <= app_addr;
                    end
                end
                default:begin
                    state        <= IDLE;
                    app_wdf_data <= 256'd0;
                    wr_addr_cnt  <= 24'd0;
                    rd_addr_cnt  <= 24'd0;
                    app_addr     <= 28'd0;
                end
            endcase
        end
            end
            
            //�? DDR3 实际读数据个数编号计�?
            always @(posedge ui_clk or negedge rst_n) begin
                if (~rst_n)
                    rd_cnt <= 0; //若计数到读写长度，且读有效，地址计数器则�? 0
                else if (app_rd_data_valid && rd_cnt == TEST_LENGTH - 1)
                    rd_cnt <= 0; //其他条件只要读有效，每个时钟自增 1
                else if (app_rd_data_valid)
                    rd_cnt <= rd_cnt + 1;
                    end
                
                //寄存状�?�标志位
                always @(posedge ui_clk or negedge rst_n) begin
                    if (~rst_n)
                        error_flag <= 0;
                    else if (error)
                        error_flag <= 1;
                        end
                    
                    //led 指示效果控制
                    always @(posedge ui_clk or negedge rst_n) begin
                        if ((~rst_n) || (~init_calib_complete)) begin
                            led_cnt <= 25'd0;
                            led     <= 1'b0;
                            end
                        else begin
                            if (~error_flag) //读写测试正确
                                led <= 1'b1; //led 灯常�?
                            else begin //读写测试错误
                                led_cnt <= led_cnt + 25'd1;
                                if (led_cnt == L_TIME - 1'b1) begin
                                    led_cnt <= 25'd0;
                                    led     <= ~led; //led 灯闪�?
                                end
                            end
                        end
                    end
                    
                    endmodule
