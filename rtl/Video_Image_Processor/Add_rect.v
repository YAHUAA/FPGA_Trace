module Add_rect
(
    input wire clk                ,
	input wire rst                ,
	input wire per_frame_clken    ,
	input wire per_frame_href     ,
	input wire per_frame_vsync    ,
	input wire [7:0] per_img_blue       ,
	input wire [7:0] per_img_green      ,
	input wire [7:0] per_img_red        ,
	input wire rect_up            ,
	input wire rect_down          ,
	input wire rect_left          ,
	input wire rect_right         ,
	input wire rect_flag          ,
	input wire [9:0] x_pos        ,
	input wire [9:0] y_pos        ,
								  
	output wire post_frame_clken  ,
	output wire post_frame_href   ,
	output wire post_frame_vsync  ,
	output wire [7:0] post_img_blue     ,
	output wire [7:0] post_img_red      ,
	output wire [7:0] post_img_green    
	
)

parameter RECT = 0Xffffff;  //the color of the rect
parameter WIDTH =   4'd10;

assign rect_valid = (
((pos_x >= left-margin_width) &&(pos_x <=left)&&(pos_y >= top-margin_width)&&(pos_y <= bottom+margin_width))||
((pos_x >= right) &&(pos_x <=right + margin_width)&&(pos_y >= top-margin_width)&&(pos_y <= bottom+margin_width))||
((pos_y >= top-margin_width)&&(pos_y<=top)&&(pos_x>=left)&&(pos_x<= right))||
((pos_y <= bottom+margin_width)&&(pos_y>=bottom)&&(pos_x>=left)&&(pos_x<= right))
)?1'b1:1'b0;

assign post_img_red = (rect_valid == 1)? RECT : per_img_red;    
assign post_img_green = (rect_valid == 1)? RECT : per_img_green;
assign post_img_blue = (rect_valid == 1)? RECT : per_img_blue;




always@(posedge clk or negedge rst)
