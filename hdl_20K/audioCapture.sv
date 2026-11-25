import WS_defines::*;

module audioCapture #(
    parameter int FILTERLEN = 5
)(
    input  logic clk,
    input  logic rst,
    input  logic LRCK,
    input  logic SDAT,
    input  logic BCLK,
    output logic [15:0] audioOutL,
    output logic [15:0] audioOutR,
    output logic audioValidL,
    output logic audioValidR
);

  logic [FILTERLEN-1:0] LRCK_filter, SDAT_filter, BCLK_filter;
  logic LRCK_int, SDAT_int, BCLK_int;
  logic [15:0] audioBufL, audioBufR;
  logic BCLK_del, LRCK_del;

  assign audioOutL = audioBufL;
  assign audioOutR = audioBufR;

  always_ff @(posedge clk) begin
    if (rst) begin
      audioBufL   <= 16'd0;
      audioBufR   <= 16'd0;
      audioValidL <= 1'b0;
      audioValidR <= 1'b0;
      BCLK_del    <= 1'b0;
      LRCK_del    <= 1'b0;
      LRCK_filter <= '0;
      SDAT_filter <= '0;
      BCLK_filter <= '0;
      LRCK_int    <= 1'b0;
      BCLK_int    <= 1'b0;
      SDAT_int    <= 1'b0;
    end else begin
      BCLK_filter <= {BCLK, BCLK_filter[FILTERLEN-1:1]};
      SDAT_filter <= {SDAT, SDAT_filter[FILTERLEN-1:1]};
      LRCK_filter <= {LRCK, LRCK_filter[FILTERLEN-1:1]};

      if (!BCLK_int && (&BCLK_filter)) BCLK_int <= 1'b1;
      else if (BCLK_int && !(|BCLK_filter)) BCLK_int <= 1'b0;

      if (!LRCK_int && (&LRCK_filter)) LRCK_int <= 1'b1;
      else if (LRCK_int && !(|LRCK_filter)) LRCK_int <= 1'b0;

      if (!SDAT_int && (&SDAT_filter)) SDAT_int <= 1'b1;
      else if (SDAT_int && !(|SDAT_filter)) SDAT_int <= 1'b0;

      BCLK_del <= BCLK_int;
      LRCK_del <= LRCK_int;
      
      audioValidL <= 1'b0;
      audioValidR <= 1'b0;
      
      if (LRCK_int != LRCK_del) begin
        if (LRCK_int) audioValidR <= 1'b1;
        else          audioValidL <= 1'b1;
      end

      if (BCLK_int && !BCLK_del) begin
        if (LRCK_int) begin
          audioBufL <= {audioBufL[14:0], SDAT_int};
        end else begin
          audioBufR <= {audioBufR[14:0], SDAT_int};
        end
      end
    end
  end
endmodule