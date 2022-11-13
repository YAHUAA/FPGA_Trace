module top
(
     input wire sys_clk              ,
	 input wire [7:0] cam_data       ,
	 input wire cam_href             ,
	 input wire cam_pclk             ,
	 input wire vsync                ,
	 input wire sys_rst_n            ,
									
	 output wire [12:0] sdram_addr   ,
	 output wire [1:0] sdram _ba     ,
	 output wire sdram_cas_n         ,
	 output wire sdram_cke_n         ,
	 output wire sdram_clk           ,
	 output wire sdram_cs_n          ,
	 output wire [15:0] sdram_data   ,
	 output wire [1:0] sdram_dqm     ,
	 output wire sdram_ras_n         ,
	 output wire sdram_we_n          ,
	 
	 output wire cam_scl             ,
	 output wire cam_sda             ,
	 output wire vga_hs              ,
	 output wire vga_vs              ,
	 output wire [15:0] vga_rgb      ;
	 
	 
)

wire ref_clk;
wire out_clk;
wire vag_clk;
wire locked;

wire rst_n;
wire comb;

assign rst_n = sys_rst_n & locked;
assign sys_init_done = init_done &  sdram_init_done;
assign comb = sys_init_done & rst_n;



pll_clk u_pll_clk
(
    .areset   (sys_rst_n), 
	.inclk    (sys_clk),
	.c0       (ref_clk),
	.c1       (out_clk),
    .c2       (vag_clk),
	.locked   (locked)
)

wire i2c_exec  
wire bit_ctrl  
wire i2c_rh_wl 
wire [15:0] i2c_addr  
wire [7:0] i2c_data_w
wire [7:0] i2c_data_r
wire i2c_done  
wire scl       
wire sda       
wire dri_clk

wire [15:0] i2c_data
assign i2c_addr = i2c_data[15:8];
assign i2c_data_w = i2c_data[7:0];

i2c_dri u_i2c_dri
(
     .  clk        (vag_clk),
	 .  rst_n      (rst_n),
				   
	 .  i2c_exec   (i2c_exec),
	 .  bit_ctrl   (1'h0),
	 .  i2c_rh_wl  (1'h0),
	 .  i2c_addr   (i2c_addr),
	 .  i2c_data_w (i2c_data_w),
	 .  i2c_data_r (),
	 .  i2c_done   (i2c_done),
	 .  scl        (cam_scl),
	 .  sda        (cam_sda),
				  
	 .  dri_clk    (dri_clk) 
)

i2c_ov_7725_rgb565_cfg u_i2c_cfg 
(
     .clk      (dri_clk),
	 .rst_n    (rst_n),
		
	 .i2c_done (i2c_done),
	 .i2c_exec (i2c_exec),
	 .i2c_data (i2c_data),
	 .init_done(init_done) 
	 
)

wire init_done ;  //ov7725初始化
wire sys_init_done;   //系统初始化
wire [15:0] wr_data1;
assign wr_data1 = {post_img_blue[7:3],post_img_green[7:2],post_img_red[7:3]};

sdram_top u_sdram_top 
(
     .ref_clk           (ref_clk),      
	 .out_clk           (out_clk),
	 .rst_n             (rst_n),
						
	 .wr_clk0           (cam_pclk),
	 .wr_en0            (YCbCr_frame_clken),
	 .wr_data0          (YCbCr_img_y_current),
	                 
	 .wr_clk1           (cam_pclk),
	 .wr_en1            (post_frame_clken),
	 .wr_data1          (wr_data1),
						
	 .wr_min_addr       (24'h0),
	 .wr_max_addr       (24'hd20),
	 .wr_len            (10'h1),
	 .wr_load           (rst_n),
						
	 .rd_clk0           (cam_pclk),
	 .rd_en0            (YCbCr_frame_clken),
	 .rd_data0          (YCbCr_img_y_pre),
						
	 .rd_clk1           (vag_clk),
	 .rd_en1            (data_req),
	 .rd_data1          (pixel_data),     //处理后的数据
						
	 .rd_min_addr       (24'h0),
	 .rd_max_addr       (24'hd20),
	 .rd_len            (10'h1),
	 .rd_load           (rst_n),
						
	 .sdram_read_valid  (1'h1),
	 .sdram_pingpang_en (1'h1),
	 .sdram_init_done   (sdram_init_done),
						
	 .sdram_clk         (sdram_clk),
	 .sdram_cke         (sdram_cke),
	 .sdram_cs_n        (sdram_cs_n),
	 .sdram_ras_n       (sdram_ras_n),
	 .sdram_cas_n       (sdram_cas_n),
	 .sdram_we_n        (sdram_we_n),
	 .sdram_ba          (sdram_ba),
	 .sdram_addr        (sdram_addr),
	 .sdram_data        (sdram_data),
	 .sdram_dqm         (sdram_dqm)
	 
)
 
 wire [15:0] cmos_frame_data;
 assign per_img_blue = {cmos_frame_data[2:4],cmos_frame_data[0:4]};
 assign per_img_green = {cmos_frame_data[9:10],cmos_frame_data[5:10]};
 assign per_img_red = cmos_frame_data   ;
 
cmos_capture_data u_cmos_capture_data(
        .            rst_n (comb)            //复位信号
                            //摄像头接口
        .            cam_pclk (cam_pclk)        //cmos 数据像素时钟
        .            cam_vsync (cam_vsync)       //cmos 场同步信号
        .            cam_href(cam_href)          //cmos 行同步信号
        .     cam_data      (cam_data)    //cmos 数据                             
           //用户接口
        .            cmos_frame_vsync(per_frame_vsync)  //帧有效信号    
        .            cmos_frame_href (per_frame_href)  //行有效信号
        .            cmos_frame_valid(per_frame_clken)  //数据有效使能信号
        .     cmos_frame_data (cmos_frame_data)   //有效数据        
    );



wire [7:0] YCbCr_img_y_current;
wire [7:0] YCbCr_img_y_pre;
wire YCbCr_frame_clken;

wire [15:0] wr_data1;
assign wr_data1 = {post_img_red[7:3],post_img_green[7:2],post_img_blue[7:3]}

wire post_frame_clken;
wire [7:0] per_img_red,per_img_green,per_img_blue;

Video_Image_Professor u_Video_Image_Professor
(
     .clk                  (cam_pclk),
	 .rst_n                (),
	 .Diff_Threshold       (8'h14),
	 .YCbCr_img_y_pre      (YCbCr_img_y_pre),
	 .per_frame_vsync      (per_frame_vsync),
	 .per_frame_href	   (per_frame_href),
	 .per_frame_clken      (per_frame_clken),
	 .per_img_red          (per_img_red),
	 .per_img_green	       (per_img_green),
	 .per_img_blue	       (per_img_blue),
	           
	 .YCbCr_img_y_current  (YCbCr_img_y_current),
	  
     .YCbCr_frame_clken    (YCbCr_frame_clken),	  
	 .post_frame_clken     (post_frame_clken),
     .post_img_blue        (post_img_blue),
     .post_img_green       (post_img_green),
     .post_img_red         (post_img_red)
	 
)
wire [15:0] pixel_data;
wire vga_hs;
wire vga_vs;
wire data_req;
wire [15:0] vga_rgb;
vga_driver(
      .        vga_clk   (vag_clk)      //VGA驱动时钟
      .        sys_rst_n (rst_n)      //复位信号
          
      .        vga_hs    (vga_hs)      //行同步信号
      .        vga_vs    (vga_vs)      //场同步信号
      .        vga_rgb   (vga_rgb)       //红 绿蓝三原色输出
	
      .  pixel_data      (pixel_data)       //像素点数据
      .  data_req        (data_req)      //请求像素点颜色数据输入 
      .  pixel_xpos      (pixel_xpos)      //像素点横坐标
      .  pixel_ypos      (pixel_ypos)       //像素点纵坐标    
    );             


endmodule 