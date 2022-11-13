/*-----------------------------------------------------------------------
								 \\\|///
							   \\  - -  //
								(  @ @  )
+-----------------------------oOOo-(_)-oOOo-----------------------------+
CONFIDENTIAL IN CONFIDENCE
This confidential and proprietary software may be only used as authorized
by a licensing agreement from CrazyBingo (Thereturnofbingo).
In the event of publication, the following notice is applicable:
Copyright (C) 2013-20xx CrazyBingo Corporation
The entire notice above must be reproduced on all authorized copies.
Author				:		CrazyBingo
Technology blogs 	: 		www.crazyfpga.com
Email Address 		: 		crazyfpga@vip.qq.com
Filename			:		Video_Image_Processor.v
Date				:		2013-05-26
Description			:		Video Image processor module.
Modification History	:
Date			By			Version			Change Description
=========================================================================
13/05/25		CrazyBingo	1.0				Original
14/03/16		CrazyBingo	2.0				Modification
-------------------------------------------------------------------------
|                                     Oooo								|
+-------------------------------oooO--(   )-----------------------------+
                               (   )   ) /
                                \ (   (_/
                                 \_)
-----------------------------------------------------------------------*/   

`timescale 1ns/1ns    //包含了边缘检测、腐蚀、膨胀
module Video_Image_Processor #(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)
(
	//global clock
	input				clk,  				//cmos video pixel clock
	input				rst_n,				//global reset

	//Image data prepred to be processd
	input				per_frame_vsync,	//Prepared Image data vsync valid signal
	input				per_frame_href,		//Prepared Image data href vaild  signal
	input				per_frame_clken,	//Prepared Image data output/capture enable clock
	input		[7:0]	per_img_red,		//Prepared Image red data to be processed
	input		[7:0]	per_img_green,		//Prepared Image green data to be processed
	input		[7:0]	per_img_blue,		//Prepared Image blue data to be processed

	//Image data has been processd
	output				post_frame_vsync,	//Processed Image data vsync valid signal
	output				post_frame_href,	//Processed Image data href vaild  signal
	output				post_frame_clken,	//Processed Image data output/capture enable clock
	output				post_img_Bit,		//Processed Image Bit flag outout(1: Value, 0:inValid)
	
	//user interface
	input		[7:0]	Sobel_Threshold		//Sobel Threshold for image edge detect	
);


//-------------------------------------
//Convert the RGB888 format to YCbCr444 format.
wire 		post0_frame_vsync;   
wire 		post0_frame_href ;   
wire 		post0_frame_clken;    
wire [7:0]	post0_img_Y      ;   
wire [7:0]	post0_img_Cb     ;   
wire [7:0]	post0_img_Cr     ;   

VIP_RGB888_YCbCr444	u_VIP_RGB888_YCbCr444
(
	//global clock
	.clk				(clk),					//cmos video pixel clock
	.rst_n				(rst_n),				//system reset

	//Image data prepred to be processd
	.per_frame_vsync	(per_frame_vsync),		//Prepared Image data vsync valid signal
	.per_frame_href		(per_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken	(per_frame_clken),		//Prepared Image data output/capture enable clock
	.per_img_red		(per_img_red),			//Prepared Image red data input
	.per_img_green		(per_img_green),		//Prepared Image green data input
	.per_img_blue		(per_img_blue),			//Prepared Image blue data input
	
	//Image data has been processd
	.post_frame_vsync	(post0_frame_vsync),		//Processed Image frame data valid signal
	.post_frame_href	(post0_frame_href),		//Processed Image hsync data valid signal
	.post_frame_clken	(post0_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Y			(post0_img_Y),			//Processed Image brightness output
	.post_img_Cb		(post0_img_Cb),			//Processed Image blue shading output
	.post_img_Cr		(post0_img_Cr)			//Processed Image red shading output
);

//--------------------------------------
//Image edge detector with Sobel.
wire			post1_frame_vsync;	//Processed Image data vsync valid signal
wire			post1_frame_href;	//Processed Image data href vaild  signal
wire			post1_frame_clken;	//Processed Image data output/capture enable clock
wire			post1_img_Bit;		//Processed Image Bit flag outout(1: Value, 0:inValid)
VIP_Sobel_Edge_Detector
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)
u_VIP_Sobel_Edge_Detector
(
	//global clock
	.clk					(clk),  				//cmos video pixel clock
	.rst_n					(rst_n),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync		(post0_frame_vsync),		//Prepared Image data vsync valid signal
	.per_frame_href			(post0_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken		(post0_frame_clken),		//Prepared Image data output/capture enable clock
	.per_img_Y				(post0_img_Y),			//Prepared Image brightness input

	//Image data has been processd
	.post_frame_vsync		(post1_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href		(post1_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken		(post1_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Bit			(post1_img_Bit),			//Processed Image Bit flag outout(1: Value, 0:inValid)
	
	//User interface
	.Sobel_Threshold		(Sobel_Threshold)					//Sobel Threshold for image edge detect
);


//--------------------------------------
//Bit Image Process with Erosion before Dilation Detector.
wire			post2_frame_vsync;	//Processed Image data vsync valid signal
wire			post2_frame_href;	//Processed Image data href vaild  signal
wire			post2_frame_clken;	//Processed Image data output/capture enable clock
wire			post2_img_Bit;		//Processed Image Bit flag outout(1: Value, 0:inValid)
VIP_Bit_Erosion_Detector
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)
u_VIP_Bit_Erosion_Detector
(
	//global clock
	.clk					(clk),  				//cmos video pixel clock
	.rst_n					(rst_n),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync		(post1_frame_vsync),	//Prepared Image data vsync valid signal
	.per_frame_href			(post1_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken		(post1_frame_clken),	//Prepared Image data output/capture enable clock
	.per_img_Bit			(post1_img_Bit),		//Processed Image Bit flag outout(1: Value, 0:inValid)

	//Image data has been processd
	.post_frame_vsync		(post2_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href		(post2_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken		(post2_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Bit			(post2_img_Bit)			//Processed Image Bit flag outout(1: Value, 0:inValid)
);


//--------------------------------------
//Bit Image Process with Dilation after Erosion Detector.
VIP_Bit_Dilation_Detector
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)
u_VIP_Bit_Dilation_Detector
(
	//global clock
	.clk					(clk),  				//cmos video pixel clock
	.rst_n					(rst_n),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync		(post2_frame_vsync),	//Prepared Image data vsync valid signal
	.per_frame_href			(post2_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken		(post2_frame_clken),	//Prepared Image data output/capture enable clock
	.per_img_Bit			(post2_img_Bit),		//Processed Image Bit flag outout(1: Value, 0:inValid)

	//Image data has been processd
	.post_frame_vsync		(post_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href		(post_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken		(post_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Bit			(post_img_Bit)			//Processed Image Bit flag outout(1: Value, 0:inValid)
);


endmodule
