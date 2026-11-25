//-----------------------------------------------------------------------
//-- Title: Image Gen (Scalable 3-Stage Pipeline Architecture - Alignment Fixed)
//-- Author: zwenergy
//-----------------------------------------------------------------------
 
import configPackage::*;
module imageGen
(
  input logic pxlClk,
  input logic pxlClkx5,
  input logic rst,
  
  input logic[35:0] pxlData,
  output logic[13:0] pxlAddr,
  
  input logic rotate,
 
  // Audio
  input logic SDAT,
  input logic LRCK,
  input logic BCLK,
 
  // 十字キー入力(押下=0)
  input logic key_up_in,
  input logic key_down_in,
  input logic key_left_in,
  input logic key_right_in,
  // OSD開閉状態の出力(topUnitのパススルー制御用)
  output logic osd_open,
 
  output logic tmds_clk,
  output logic[2:0] tmds_p,
  output logic[2:0] tmds_n
);
 
// 表示領域・走査座標定数
localparam int CORRECTX = 2;
localparam int VP_START_X   = (FRAMEWIDTH - (SCALE * 224)) / 2;
localparam int VP_START_Y   = (FRAMEHEIGHT - (SCALE * 144)) / 2;
localparam int VP_END_X     = VP_START_X + (SCALE * 223);
localparam int VP_END_Y     = VP_START_Y + (SCALE * 144);
localparam int VP_START_ROT_X = (FRAMEWIDTH - (SCALEROT * 144)) / 2;
localparam int VP_START_ROT_Y = (FRAMEHEIGHT - (SCALEROT * 224)) / 2;
localparam int VP_END_ROT_X   = VP_START_ROT_X + (SCALEROT * 143); // 回転時の右端境界（赤い線）をカット
localparam int VP_END_ROT_Y   = VP_START_ROT_Y + (SCALEROT * 224);
localparam int WINDOW_END_X   = VP_START_X + (COLLEN * 3 * SCALE);
localparam int WINDOW_END_Y   = FRAMEHEIGHT;
localparam int WINDOW_END_ROT_X = VP_START_ROT_X + (150 * SCALEROT);
 
localparam bit [10:0] VP_S_X_P2   = 11'(VP_START_X + CORRECTX);
localparam bit [10:0] VP_E_X_P2   = 11'(VP_END_X + CORRECTX);
localparam bit [10:0] VP_S_R_X_P2 = 11'(VP_START_ROT_X + CORRECTX);
localparam bit [10:0] VP_E_R_X_P2 = 11'(VP_END_ROT_X + CORRECTX);
localparam bit [10:0] WD_E_X_P1   = 11'(WINDOW_END_X + 1);
 
// OSD レイアウト定数 (文字32x32, 8行: タイトル+6項目+ショップ名)
localparam int OSD_CHAR_W = 32;          // 文字幅(4倍)
localparam int OSD_CHAR_H = 32;          // 文字高さ(4倍)
localparam int OSD_ROW_PITCH = 44;       // 行ピッチ
localparam int OSD_W = 896;              // メニュー領域 横幅
localparam int OSD_H = 580;              // メニュー領域 縦幅 (9項目対応で拡張)
localparam int OSD_X = (1280 - OSD_W) / 2;   // 左上X (=360)
localparam int OSD_Y = (720  - OSD_H) / 2;   // 左上Y (=130)
// 各行の上端Y (OSD_Y からの絶対座標)
localparam int OSD_ROW0_Y = OSD_Y + 24;              // タイトル
localparam int OSD_ITEM0_Y = OSD_Y + 24 + 60;        // 項目0開始
localparam int OSD_SHOP_Y = OSD_Y + OSD_H - 56;      // ショップ名
localparam [4:0] VALUE_COL = 5'd11;                  // 値表示の開始文字位置(ラベル後)
 
// 内部走査・アドレス線
logic [23:0] rgb;
logic [23:0] con_pixel;          // contrast適用後(Stage2.5a出力)
logic [23:0] bri_pixel;          // brightness適用後(Stage2.5b出力)
logic [23:0] sat_in_pixel;       // 彩度入力(2.5c: bri_pixelを1段保持)
logic [7:0]  sat_y;              // 輝度Y(2.5c出力)
logic [23:0] sat_pixel;          // saturation適用後(Stage2.5d出力)
logic [23:0] gam_pixel;          // gamma適用後(Stage2.5e出力)
logic [23:0] adj_pixel;          // fx適用後(Stage2.5f出力, 最終)
logic viewport_area_p3, viewport_area_p4, viewport_area_p5, viewport_area_p6, viewport_area_p7, viewport_area_p8;
logic grid_line_p3, grid_line_p4, grid_line_p5, grid_line_p6, grid_line_p7, grid_line_p8;
logic [9:0] cy, frameHeight;
logic [10:0] cx, frameWidth;
logic [13:0] pxlAddrReg;
logic [8:0] lineCntPxl;
logic [2:0] colCnt, colCnt_del;
// pixel grid 用
logic [2:0] grid_mode = 3'd2;            // 0:暗強 1:暗弱 2:OFF 3:明弱 4:明強 (中央=OFF)
logic grid_line_p1, grid_line_p2;        // 境界線かどうか(2段遅延でrgbに同期)
 
// OSD 状態
logic osd_open_r = 1'b0;                 // OSDが開いているか
logic [3:0] osd_sel = 4'd0;              // 選択中の項目 0..8
logic [7:0] osd_auto_cnt = 8'd0;   // OSD自動移動用(デバッグ)
logic [2:0] scanline_mode = 3'd0;        // スキャンライン 0:OFF 1:25% 2:50% 3:75% 4:100%
logic [3:0] brightness = 4'd8;           // 明るさ 0..15 (中央8)
logic [3:0] contrast   = 4'd8;           // コントラスト 0..15 (中央8)
logic [3:0] saturation = 4'd8;           // 彩度 0..15 (中央8)
logic [3:0] color_temp = 4'd8;           // 色温度 0..15 (中央8)
logic invert_mode    = 1'b0;             // 色反転 OFF/ON
logic grayscale_mode = 1'b0;             // グレースケール OFF/ON
logic sepia_mode     = 1'b0;             // セピア OFF/ON
assign osd_open = osd_open_r;
 
// 十字キー 同期化とエッジ検出 (押下=0 → 押された瞬間に1パルス)
logic ku0,ku1,ku2, kd0,kd1,kd2, kl0,kl1,kl2, kr0,kr1,kr2;
logic key_up_edge, key_down_edge, key_left_edge, key_right_edge;
 
logic [13:0] lineBase;
logic [23:0] latestPixel;
logic [7:0] lineCntAbs, lineCntRel;
logic [3:0] scaleCntX, scaleCntY;
 
// 音声処理用バッファ
logic [15:0] audioL, audioR, audioLBuff, audioRBuff;
logic audioValidL, audioValidR;
localparam int AUDIOCLKMAXCNT = (CLKFRQ / 48);
logic [$clog2(AUDIOCLKMAXCNT)-1:0] audioCnt;
logic audioClk;
 
// 1ボタン操作ステート
logic sys_mode = 1'b0; 
logic rotate_int;
logic [19:0] btn_debounce;
logic rotate_sync_0, rotate_sync_1, rotate_sync_2;
logic rotate_edge;
 
logic [7:0] press_cnt;                  // フレーム単位の押下カウンタ
localparam int LONGPRESS = 8'd60;       // 60フレーム ≒ 1秒 (60Hz)
logic long_fired;
logic cy_zero_prev;                     // 前サイクルの cy==0 状態(フレームエッジ検出用)
logic frame_tick;                       // 1フレームに1パルス
 
assign pxlAddr = pxlAddrReg;
assign rotate_int = sys_mode;
 
// --- 拡張用パイプライン信号線の定義 ---
// Pipeline Stage 1 (1クロック遅延)
logic viewport_area_p1;
 
// Pipeline Stage 2 (2クロック遅延 - OSDのBRAM出力タイミングに完全同期)
logic viewport_area_p2;
logic [23:0] game_pixel_p2;
 
// Audio クロックおよびバッファ制御
always_ff @(posedge pxlClk) begin
  if (rst) begin
    audioCnt   <= '0;
    audioClk   <= 1'b0;
    audioLBuff <= '0;
    audioRBuff <= '0;
  end else begin
    if (audioCnt == AUDIOCLKMAXCNT - 1)
      audioCnt <= '0;
    else
      audioCnt <= audioCnt + 1'b1;
 
    audioClk <= (audioCnt >= AUDIOCLKMAXCNT / 2);
    if (audioValidL) audioLBuff <= audioL >>> 2;
    if (audioValidR) audioRBuff <= audioR >>> 2;
  end
end
 
// フレーム先頭(cy==0)を1パルス化
always_ff @(posedge pxlClk) begin
  if (rst) begin
    cy_zero_prev <= 1'b0;
    frame_tick   <= 1'b0;
  end else begin
    cy_zero_prev <= (cy == 10'd0);
    frame_tick   <= (cy == 10'd0) && !cy_zero_prev;  // 立ち上がりのみ
  end
end
 
// 十字キーの同期化とエッジ検出 (押下=0、押された瞬間に1パルス)
always_ff @(posedge pxlClk) begin
  if (rst) begin
    ku0<=1'b1; ku1<=1'b1; ku2<=1'b1;
    kd0<=1'b1; kd1<=1'b1; kd2<=1'b1;
    kl0<=1'b1; kl1<=1'b1; kl2<=1'b1;
    kr0<=1'b1; kr1<=1'b1; kr2<=1'b1;
  end else begin
    ku0<=key_up_in;    ku1<=ku0; ku2<=ku1;
    kd0<=key_down_in;  kd1<=kd0; kd2<=kd1;
    kl0<=key_left_in;  kl1<=kl0; kl2<=kl1;
    kr0<=key_right_in; kr1<=kr0; kr2<=kr1;
  end
end
// 押された瞬間(1→0の立ち下がり)を検出
assign key_up_edge    = (ku2 == 1'b1) && (ku1 == 1'b0);
assign key_down_edge  = (kd2 == 1'b1) && (kd1 == 1'b0);
assign key_left_edge  = (kl2 == 1'b1) && (kl1 == 1'b0);
assign key_right_edge = (kr2 == 1'b1) && (kr1 == 1'b0);
 
// ボタン: 短押し=回転 / 長押し=OSD開閉トグル。OSD開時は十字キーでメニュー操作 (押下=0極性、フレーム単位)
always_ff @(posedge pxlClk) begin
  if (rst) begin
    rotate_sync_0 <= 1'b1;
    rotate_sync_1 <= 1'b1;
    rotate_sync_2 <= 1'b1;
    sys_mode      <= 1'b0;
    grid_mode     <= 3'd2;
    press_cnt     <= '0;
    long_fired    <= 1'b0;
    osd_open_r    <= 1'b0;
    osd_sel       <= 4'd0;
    scanline_mode <= 3'd0;
    brightness    <= 4'd8;
    contrast      <= 4'd8;
    saturation    <= 4'd8;
    color_temp    <= 4'd8;
    invert_mode    <= 1'b0;
    grayscale_mode <= 1'b0;
    sepia_mode     <= 1'b0;
  end else begin
    rotate_sync_0 <= rotate;
    rotate_sync_1 <= rotate_sync_0;
    rotate_sync_2 <= rotate_sync_1;
 
    // PSボタン(押下=0)
    if (!rotate_sync_2) begin
      if (frame_tick) begin
        if (press_cnt < LONGPRESS) begin
          press_cnt <= press_cnt + 1'b1;
        end else if (!long_fired) begin
          osd_open_r <= ~osd_open_r;   // 長押し成立: OSD開閉トグル
          long_fired <= 1'b1;
        end
      end
    end else begin
      if (press_cnt > 8'd2 && press_cnt < LONGPRESS && !long_fired) begin
        sys_mode <= ~sys_mode;         // 短押し: 回転
      end
      press_cnt  <= '0;
      long_fired <= 1'b0;
    end
 
    // OSD開時の十字キー操作
    if (osd_open_r) begin
      // === デバッグ: 自動移動/自動変動 (実機十字キー確認のため無効化) ===
      // if (frame_tick) begin
      //   if (osd_auto_cnt >= 8'd59) begin
      //     osd_auto_cnt <= 8'd0;
      //     osd_sel    <= (osd_sel == 3'd5) ? 3'd0 : osd_sel + 1'b1;
      //   end else begin
      //     osd_auto_cnt <= osd_auto_cnt + 1'b1;
      //   end
      // end
      // === デバッグここまで ===
 
      // 上下: 項目選択 (0..8 を循環)
      if (key_up_edge) begin
        osd_sel <= (osd_sel == 4'd0) ? 4'd8 : osd_sel - 1'b1;
      end else if (key_down_edge) begin
        osd_sel <= (osd_sel == 4'd8) ? 4'd0 : osd_sel + 1'b1;
      end
 
      // 左右: 選択中項目の値変更
      if (key_left_edge) begin
        case (osd_sel)
          4'd0: if (grid_mode != 3'd0) grid_mode <= grid_mode - 1'b1;
          4'd1: scanline_mode <= (scanline_mode == 3'd0) ? 3'd4 : scanline_mode - 1'b1;
          4'd2: if (brightness > 4'd1) brightness <= brightness - 1'b1;
          4'd3: if (contrast   > 4'd1) contrast   <= contrast   - 1'b1;
          4'd4: if (saturation > 4'd1) saturation <= saturation - 1'b1;
          4'd5: if (color_temp > 4'd1) color_temp <= color_temp - 1'b1;
          4'd6: invert_mode    <= ~invert_mode;
          4'd7: grayscale_mode <= ~grayscale_mode;
          4'd8: sepia_mode     <= ~sepia_mode;
        endcase
      end else if (key_right_edge) begin
        case (osd_sel)
          4'd0: if (grid_mode != 3'd4) grid_mode <= grid_mode + 1'b1;
          4'd1: scanline_mode <= (scanline_mode == 3'd4) ? 3'd0 : scanline_mode + 1'b1;
          4'd2: if (brightness != 4'd15) brightness <= brightness + 1'b1;
          4'd3: if (contrast   != 4'd15) contrast   <= contrast   + 1'b1;
          4'd4: if (saturation != 4'd15) saturation <= saturation + 1'b1;
          4'd5: if (color_temp != 4'd15) color_temp <= color_temp + 1'b1;
          4'd6: invert_mode    <= ~invert_mode;
          4'd7: grayscale_mode <= ~grayscale_mode;
          4'd8: sepia_mode     <= ~sepia_mode;
        endcase
      end
    end
  end
end
 
assign rotate_edge = rotate_sync_2 & ~rotate_sync_1;
 
// ピクセルデータサンプリング (元の1段版に戻す)
always_ff @(posedge pxlClk) begin
  colCnt_del <= colCnt;
  case (colCnt_del)
    3'd0: latestPixel <= {pxlData[35:32], 4'b0, pxlData[31:28], 4'b0, pxlData[27:24], 4'b0};
    3'd1: latestPixel <= {pxlData[23:20], 4'b0, pxlData[19:16], 4'b0, pxlData[15:12], 4'b0};
    default: latestPixel <= {pxlData[11:8], 4'b0, pxlData[7:4], 4'b0, pxlData[3:0], 4'b0};
  endcase
end
 
// --- Pipeline Stage 1 & 2: 完全同期マルチステージ処理 ---
always_ff @(posedge pxlClk) begin
  if (rst) begin
    viewport_area_p1   <= 1'b0;
    viewport_area_p2   <= 1'b0;
    game_pixel_p2      <= 24'd0;
    grid_line_p1       <= 1'b0;
    grid_line_p2       <= 1'b0;
  end else begin
    // Stage 1
    if (!rotate_int) begin
      viewport_area_p1 <= (cx > VP_S_X_P2 && cx <= VP_E_X_P2 && cy > VP_START_Y && cy <= VP_END_Y);
    end else begin
      viewport_area_p1 <= (cx > VP_S_R_X_P2 && cx <= VP_E_R_X_P2 && cy > VP_START_ROT_Y && cy <= VP_END_ROT_Y);
    end
    // 実ピクセル境界(拡大ブロックの先頭ドット)を線とする
    grid_line_p1       <= (scaleCntX == '0) || (scaleCntY == '0);
 
    // Stage 2
    viewport_area_p2   <= viewport_area_p1;
    game_pixel_p2      <= latestPixel;
    grid_line_p2       <= grid_line_p1;
  end
end
 
// --- Stage 2.5a: contrast / Stage 2.5b: brightness ---
// brightness: 中央8=無変化, 1段 ±16, 飽和
function [7:0] sat_add(input [7:0] c, input signed [9:0] off);
  logic signed [10:0] s;
  begin
    s = $signed({1'b0, c}) + off;
    if (s < 0)             sat_add = 8'h00;
    else if (s > 11'sd255) sat_add = 8'hFF;
    else                   sat_add = s[7:0];
  end
endfunction
 
// contrast: out = 128 + (in-128)*contrast/8, 飽和 (8で無変化)
function [7:0] con_px(input [7:0] c, input [3:0] k);
  logic signed [11:0] d;
  logic signed [16:0] m;
  logic signed [12:0] r;
  begin
    d = $signed({1'b0, c}) - 12'sd128;
    m = d * $signed({1'b0, k});
    r = (m >>> 3) + 13'sd128;
    if (r < 0)             con_px = 8'h00;
    else if (r > 13'sd255) con_px = 8'hFF;
    else                   con_px = r[7:0];
  end
endfunction
 
// gamma 1色適用: 中間調を持ち上げ/沈め。g=gamma-8 (±7)。off=g*(128-|c-128|)>>6
function [7:0] gam_px(input [7:0] c, input signed [4:0] g);
  logic [7:0]  gdist;      // |c-128|
  logic [7:0]  gmid;       // 128-gdist (中間調で最大)
  logic signed [13:0] off;
  logic signed [9:0]  r;
  begin
    gdist = (c >= 8'd128) ? (c - 8'd128) : (8'd128 - c);
    gmid  = 8'd128 - gdist;
    off   = (g * $signed({1'b0, gmid})) >>> 3;
    r     = $signed({1'b0, c}) + off;
    if (g == 5'sd0)        gam_px = c;       // g=0は厳密にc(無変化保証)
    else if (r < 0)        gam_px = 8'h00;
    else if (r > 10'sd255) gam_px = 8'hFF;
    else                   gam_px = r[7:0];
  end
endfunction
 
// saturation 1色適用: out = y + (c-y)*k/8。k=8で厳密にc(丸め誤差を出さない)
function [7:0] sat_px(input [7:0] c, input [7:0] y, input [3:0] k);
  logic signed [9:0]  d;
  logic signed [14:0] m;
  logic signed [11:0] r;
  begin
    d = $signed({1'b0, c}) - $signed({1'b0, y});
    m = d * $signed({1'b0, k});
    // 負方向の切り捨て偏りを除くため、負のとき +7 してから算術シフト(対称丸め)
    r = ((m + (m[14] ? 15'sd7 : 15'sd0)) >>> 3) + $signed({1'b0, y});
    if (k == 4'd8)         sat_px = c;       // 無変化を厳密保証
    else if (r < 0)        sat_px = 8'h00;
    else if (r > 12'sd255) sat_px = 8'hFF;
    else                   sat_px = r[7:0];
  end
endfunction
 
logic signed [9:0] bright_off;
always_comb bright_off = ($signed({1'b0, brightness}) - 10'sd8) * 10'sd16;
 
logic signed [4:0] gamma_g;
always_comb gamma_g = $signed({1'b0, color_temp}) - 5'sd8;  // color_tempレジスタをgammaとして流用
 
// グレースケール/セピア/反転を適用 (gray→sepia→invertの順)
function [23:0] fx_apply(input [23:0] px, input gray, input sepia, input inv);
  logic [7:0]  r, g, b;
  logic [7:0]  y;
  logic [12:0] ysum;
  logic [15:0] sr, sg, sb;
  begin
    r = px[23:16]; g = px[15:8]; b = px[7:0];
    // グレースケール or セピアは輝度Yを使う
    ysum = 13'(r) * 13'd5 + 13'(g) * 13'd9 + 13'(b) * 13'd2;  // (R*5+G*9+B*2)
    y = ysum[11:4];                                            // /16
    if (sepia) begin
      // セピア: Yに固定色比 (R:G:B ≒ 1.0:0.79:0.55)
      sr = 16'(y) * 16'd16;  sr = sr >> 4;             // ×1.00
      sg = 16'(y) * 16'd13;  sg = sg >> 4;             // ×0.81
      sb = 16'(y) * 16'd9;   sb = sb >> 4;             // ×0.56
      r = (sr > 16'd255) ? 8'hFF : sr[7:0];
      g = (sg > 16'd255) ? 8'hFF : sg[7:0];
      b = (sb > 16'd255) ? 8'hFF : sb[7:0];
    end else if (gray) begin
      r = y; g = y; b = y;
    end
    if (inv) begin r = 8'hFF - r; g = 8'hFF - g; b = 8'hFF - b; end
    fx_apply = {r, g, b};
  end
endfunction
 
always_ff @(posedge pxlClk) begin
  if (rst) begin
    con_pixel        <= 24'd0;
    bri_pixel        <= 24'd0;
    sat_in_pixel     <= 24'd0;
    sat_y            <= 8'd0;
    sat_pixel        <= 24'd0;
    gam_pixel        <= 24'd0;
    adj_pixel        <= 24'd0;
    viewport_area_p3 <= 1'b0;
    viewport_area_p4 <= 1'b0;
    viewport_area_p5 <= 1'b0;
    viewport_area_p6 <= 1'b0;
    viewport_area_p7 <= 1'b0;
    viewport_area_p8 <= 1'b0;
    grid_line_p3     <= 1'b0;
    grid_line_p4     <= 1'b0;
    grid_line_p5     <= 1'b0;
    grid_line_p6     <= 1'b0;
    grid_line_p7     <= 1'b0;
    grid_line_p8     <= 1'b0;
  end else begin
    // Stage 2.5a: contrast
    con_pixel <= { con_px(game_pixel_p2[23:16], contrast),
                   con_px(game_pixel_p2[15:8],  contrast),
                   con_px(game_pixel_p2[7:0],   contrast) };
    viewport_area_p3 <= viewport_area_p2;
    grid_line_p3     <= grid_line_p2;
 
    // Stage 2.5b: brightness
    bri_pixel <= { sat_add(con_pixel[23:16], bright_off),
                   sat_add(con_pixel[15:8],  bright_off),
                   sat_add(con_pixel[7:0],   bright_off) };
    viewport_area_p4 <= viewport_area_p3;
    grid_line_p4     <= grid_line_p3;
 
    // Stage 2.5c: 輝度Y計算のみ (R*5+G*9+B*2)/16
    sat_in_pixel <= bri_pixel;
    sat_y <= 8'(( 13'(bri_pixel[23:16]) * 13'd5
                + 13'(bri_pixel[15:8])  * 13'd9
                + 13'(bri_pixel[7:0])   * 13'd2 ) >> 4);
    viewport_area_p5 <= viewport_area_p4;
    grid_line_p5     <= grid_line_p4;
 
    // Stage 2.5d: 彩度適用 (k=8は素通り、それ以外のみ演算)
    if (saturation == 4'd8)
      sat_pixel <= sat_in_pixel;
    else
      sat_pixel <= { sat_px(sat_in_pixel[23:16], sat_y, saturation),
                     sat_px(sat_in_pixel[15:8],  sat_y, saturation),
                     sat_px(sat_in_pixel[7:0],   sat_y, saturation) };
    viewport_area_p6 <= viewport_area_p5;
    grid_line_p6     <= grid_line_p5;
 
    // Stage 2.5e: gamma適用 (g=0は素通り)
    if (gamma_g == 5'sd0)
      gam_pixel <= sat_pixel;
    else
      gam_pixel <= { gam_px(sat_pixel[23:16], gamma_g),
                     gam_px(sat_pixel[15:8],  gamma_g),
                     gam_px(sat_pixel[7:0],   gamma_g) };
    viewport_area_p7 <= viewport_area_p6;
    grid_line_p7     <= grid_line_p6;
 
    // Stage 2.5f: グレースケール → セピア → 反転 (最終)
    adj_pixel <= fx_apply(gam_pixel, grayscale_mode, sepia_mode, invert_mode);
    viewport_area_p8 <= viewport_area_p7;
    grid_line_p8     <= grid_line_p7;
  end
end
 
// --- Pipeline Stage 3: HDMI最終出力段 (grid合成 + OSD枠) ---
// OSD領域・選択行ハイライトの判定 (cx/cy は2段前なので簡易に現座標で判定)
logic osd_in_area;
logic osd_in_sel_row;
logic [3:0] osd_row_idx;   // メニュー領域内で今どの項目行か
 
// === OSD 文字描画 ===
logic [6:0] osd_ascii;        // 今の文字位置のASCIIコード
logic [2:0] osd_font_row;     // フォント内の行(0..7)
logic [7:0] osd_font_bits;    // font_rom 出力
logic [2:0] osd_char_col;     // 行内の文字位置(0..)
logic [2:0] osd_bit_x;        // 文字内のXビット(0..7)
logic osd_text_on;            // この座標が文字(白)か
logic osd_textcol_valid;      // 文字カラム有効(左端ガード込み)
 
// font経路パイプライン用 1段レジスタ
logic osd_in_area_r, osd_in_sel_row_r, in_text_line_r, osd_textcol_valid_r;
logic [2:0] osd_bit_x_r, osd_font_row_r;
logic [6:0] osd_ascii_r;
 
// 文字列デコード: 行と文字位置から ASCII を返す
// 行の定義: 0=タイトル, 1..6=項目, 7=ショップ名
logic [3:0] osd_line;     // どの行か
logic [4:0] osd_line_col; // 行内の文字位置(0..)
logic in_text_line;       // 文字を描く行の中か
logic [9:0] osd_rel_y;    // OSD内相対Y
 
// 行ごとの文字列を返す function (行番号, 文字位置 → ASCII)
// 項目行(1..6)の col>=VALUE_COL は値表示: 行1,2=OFF/BRIGHT/DARK, 行3..6=■バー(■=0x01/□=0x02)
function [6:0] osd_char_at(input [3:0] line, input [4:0] col);
  logic [4:0] vcol;
  logic [3:0] v;
  begin
    osd_char_at = " ";
    vcol = col - VALUE_COL;
 
    // === 値表示 (項目行1..9 かつ col>=VALUE_COL のみ) ===
    if (line >= 4'd1 && line <= 4'd9 && col >= VALUE_COL) begin
      if (line == 4'd1) begin
        // PIXEL GRID: ■位置表示 (□□■□□, 5マス。中央2=OFF)
        if (vcol < 5'd5)
          osd_char_at = (vcol == {2'b0, grid_mode}) ? 7'h01 : 7'h02;
      end else if (line == 4'd2) begin
        // SCANLINE: 数値表記 OFF/25%/50%/75%/100%
        case (scanline_mode)
          3'd0: case (vcol) 0:osd_char_at="O";1:osd_char_at="F";2:osd_char_at="F";default:osd_char_at=" "; endcase
          3'd1: case (vcol) 0:osd_char_at="2";1:osd_char_at="5";2:osd_char_at="%";default:osd_char_at=" "; endcase
          3'd2: case (vcol) 0:osd_char_at="5";1:osd_char_at="0";2:osd_char_at="%";default:osd_char_at=" "; endcase
          3'd3: case (vcol) 0:osd_char_at="7";1:osd_char_at="5";2:osd_char_at="%";default:osd_char_at=" "; endcase
          default: case (vcol) 0:osd_char_at="1";1:osd_char_at="0";2:osd_char_at="0";3:osd_char_at="%";default:osd_char_at=" "; endcase
        endcase
      end else if (line >= 4'd7) begin
        // line7..9: ON/OFF (INVERT/GRAYSCALE/SEPIA)
        if ((line == 4'd7 && invert_mode) ||
            (line == 4'd8 && grayscale_mode) ||
            (line == 4'd9 && sepia_mode))
          case (vcol) 0:osd_char_at="O";1:osd_char_at="N";default:osd_char_at=" "; endcase
        else
          case (vcol) 0:osd_char_at="O";1:osd_char_at="F";2:osd_char_at="F";default:osd_char_at=" "; endcase
      end else begin
        // line 3..6: ■位置表示 (□…■…□, 16マス。■=現在値0..15)
        v = (line == 4'd3) ? brightness :
            (line == 4'd4) ? contrast   :
            (line == 4'd5) ? saturation : color_temp;
        if (vcol < 5'd15)
          osd_char_at = (vcol == ({1'b0, v} - 5'd1)) ? 7'h01 : 7'h02;  // 値1..15 → vcol0..14
      end
    end
    // === ラベル文字列 (上記以外) ===
    else begin
      case (line)
        4'd0: if (col >= 5'd6) case (5'(col - 5'd6)) // WSCHD REV2.0.1 (center)
          0:osd_char_at="W";1:osd_char_at="S";2:osd_char_at="C";3:osd_char_at="H";
          4:osd_char_at="D";5:osd_char_at=" ";6:osd_char_at="R";7:osd_char_at="E";
          8:osd_char_at="V";9:osd_char_at=".";10:osd_char_at="2";11:osd_char_at="0";
          12:osd_char_at="K";13:osd_char_at=" ";default:osd_char_at=" ";
        endcase
        4'd1: case (col) // PIXEL GRID
          0:osd_char_at="P";1:osd_char_at="I";2:osd_char_at="X";3:osd_char_at="E";
          4:osd_char_at="L";5:osd_char_at=" ";6:osd_char_at="G";7:osd_char_at="R";
          8:osd_char_at="I";9:osd_char_at="D";default:osd_char_at=" ";
        endcase
        4'd2: case (col) // SCANLINE
          0:osd_char_at="S";1:osd_char_at="C";2:osd_char_at="A";3:osd_char_at="N";
          4:osd_char_at="L";5:osd_char_at="I";6:osd_char_at="N";7:osd_char_at="E";
          default:osd_char_at=" ";
        endcase
        4'd3: case (col) // BRIGHTNESS
          0:osd_char_at="B";1:osd_char_at="R";2:osd_char_at="I";3:osd_char_at="G";
          4:osd_char_at="H";5:osd_char_at="T";6:osd_char_at="N";7:osd_char_at="E";
          8:osd_char_at="S";9:osd_char_at="S";default:osd_char_at=" ";
        endcase
        4'd4: case (col) // CONTRAST
          0:osd_char_at="C";1:osd_char_at="O";2:osd_char_at="N";3:osd_char_at="T";
          4:osd_char_at="R";5:osd_char_at="A";6:osd_char_at="S";7:osd_char_at="T";
          default:osd_char_at=" ";
        endcase
        4'd5: case (col) // SATURATION
          0:osd_char_at="S";1:osd_char_at="A";2:osd_char_at="T";3:osd_char_at="U";
          4:osd_char_at="R";5:osd_char_at="A";6:osd_char_at="T";7:osd_char_at="I";
          8:osd_char_at="O";9:osd_char_at="N";default:osd_char_at=" ";
        endcase
        4'd6: case (col) // GAMMA
          0:osd_char_at="G";1:osd_char_at="A";2:osd_char_at="M";3:osd_char_at="M";
          4:osd_char_at="A";default:osd_char_at=" ";
        endcase
        4'd7: case (col) // INVERT
          0:osd_char_at="I";1:osd_char_at="N";2:osd_char_at="V";3:osd_char_at="E";
          4:osd_char_at="R";5:osd_char_at="T";default:osd_char_at=" ";
        endcase
        4'd8: case (col) // MONO (grayscale)
          0:osd_char_at="M";1:osd_char_at="O";2:osd_char_at="N";3:osd_char_at="O";
          default:osd_char_at=" ";
        endcase
        4'd9: case (col) // SEPIA
          0:osd_char_at="S";1:osd_char_at="E";2:osd_char_at="P";3:osd_char_at="I";
          4:osd_char_at="A";default:osd_char_at=" ";
        endcase
        4'd10: if (col >= 5'd7) case (5'(col - 5'd7)) // RETRO PROTECT (center)
          0:osd_char_at="R";1:osd_char_at="E";2:osd_char_at="T";3:osd_char_at="R";
          4:osd_char_at="O";5:osd_char_at=" ";6:osd_char_at="P";7:osd_char_at="R";
          8:osd_char_at="O";9:osd_char_at="T";10:osd_char_at="E";11:osd_char_at="C";
          12:osd_char_at="T";default:osd_char_at=" ";
        endcase
        default: osd_char_at=" ";
      endcase
    end
  end
endfunction
 
// 値バー用: 選択項目の値を■の数で
logic [3:0] osd_val_of_row;
always_comb begin
  case (osd_line)
    4'd3: osd_val_of_row = brightness;
    4'd4: osd_val_of_row = contrast;
    4'd5: osd_val_of_row = saturation;
    4'd6: osd_val_of_row = color_temp;
    default: osd_val_of_row = 4'd0;
  endcase
end
 
// Stage A→B: デコード結果を1段登録(深い組合せ経路を分断)
always_ff @(posedge pxlClk) begin
  osd_in_area_r       <= osd_in_area;
  osd_in_sel_row_r    <= osd_in_sel_row;
  in_text_line_r      <= in_text_line;
  osd_textcol_valid_r <= osd_textcol_valid;
  osd_bit_x_r         <= osd_bit_x;
  osd_ascii_r         <= osd_ascii;
  osd_font_row_r      <= osd_font_row;
end
 
font_rom osd_font (
  .ascii_code( osd_ascii_r ),
  .row( osd_font_row_r ),
  .bit_pattern( osd_font_bits )
);
 
// Stage B: 登録済み入力からのfont出力で点灯判定
assign osd_text_on = in_text_line_r && osd_textcol_valid_r &&
                     osd_font_bits[7 - osd_bit_x_r];
 
always_comb begin
  osd_in_area = osd_open_r &&
                (cx >= OSD_X) && (cx < OSD_X + OSD_W) &&
                (cy >= OSD_Y) && (cy < OSD_Y + OSD_H);
  // 項目行(0..5)の判定: OSD_ITEM0_Y から OSD_ROW_PITCH ごと
  osd_row_idx = 4'd0;
  osd_in_sel_row = 1'b0;
  if (osd_open_r && cy >= OSD_ITEM0_Y && cy < OSD_ITEM0_Y + 9*OSD_ROW_PITCH) begin
    osd_row_idx = 4'((cy - OSD_ITEM0_Y) / OSD_ROW_PITCH);
    if (osd_row_idx == osd_sel) osd_in_sel_row = 1'b1;
  end
end
 
// 文字描画の座標計算: cx/cy から行・文字位置・フォントビットを求める
always_comb begin
  osd_line     = 4'd15;   // 無効
  osd_line_col = 5'd0;
  osd_bit_x    = 3'd0;
  osd_font_row = 3'd0;
  in_text_line = 1'b0;
 
  // タイトル行
  if (cy >= OSD_ROW0_Y && cy < OSD_ROW0_Y + OSD_CHAR_H) begin
    osd_line = 4'd0; in_text_line = 1'b1;
    osd_font_row = 3'((cy - OSD_ROW0_Y) >> 2);
  end
  else if (cy >= OSD_ITEM0_Y && cy < OSD_ITEM0_Y + 9*OSD_ROW_PITCH) begin
    // 行内オフセット。上下中央化のため 6px 下げた範囲に文字を描く (44-32=12, 上6/下6)
    if (((cy - OSD_ITEM0_Y) % OSD_ROW_PITCH) >= 6 &&
        ((cy - OSD_ITEM0_Y) % OSD_ROW_PITCH) <  6 + OSD_CHAR_H) begin
      osd_line = 4'(1 + (cy - OSD_ITEM0_Y) / OSD_ROW_PITCH);
      in_text_line = 1'b1;
      osd_font_row = 3'((((cy - OSD_ITEM0_Y) % OSD_ROW_PITCH) - 6) >> 2);
    end
  end
  // ショップ名行
  else if (cy >= OSD_SHOP_Y && cy < OSD_SHOP_Y + OSD_CHAR_H) begin
    osd_line = 4'd10; in_text_line = 1'b1;
    osd_font_row = 3'((cy - OSD_SHOP_Y) >> 2);
  end
 
  // X方向: 文字位置と文字内ビット (文字幅32=4倍, 左端 OSD_X+16 から)
  osd_line_col = 5'((cx - (OSD_X + 16)) >> 5);
  osd_bit_x    = 3'(((cx - (OSD_X + 16)) >> 2) & 3'd7);
 
  // ASCII を引く (font_rom へは次段で登録して渡す)
  osd_ascii = osd_char_at(osd_line, osd_line_col);
  // 文字列カラムが有効か (左端ガード込み)
  osd_textcol_valid = osd_in_area && (cx >= (OSD_X + 16));
end
 
// grid適用後・scanline適用前の色 (comb)
logic [23:0] rgb_base;
logic [23:0] rgb_base_r;     // gridを1段登録(scanlineとの経路分割)
logic        sl_active_r;    // scanline対象を1段登録
logic [23:0] rgb_sl;
logic [8:0]  sl_luma;
logic [8:0]  sl_w;
logic [2:0]  sl_sh;
logic [7:0]  sl_r, sl_g, sl_b;
always_comb begin
  // ベース色: viewport内はゲーム/grid、外は暗背景
  if (viewport_area_p8) begin
    if (grid_mode != 3'd2 && grid_line_p8) begin
      if (grid_mode == 3'd0)
        rgb_base = {  (adj_pixel[23:16] < 8'h40) ? 8'h00 : adj_pixel[23:16] - 8'h40,
                      (adj_pixel[15:8]  < 8'h40) ? 8'h00 : adj_pixel[15:8]  - 8'h40,
                      (adj_pixel[7:0]   < 8'h40) ? 8'h00 : adj_pixel[7:0]   - 8'h40 };
      else if (grid_mode == 3'd1)
        rgb_base = {  (adj_pixel[23:16] < 8'h20) ? 8'h00 : adj_pixel[23:16] - 8'h20,
                      (adj_pixel[15:8]  < 8'h20) ? 8'h00 : adj_pixel[15:8]  - 8'h20,
                      (adj_pixel[7:0]   < 8'h20) ? 8'h00 : adj_pixel[7:0]   - 8'h20 };
      else if (grid_mode == 3'd3)
        rgb_base = {  (adj_pixel[23:16] > 8'hDF) ? 8'hFF : adj_pixel[23:16] + 8'h20,
                      (adj_pixel[15:8]  > 8'hDF) ? 8'hFF : adj_pixel[15:8]  + 8'h20,
                      (adj_pixel[7:0]   > 8'hDF) ? 8'hFF : adj_pixel[7:0]   + 8'h20 };
      else
        rgb_base = {  (adj_pixel[23:16] > 8'hBF) ? 8'hFF : adj_pixel[23:16] + 8'h40,
                      (adj_pixel[15:8]  > 8'hBF) ? 8'hFF : adj_pixel[15:8]  + 8'h40,
                      (adj_pixel[7:0]   > 8'hBF) ? 8'hFF : adj_pixel[7:0]   + 8'h40 };
    end else begin
      rgb_base = adj_pixel;
    end
  end else begin
    rgb_base = 24'h141414;
  end
end

// grid結果を1段登録してscanlineと経路分割(緑縦線対策)
always_ff @(posedge pxlClk) begin
  rgb_base_r  <= rgb_base;
  sl_active_r <= (scanline_mode != 3'd0) && cy[0] && viewport_area_p8;
end

always_comb begin
  if (sl_active_r) begin
    sl_luma = ({2'b0, rgb_base_r[23:16]} + {2'b0, rgb_base_r[15:8]} + {2'b0, rgb_base_r[7:0]}) >> 2;
    case (scanline_mode)
      3'd1: sl_sh = 3'd3;
      3'd2: sl_sh = 3'd2;
      3'd3: sl_sh = 3'd1;
      default: sl_sh = 3'd0;
    endcase
    sl_r = (rgb_base_r[23:16] >> sl_sh);
    sl_g = (rgb_base_r[15:8]  >> sl_sh);
    sl_b = (rgb_base_r[7:0]   >> sl_sh);
    sl_w  = (sl_luma >= 9'd255) ? 9'd0 : (9'd255 - sl_luma);
    sl_r  = 8'((16'(sl_r) * 16'(sl_w)) >> 8);
    sl_g  = 8'((16'(sl_g) * 16'(sl_w)) >> 8);
    sl_b  = 8'((16'(sl_b) * 16'(sl_w)) >> 8);
    rgb_sl = { (rgb_base_r[23:16] > sl_r) ? rgb_base_r[23:16] - sl_r : 8'h0,
               (rgb_base_r[15:8]  > sl_g) ? rgb_base_r[15:8]  - sl_g : 8'h0,
               (rgb_base_r[7:0]   > sl_b) ? rgb_base_r[7:0]   - sl_b : 8'h0 };
  end else begin
    rgb_sl = rgb_base_r;
  end
end
 
always_ff @(posedge pxlClk) begin
  if (rst) begin
    rgb <= 24'h141414;
  end else begin
    rgb <= rgb_sl;
 
    // OSD を重ねる (黒50%アルファ。選択行ハイライト。文字は白でくっきり)
    if (osd_in_area_r) begin
      if (osd_text_on) begin
        rgb <= 24'hFFFFFF;   // 文字: 不透明な白
      end else if (viewport_area_p8) begin
        // ビューポート内: 調整後ゲーム映像を50%で透かす(本体と同じ7段遅延に揃える)
        if (osd_in_sel_row_r)
          rgb <= { 1'b0, adj_pixel[23:17] + 7'h20,
                   1'b0, adj_pixel[15:9]  + 7'h20,
                   1'b0, adj_pixel[7:1]   + 7'h40 };
        else
          rgb <= { 1'b0, adj_pixel[23:17],
                   1'b0, adj_pixel[15:9],
                   1'b0, adj_pixel[7:1] };
      end else begin
        // ビューポート外: 映像を透かさず固定の暗背景(選択行のみ青寄り)
        rgb <= osd_in_sel_row_r ? 24'h101030 : 24'h0A0A0A;
      end
    end
  end
end
 
// メモリアドレスジェネレータ
always_ff @(posedge pxlClk) begin
  if (rst) begin
    pxlAddrReg <= '0; lineCntPxl <= '0; scaleCntX  <= '0; scaleCntY  <= '0;
    lineBase   <= '0; colCnt     <= '0; lineCntAbs <= '0; lineCntRel <= '0;
  end else if (!rotate_int) begin
    if (cx == VP_START_X) lineBase <= pxlAddrReg;
    if (cy > WINDOW_END_Y) begin
      pxlAddrReg <= '0; lineCntPxl <= '0; scaleCntX  <= '0; scaleCntY  <= '0;
      lineBase   <= '0; colCnt     <= '0;
    end else if (cx == 11'(WINDOW_END_X + 1)) begin
      scaleCntX <= '0;
      if (scaleCntY == 4'(SCALE - 1)) scaleCntY <= '0;
      else scaleCntY <= scaleCntY + 1'b1;
    end
 
    if (cx > VP_START_X && cx <= WINDOW_END_X && cy > VP_START_Y && cy <= WINDOW_END_Y) begin
      if ((lineCntPxl == 9'(COLLEN - 1)) && (scaleCntX == 4'(SCALE - 1))) begin
        pxlAddrReg <= ((colCnt < 3'd2) || (scaleCntY < 4'(SCALE - 1))) ? lineBase : pxlAddrReg + 1'b1;
        lineCntPxl <= '0; scaleCntX  <= '0; colCnt <= colCnt + 1'b1;
      end else if (scaleCntX == 4'(SCALE - 1)) begin
        lineCntPxl <= lineCntPxl + 1'b1; pxlAddrReg <= pxlAddrReg + 1'b1; scaleCntX  <= '0;
      end else begin
        scaleCntX  <= scaleCntX + 1'b1;
      end
    end else begin
      colCnt <= '0; lineCntPxl <= '0;
    end
  end else begin
    if (cx == VP_START_ROT_X) lineBase <= pxlAddrReg;
    if (cy <= VP_START_ROT_Y || cy > VP_END_ROT_Y) begin
      pxlAddrReg <= 14'(COLLEN - 1 - 16); lineCntPxl <= '0; scaleCntX  <= '0; scaleCntY  <= '0;
      lineBase   <= '0; colCnt <= 3'd2; lineCntAbs <= 8'd16; lineCntRel <= 8'd16;
    end
 
    if (lineCntAbs <= 8'(COLLEN - 1)) colCnt <= 3'd2;
    else if (lineCntAbs <= 8'((2 * COLLEN) - 1)) colCnt <= 3'd1;
    else colCnt <= 3'd0;
 
    if (cx > VP_START_ROT_X && cx <= WINDOW_END_ROT_X && cy > VP_START_ROT_Y && cy <= VP_END_ROT_Y) begin
      if ((lineCntPxl == 9'(150 - 1)) && (scaleCntX == 4'(SCALEROT - 1))) begin
        lineCntPxl <= '0; scaleCntX  <= '0;
        if (scaleCntY == 4'(SCALEROT - 1)) begin
          lineCntAbs <= lineCntAbs + 1'b1;
          scaleCntY  <= '0;
          if (lineCntRel == 8'(COLLEN - 1)) begin
            lineCntRel <= '0; pxlAddrReg <= 14'(COLLEN - 1);
          end else begin
            lineCntRel <= lineCntRel + 1'b1; pxlAddrReg <= lineBase - 14'd1;
          end
        end else begin
          scaleCntY <= scaleCntY + 1'b1; pxlAddrReg <= lineBase;
        end
      end else if (scaleCntX == 4'(SCALEROT - 1)) begin
        lineCntPxl <= lineCntPxl + 1'b1; scaleCntX <= '0; pxlAddrReg <= pxlAddrReg + 14'(COLLEN);
      end else begin
        scaleCntX <= scaleCntX + 1'b1;
      end
    end else begin
      lineCntPxl <= '0;
    end
  end
end
 
logic [2:0] tmds;
assign tmds_p = tmds;
assign tmds_n = ~tmds; 
assign tmds_clk = pxlClk;
 
logic [AUDIO_BIT_WIDTH-1:0] audioWord [1:0];
assign audioWord[0] = AUDIO_BIT_WIDTH'(audioRBuff);
assign audioWord[1] = AUDIO_BIT_WIDTH'(audioLBuff);
 
// HDMIモジュールインスタンス
hdmi #( .VIDEO_ID_CODE(VIDEOID), 
        .DVI_OUTPUT(0), 
        .VIDEO_REFRESH_RATE(VIDEO_REFRESH),
        .IT_CONTENT(1),
`ifdef CUSTOM_RES
        .CUSTOM_FRAME_WIDTH( CUSTOM_FRAME_WIDTH ),
        .CUSTOM_FRAME_HEIGHT( CUSTOM_FRAME_HEIGHT ),
        .CUSTOM_SCREEN_WIDTH( CUSTOM_SCREEN_WIDTH ),
        .CUSTOM_SCREEN_HEIGHT( CUSTOM_SCREEN_HEIGHT ),
        .CUSTOM_HSYNC_PULSE_START( CUSTOM_HSYNC_PULSE_START ),
        .CUSTOM_HSYNC_PULSE_SIZE( CUSTOM_HSYNC_PULSE_SIZE ),
        .CUSTOM_VSYNC_PULSE_START( CUSTOM_VSYNC_PULSE_START ),
        .CUSTOM_VSYNC_PULSE_SIZE( CUSTOM_VSYNC_PULSE_SIZE ),
        .CUSTOM_INVERT( CUSTOM_INVERT ),
        .CUSTOM_VIDEO_RATE( CUSTOM_VIDEO_RATE ),
        .CUSTOM_BIT_WIDTH( CUSTOM_BIT_WIDTH ),
        .CUSTOM_BIT_HEIGHT( CUSTOM_BIT_HEIGHT ),
`endif
        .AUDIO_RATE(48000), 
        .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
        .START_X(0),
        .START_Y(0) )
hdmi_inst (
      .clk_pixel_x5(pxlClkx5), 
      .clk_pixel(pxlClk), 
      .clk_audio(audioClk),
      .rgb(rgb), 
      .reset( rst ),
      .audio_sample_word(audioWord),
      .tmds(tmds), 
      .tmds_clock(tmds_clk), 
      .cx(cx), 
      .cy(cy),
      .frame_width( frameWidth ),
      .frame_height( frameHeight ),
      .screen_width( ), 
      .screen_height( ) 
);
 
// オーディオキャプチャインスタンス
audioCapture audio_inst (
  .clk( pxlClk ),
  .rst( rst ),
  .LRCK( LRCK ),
  .SDAT( SDAT ),
  .BCLK( BCLK ),
  .audioOutL( audioL ),
  .audioOutR( audioR ),
  .audioValidR( audioValidR ),
  .audioValidL( audioValidL ) );
 
endmodule