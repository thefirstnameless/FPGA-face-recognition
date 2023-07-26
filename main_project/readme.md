## ❥点击看I2C细节❥

1. 系统时钟为50MHz，i2c_clk是1MHz，i2c_dri里每4个i2c_clk周期sda改变一次，scl周期为250MHz
   
2. I2C在本工程中作用为初始化摄像头寄存器配置，并不承担数据的读（记得删除read，把800行代码缩减）
   
3. i2c_exec判定条件中有i2c_done，i2c_dri工作时i2c_exec竟然是0。所以i2c_cfg模块并非1μs给16位数据，而是每1μs查询i2c_done是否拉高
  
4. 以上都是骗人的

## ❥摄像头采集数据细节❥

1. 输入是摄像头的时钟，提供的信号为：cam_pclk,cam_vsync,cam_href,cam_data.

2. capture模块是通过byte_flag的翻转将两个8bit数据拼接成一个16bit数据。因为使用了D触发器拼接数据，所以byte_flag需要在打一拍。

3. tailor模块是将在lcd分辨率小于摄像头分辨率的情况时，只取摄像头中心一块放入lcd屏中。如果lcd分辨率更大就顺从摄像头的分辨率。

4. ![guomienasai](../cmos_time.png)

# Click to see I2C details Perso

1. The system clock is 50MHz, the i2c_clk is 1 MHZ, the sda of the i2c_dri is changed once every four i2c_clk periods, and the scl period is 250MHz

2. The function of I2C in this project is to initialize the configuration of camera registers, and it does not undertake data reading (remember to delete read and reduce 800 lines of code).

3. If i2c_done is included in the i2c_exec criteria, the value of i2c_exec is 0 when i2c_dri is working. Therefore, the i2c_cfg module does not give 1μs to 16 bits of data, but queries whether the i2c_done is higher every 1μs

4. The above are all lies