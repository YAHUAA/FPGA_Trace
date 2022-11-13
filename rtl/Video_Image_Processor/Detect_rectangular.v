module Detect_rectangular 
(
    input per_frame_clken
	input per_frame_herf
	input per_frame_vsync
	input per_img_bit
	input clk
	input rst

	
	output rect_flag
	output [9:0] rect_up
	output [9:0] rect_down
	output [9:0] rect_left
	output [9:0] rect_right
);

reg [9:0] reg_up,reg_down,reg_left,reg_right;

     wire href_dly,vsync_dly;
	 wire href_fall,vsync_fall;
     reg [9:0] up,down,left,right;
	 
	 reg [9:0] pos_x,pos_y;
	 
	 //per_frame_href的下降沿
	 always@(posedge clk)
	 href_dly <= per_frame_href;
	 
	 assign href_fall <= href_dly & (~per_frame_href);
	 
	 //per_frame_vsync的下降沿
	 always@(posedge clk)
	 vsync_dly <= per_frame_vsync;
	 
	 assign vsync_fall <= vsync_dly & (~per_frame_vsync);
	 
	 //pos_x
	 always@(posedge clk or negedge rst_n)
	 if(!rst_n) pos_x <= 0;
	 else if(per_frame_href == 1'b1 && per_frame_clken == 1'b1)  pos_x <= pos_x + 1'b1;
	 else if(href_fall == 1'b1) pos_x <= 10'd0;
	 else pos_x <= pos_x;
	 
	 //pos_y 
	 always@(posedge clk or negedge rst_n)
	 if(!rst_n ) pos_y <= 0;
     else if( href_fall == 1'b1) pos_y <= pos_y + 1'b1;
	 else if(vsync_fall == 1'b1) pos_y <= 10'd0;
	 else pos_y <= pos_y;
	
     //遍历一帧，寻找边界
	 always@(posedge clk)
	 if(per_img_bit == 1'b1) begin
	     up <= (pos_y < up)?pos_y:up;
		 down <= (pos_y > down)?pos_y:up;
		 left <= (pos_x < left)?pos_x:left;
		 right <= (pos_x > right)?pos_x:right;
	 end
	 else if(pos_x == 0 && pos_y == 0)
	 begin
	     up <= 9'd800;
		 down <= 9'd0;
		 right <= 9'd0;
		 left <=9'd700;
	 end
     else begin
	      up <= up;
		  down <= down;
		  right <= right;
		  left <= left;
	 end
     
	 assign rect_down = (per_frame_vsync == 1'b0)?down:rect_down;
	 assign rect_up = (per_frame_vsync == 1'b0)?up:rect_up;
	 assign rect_left = (per_frame_vsync == 1'b0)? left:rect_left;
	 assign rect_right = (per_frame_vsync == 1'b0)?right:rect_right;
	 
	 //rect_flag
	 always@(posedge clk or negedge rst_n)
	 if(!rst_n ) rect_flag <= 1'b0;
	 else if (vsync_fall == 1'b1) begin
	 if( left == 9'd800 && up == 9'd800) rect_flag <= 1'b0;
	 else rect_flag <= 1'b1;
	 end

