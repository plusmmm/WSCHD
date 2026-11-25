// font_rom.v  8x8 フォント (A-Z, 0-9, '.', ' ', バー用 ■=0x01 □=0x02)
// 文字は左7bitに描画しbit0は余白(字間4px)。バー(0x01/0x02)のみ8bitフル。
module font_rom (
    input wire [6:0] ascii_code,
    input wire [2:0] row,
    output reg [7:0] bit_pattern
);
    always @(*) begin
        case (ascii_code)
            7'h01: case(row) // ■ 塗りつぶし (8bitフル, 字間なし)
                3'd0: bit_pattern=8'b01111110; 3'd1: bit_pattern=8'b01111110;
                3'd2: bit_pattern=8'b01111110; 3'd3: bit_pattern=8'b01111110;
                3'd4: bit_pattern=8'b01111110; 3'd5: bit_pattern=8'b01111110;
                3'd6: bit_pattern=8'b01111110; 3'd7: bit_pattern=8'b01111110;
            endcase
            7'h02: case(row) // □ 枠 (8bitフル, 字間なし)
                3'd0: bit_pattern=8'b00000000; 3'd1: bit_pattern=8'b00000000;
                3'd2: bit_pattern=8'b00000000; 3'd3: bit_pattern=8'b00000000;
                3'd4: bit_pattern=8'b01111110; 3'd5: bit_pattern=8'b01111110;
                3'd6: bit_pattern=8'b00000000; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h20: bit_pattern=8'b00000000; // スペース
            7'h2E: case(row) // .
                3'd0: bit_pattern=8'b00000000; 3'd1: bit_pattern=8'b00000000;
                3'd2: bit_pattern=8'b00000000; 3'd3: bit_pattern=8'b00000000;
                3'd4: bit_pattern=8'b00000000; 3'd5: bit_pattern=8'b00011000;
                3'd6: bit_pattern=8'b00011000; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h30: case(row) // 0
                3'd0: bit_pattern=8'b00111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000110; 3'd3: bit_pattern=8'b01011010;
                3'd4: bit_pattern=8'b01100010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h31: case(row) // 1
                3'd0: bit_pattern=8'b00011000; 3'd1: bit_pattern=8'b00111000;
                3'd2: bit_pattern=8'b00011000; 3'd3: bit_pattern=8'b00011000;
                3'd4: bit_pattern=8'b00011000; 3'd5: bit_pattern=8'b00011000;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h32: case(row) // 2
                3'd0: bit_pattern=8'b00111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b00000010; 3'd3: bit_pattern=8'b00001100;
                3'd4: bit_pattern=8'b00110000; 3'd5: bit_pattern=8'b01000000;
                3'd6: bit_pattern=8'b01111110; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h33: case(row) // 3
                3'd0: bit_pattern=8'b00111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b00000010; 3'd3: bit_pattern=8'b00011100;
                3'd4: bit_pattern=8'b00000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h34: case(row) // 4
                3'd0: bit_pattern=8'b00000100; 3'd1: bit_pattern=8'b00001100;
                3'd2: bit_pattern=8'b00010100; 3'd3: bit_pattern=8'b00100100;
                3'd4: bit_pattern=8'b01111110; 3'd5: bit_pattern=8'b00000100;
                3'd6: bit_pattern=8'b00000100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h35: case(row) // 5
                3'd0: bit_pattern=8'b01111110; 3'd1: bit_pattern=8'b01000000;
                3'd2: bit_pattern=8'b01111100; 3'd3: bit_pattern=8'b00000010;
                3'd4: bit_pattern=8'b00000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h36: case(row) // 6
                3'd0: bit_pattern=8'b00111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000000; 3'd3: bit_pattern=8'b01111100;
                3'd4: bit_pattern=8'b01000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h37: case(row) // 7
                3'd0: bit_pattern=8'b01111110; 3'd1: bit_pattern=8'b00000010;
                3'd2: bit_pattern=8'b00000100; 3'd3: bit_pattern=8'b00001000;
                3'd4: bit_pattern=8'b00010000; 3'd5: bit_pattern=8'b00010000;
                3'd6: bit_pattern=8'b00010000; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h38: case(row) // 8
                3'd0: bit_pattern=8'b00111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b00111100;
                3'd4: bit_pattern=8'b01000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h39: case(row) // 9
                3'd0: bit_pattern=8'b00111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b00111110;
                3'd4: bit_pattern=8'b00000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h41: case(row) // A
                3'd0: bit_pattern=8'b00011000; 3'd1: bit_pattern=8'b00100100;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b01000010;
                3'd4: bit_pattern=8'b01111110; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b01000010; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h42: case(row) // B
                3'd0: bit_pattern=8'b01111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b01111100;
                3'd4: bit_pattern=8'b01000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b01111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h43: case(row) // C
                3'd0: bit_pattern=8'b00111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000000; 3'd3: bit_pattern=8'b01000000;
                3'd4: bit_pattern=8'b01000000; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h44: case(row) // D
                3'd0: bit_pattern=8'b01111000; 3'd1: bit_pattern=8'b01000100;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b01000010;
                3'd4: bit_pattern=8'b01000010; 3'd5: bit_pattern=8'b01000100;
                3'd6: bit_pattern=8'b01111000; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h45: case(row) // E
                3'd0: bit_pattern=8'b01111110; 3'd1: bit_pattern=8'b01000000;
                3'd2: bit_pattern=8'b01000000; 3'd3: bit_pattern=8'b01111000;
                3'd4: bit_pattern=8'b01000000; 3'd5: bit_pattern=8'b01000000;
                3'd6: bit_pattern=8'b01111110; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h47: case(row) // G
                3'd0: bit_pattern=8'b00111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000000; 3'd3: bit_pattern=8'b01001110;
                3'd4: bit_pattern=8'b01000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h48: case(row) // H
                3'd0: bit_pattern=8'b01000010; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b01111110;
                3'd4: bit_pattern=8'b01000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b01000010; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h49: case(row) // I
                3'd0: bit_pattern=8'b00111110; 3'd1: bit_pattern=8'b00001000;
                3'd2: bit_pattern=8'b00001000; 3'd3: bit_pattern=8'b00001000;
                3'd4: bit_pattern=8'b00001000; 3'd5: bit_pattern=8'b00001000;
                3'd6: bit_pattern=8'b00111110; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h4C: case(row) // L
                3'd0: bit_pattern=8'b01000000; 3'd1: bit_pattern=8'b01000000;
                3'd2: bit_pattern=8'b01000000; 3'd3: bit_pattern=8'b01000000;
                3'd4: bit_pattern=8'b01000000; 3'd5: bit_pattern=8'b01000000;
                3'd6: bit_pattern=8'b01111110; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h4D: case(row) // M
                3'd0: bit_pattern=8'b01000010; 3'd1: bit_pattern=8'b01100110;
                3'd2: bit_pattern=8'b01011010; 3'd3: bit_pattern=8'b01011010;
                3'd4: bit_pattern=8'b01000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b01000010; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h4E: case(row) // N
                3'd0: bit_pattern=8'b01000010; 3'd1: bit_pattern=8'b01100010;
                3'd2: bit_pattern=8'b01010010; 3'd3: bit_pattern=8'b01001010;
                3'd4: bit_pattern=8'b01000110; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b01000010; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h4F: case(row) // O
                3'd0: bit_pattern=8'b00111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b01000010;
                3'd4: bit_pattern=8'b01000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h50: case(row) // P
                3'd0: bit_pattern=8'b01111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b01111100;
                3'd4: bit_pattern=8'b01000000; 3'd5: bit_pattern=8'b01000000;
                3'd6: bit_pattern=8'b01000000; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h52: case(row) // R
                3'd0: bit_pattern=8'b01111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b01111100;
                3'd4: bit_pattern=8'b01001000; 3'd5: bit_pattern=8'b01000100;
                3'd6: bit_pattern=8'b01000010; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h53: case(row) // S
                3'd0: bit_pattern=8'b00111100; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000000; 3'd3: bit_pattern=8'b00111100;
                3'd4: bit_pattern=8'b00000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h54: case(row) // T
                3'd0: bit_pattern=8'b01111110; 3'd1: bit_pattern=8'b00001000;
                3'd2: bit_pattern=8'b00001000; 3'd3: bit_pattern=8'b00001000;
                3'd4: bit_pattern=8'b00001000; 3'd5: bit_pattern=8'b00001000;
                3'd6: bit_pattern=8'b00001000; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h55: case(row) // U
                3'd0: bit_pattern=8'b01000010; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b01000010;
                3'd4: bit_pattern=8'b01000010; 3'd5: bit_pattern=8'b01000010;
                3'd6: bit_pattern=8'b00111100; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h56: case(row) // V
                3'd0: bit_pattern=8'b01000010; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b01000010;
                3'd4: bit_pattern=8'b00100100; 3'd5: bit_pattern=8'b00011000;
                3'd6: bit_pattern=8'b00011000; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h57: case(row) // W
                3'd0: bit_pattern=8'b01000010; 3'd1: bit_pattern=8'b01000010;
                3'd2: bit_pattern=8'b01000010; 3'd3: bit_pattern=8'b01011010;
                3'd4: bit_pattern=8'b01011010; 3'd5: bit_pattern=8'b01100110;
                3'd6: bit_pattern=8'b01000010; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h58: case(row) // X
                3'd0: bit_pattern=8'b01000010; 3'd1: bit_pattern=8'b00100100;
                3'd2: bit_pattern=8'b00011000; 3'd3: bit_pattern=8'b00011000;
                3'd4: bit_pattern=8'b00011000; 3'd5: bit_pattern=8'b00100100;
                3'd6: bit_pattern=8'b01000010; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h46: case(row) // F
                3'd0: bit_pattern=8'b01111110; 3'd1: bit_pattern=8'b01000000;
                3'd2: bit_pattern=8'b01000000; 3'd3: bit_pattern=8'b01111000;
                3'd4: bit_pattern=8'b01000000; 3'd5: bit_pattern=8'b01000000;
                3'd6: bit_pattern=8'b01000000; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h4B: case(row) // K
                3'd0: bit_pattern=8'b01000010; 3'd1: bit_pattern=8'b01000100;
                3'd2: bit_pattern=8'b01001000; 3'd3: bit_pattern=8'b01110000;
                3'd4: bit_pattern=8'b01001000; 3'd5: bit_pattern=8'b01000100;
                3'd6: bit_pattern=8'b01000010; 3'd7: bit_pattern=8'b00000000;
            endcase
            7'h25: case(row) // %
                3'd0: bit_pattern=8'b01100010; 3'd1: bit_pattern=8'b01100100;
                3'd2: bit_pattern=8'b00001000; 3'd3: bit_pattern=8'b00010000;
                3'd4: bit_pattern=8'b00100000; 3'd5: bit_pattern=8'b01001100;
                3'd6: bit_pattern=8'b10001100; 3'd7: bit_pattern=8'b00000000;
            endcase
            default: bit_pattern = 8'b00000000;
        endcase
    end
endmodule