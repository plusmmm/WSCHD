////////////////////////////////////////////////////////////////
// Title: Top Unit for WonderSwan Color Video/Audio Capture
// Author: zwenergy
////////////////////////////////////////////////////////////////

import configPackage::*;
module topUnit
(
  input logic CLK_27MHZ,
  
  input logic dclk0,
  input logic dclk1,
  input logic hblank,
  input logic vblank,
  input logic[3:0] video0,
  input logic[3:0] video1,
  input logic[3:0] video2,
  input logic SDAT,
  input logic LRCK,
  input logic BCLK,
    input logic ARDCON,
  // 十字キー入力(キーパッドから受ける、押下=0)
  input logic key_up_in,
  input logic key_down_in,
  input logic key_left_in,
  input logic key_right_in,
  // 十字キー出力(WSC本体へ送る)
  output logic key_up_out,
  output logic key_down_out,
  output logic key_left_out,
  output logic key_right_out,
  output powerOut,
  output logic tmds_clk_p,
  output logic tmds_clk_n,
  output logic[2:0] tmds_p,
  output logic[2:0] tmds_n,
  output logic osd_open_out   // OSD開閉状態をRP2040へ
);

// Create clocks.
wire pxlClk, pxlClkx5, lock, rst;
wire clkoutd_dummy;
wire clkoutp_dummy;
assign rst = ~lock;

// Pxl Clock x5
rPLL pll_x5 (
    .CLKOUT(pxlClkx5),
    .CLKOUTP(clkoutp_dummy),
    .CLKOUTD(clkoutd_dummy),
    .LOCK(lock),
    .RESET(1'b0),
    .RESET_P(1'b0),
    .CLKIN(CLK_27MHZ),
    .CLKFB(1'b0),
    .FBDSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
    .IDSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
    .ODSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
    .PSDA({1'b0,1'b0,1'b0,1'b0}),
    .DUTYDA({1'b0,1'b0,1'b0,1'b0}),
    .FDLY({1'b0,1'b0,1'b0,1'b0})
);
defparam pll_x5.FCLKIN = "27";
defparam pll_x5.DYN_IDIV_SEL = "false";
defparam pll_x5.IDIV_SEL = IDIV_SEL_X5;
defparam pll_x5.DYN_FBDIV_SEL = "false";
defparam pll_x5.FBDIV_SEL = FBDIV_SEL_X5;
defparam pll_x5.DYN_ODIV_SEL = "false";
defparam pll_x5.ODIV_SEL = ODIV_SEL_X5;
defparam pll_x5.PSDA_SEL = "0000";
defparam pll_x5.DYN_DA_EN = "true";
defparam pll_x5.DUTYDA_SEL = DUTYDA_SEL_X5;
defparam pll_x5.CLKOUT_FT_DIR = 1'b1;
defparam pll_x5.CLKOUTP_FT_DIR = 1'b1;
defparam pll_x5.CLKOUT_DLY_STEP = 0;
defparam pll_x5.CLKOUTP_DLY_STEP = 0;
defparam pll_x5.CLKFB_SEL = "internal";
defparam pll_x5.CLKOUT_BYPASS = "false";
defparam pll_x5.CLKOUTP_BYPASS = "false";
defparam pll_x5.CLKOUTD_BYPASS = "false";
defparam pll_x5.DYN_SDIV_SEL = DYN_SDIV_SEL_X5;
defparam pll_x5.CLKOUTD_SRC = "CLKOUT";
defparam pll_x5.CLKOUTD3_SRC = "CLKOUT";
defparam pll_x5.DEVICE = "GW2AR-18C";

// Pxl Clock
CLKDIV clkdiv_inst (
    .CLKOUT(pxlClk),
    .HCLKIN(pxlClkx5),
    .RESETN(~rst),
    .CALIB(1'b0)
);
defparam clkdiv_inst.DIV_MODE = "5";
defparam clkdiv_inst.GSREN = "false";

wire[35:0] pxlToBuff, pxlFromBuff;
wire[13:0] pxlAddrWR, pxlAddrRD;
wire pxlWE;
videoCapture capInst ( .clk( pxlClk ), 
                    .rst( rst ), 
                    .dclk0( dclk0 ),
                    .dclk1( dclk1 ),
                    .hblank( hblank ),
                    .vblank( vblank ),
                    .video0( video0 ),
                    .video1( video1 ),
                    .video2( video2 ),
                    .pxlOut( pxlToBuff ),
                    .pxlAddr( pxlAddrWR ),
                    .pxlWE( pxlWE ) );

// Create the buffer.
bram_fb fb( .dout( pxlFromBuff ),
  .clka( pxlClk ),
  .cea( pxlWE ),
  .reseta( rst ),
  .clkb( pxlClk ),
  .ceb( 1'b1 ),
  .resetb( rst ),
  .oce( 1'b1 ),
  .ada( pxlAddrWR ),
  .din( pxlToBuff ),
  .adb( pxlAddrRD ) );

// Create Image part.
logic [2:0] tmds_int;
logic tmds_clk_int;
logic osd_open_int;   // imageGen から: OSDが開いているか

imageGen ig ( .pxlClk( pxlClk ),
              .pxlClkx5( pxlClkx5 ),
              .rst( rst ),
              .pxlData( pxlFromBuff ),
              .rotate( ARDCON ),
              .pxlAddr( pxlAddrRD ),
              .SDAT( SDAT ),
              .LRCK( LRCK ),
              .BCLK( BCLK ),
              .key_up_in( key_up_in ),
              .key_down_in( key_down_in ),
              .key_left_in( key_left_in ),
              .key_right_in( key_right_in ),
              .osd_open( osd_open_int ),
              .tmds_clk( tmds_clk_int ),
              .tmds_p( tmds_int ),
              .tmds_n( )
        );

// 十字キーのパススルー: OSD閉時はそのまま通す、OSD開時は非アクティブ(押されていない=1)に固定
assign key_up_out    = osd_open_int ? 1'b0 : key_up_in;
assign key_down_out  = osd_open_int ? 1'b0 : key_down_in;
assign key_left_out  = osd_open_int ? 1'b0 : key_left_in;
assign key_right_out = osd_open_int ? 1'b0 : key_right_in;

// ELVDS Buffers.
ELVDS_OBUF uut0(
.O(tmds_p[0]),
.OB(tmds_n[0]),
.I(tmds_int[0])
);

ELVDS_OBUF uut1(
.O(tmds_p[1]),
.OB(tmds_n[1]),
.I(tmds_int[1])
);

ELVDS_OBUF uut2(
.O(tmds_p[2]),
.OB(tmds_n[2]),
.I(tmds_int[2])
);

ELVDS_OBUF uutclk(
.O(tmds_clk_p),
.OB(tmds_clk_n),
.I(tmds_clk_int)
);

// Power control: 無効化 (手動でWSCをON/OFFするため、FPGAからは駆動しない)
assign powerOut = 1'bz;   // 常にHi-Z(開放)。WSCの電源に干渉しない
assign osd_open_out = osd_open_int;

endmodule