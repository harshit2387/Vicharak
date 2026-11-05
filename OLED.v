
(* top *)
module main (
    (* iopad_external_pin, clkbuf_inhibit *) input wire clk,
    (* iopad_external_pin *) output wire clk_en,

    (* iopad_external_pin *) output wire oled_scl_out,
    (* iopad_external_pin *) output wire oled_scl_oe,

    (* iopad_external_pin *) input wire oled_sda_in,
    (* iopad_external_pin *) output wire oled_sda_out,
    (* iopad_external_pin *) output wire oled_sda_oe
);

    // =====================================================
    // FPGA CLOCK
    // =====================================================

    assign clk_en = 1'b1;

    // Open-drain: output data is always LOW.
    assign oled_scl_out = 1'b0;
    assign oled_sda_out = 1'b0;

    // =====================================================
    // I2C TIMING: 100 kHz at 50 MHz
    // =====================================================

    reg [7:0] div_count = 0;
    wire i2c_tick = (div_count == 8'd249);

    always @(posedge clk) begin
        if (i2c_tick)
            div_count <= 0;
        else
            div_count <= div_count + 1'b1;
    end

    // =====================================================
    // I2C MASTER
    // Each transaction:
    // START + 78 + CONTROL + DATA + STOP
    // =====================================================

    localparam I_IDLE       = 4'd0;
    localparam I_START_A    = 4'd1;
    localparam I_START_B    = 4'd2;
    localparam I_START_C    = 4'd3;
    localparam I_BIT_SETUP  = 4'd4;
    localparam I_BIT_HIGH   = 4'd5;
    localparam I_BIT_LOW    = 4'd6;
    localparam I_ACK_SETUP  = 4'd7;
    localparam I_ACK_HIGH   = 4'd8;
    localparam I_ACK_LOW    = 4'd9;
    localparam I_STOP_SETUP = 4'd10;
    localparam I_STOP_HIGH  = 4'd11;
    localparam I_STOP_REL   = 4'd12;

    reg [3:0] i2c_state = I_IDLE;

    reg [7:0] packet1 = 0;
    reg [7:0] packet2 = 0;

    reg [7:0] byte1 = 0;
    reg [7:0] byte2 = 0;
    reg [7:0] shift_reg = 0;

    reg [1:0] byte_index = 0;
    reg [2:0] bit_index = 7;

    reg ack_sample = 0;

    reg tx_start = 0;
    reg tx_done = 0;

    wire i2c_busy = (i2c_state != I_IDLE);

    reg scl_pull_low;
    reg sda_pull_low;

    always @(*) begin

        scl_pull_low = 1'b0;
        sda_pull_low = 1'b0;

        case (i2c_state)

            I_START_B: begin
                sda_pull_low = 1'b1;
            end

            I_START_C: begin
                scl_pull_low = 1'b1;
                sda_pull_low = 1'b1;
            end

            I_BIT_SETUP,
            I_BIT_HIGH,
            I_BIT_LOW: begin
                scl_pull_low = (i2c_state != I_BIT_HIGH);
                sda_pull_low = ~shift_reg[bit_index];
            end

            I_ACK_SETUP,
            I_ACK_LOW: begin
                scl_pull_low = 1'b1;
            end

            I_STOP_SETUP: begin
                scl_pull_low = 1'b1;
                sda_pull_low = 1'b1;
            end

            I_STOP_HIGH: begin
                sda_pull_low = 1'b1;
            end

            default: begin
                scl_pull_low = 1'b0;
                sda_pull_low = 1'b0;
            end

        endcase
    end

    assign oled_scl_oe = scl_pull_low;
    assign oled_sda_oe = sda_pull_low;

    always @(posedge clk) begin

        tx_done <= 1'b0;

        if (i2c_state == I_IDLE) begin

            if (tx_start) begin

                byte1 <= packet1;
                byte2 <= packet2;

                shift_reg <= 8'h78;
                byte_index <= 0;
                bit_index <= 7;

                i2c_state <= I_START_A;

            end

        end

        else if (i2c_tick) begin

            case (i2c_state)

                I_START_A:
                    i2c_state <= I_START_B;

                I_START_B:
                    i2c_state <= I_START_C;

                I_START_C:
                    i2c_state <= I_BIT_SETUP;

                I_BIT_SETUP:
                    i2c_state <= I_BIT_HIGH;

                I_BIT_HIGH:
                    i2c_state <= I_BIT_LOW;

                I_BIT_LOW: begin

                    if (bit_index == 0)
                        i2c_state <= I_ACK_SETUP;

                    else begin
                        bit_index <= bit_index - 1'b1;
                        i2c_state <= I_BIT_SETUP;
                    end

                end

                I_ACK_SETUP:
                    i2c_state <= I_ACK_HIGH;

                I_ACK_HIGH: begin
                    ack_sample <= ~oled_sda_in;
                    i2c_state <= I_ACK_LOW;
                end

                I_ACK_LOW: begin

                    if (byte_index == 2) begin
                        i2c_state <= I_STOP_SETUP;
                    end

                    else begin

                        byte_index <= byte_index + 1'b1;
                        bit_index <= 7;

                        if (byte_index == 0)
                            shift_reg <= byte1;
                        else
                            shift_reg <= byte2;

                        i2c_state <= I_BIT_SETUP;

                    end

                end

                I_STOP_SETUP:
                    i2c_state <= I_STOP_HIGH;

                I_STOP_HIGH:
                    i2c_state <= I_STOP_REL;

                I_STOP_REL: begin
                    i2c_state <= I_IDLE;
                    tx_done <= 1'b1;
                end

                default:
                    i2c_state <= I_IDLE;

            endcase

        end

    end

    // =====================================================
    // SSD1306 INITIALIZATION ROM
    // =====================================================

    function [7:0] init_byte;
        input [4:0] index;

        begin
            case (index)
                0:  init_byte = 8'hAE;
                1:  init_byte = 8'hD5;
                2:  init_byte = 8'h80;
                3:  init_byte = 8'hA8;
                4:  init_byte = 8'h3F;
                5:  init_byte = 8'hD3;
                6:  init_byte = 8'h00;
                7:  init_byte = 8'h40;
                8:  init_byte = 8'h8D;
                9:  init_byte = 8'h14;
                10: init_byte = 8'h20;
                11: init_byte = 8'h02;
                12: init_byte = 8'hA1;
                13: init_byte = 8'hC8;
                14: init_byte = 8'hDA;
                15: init_byte = 8'h12;
                16: init_byte = 8'h81;
                17: init_byte = 8'hCF;
                18: init_byte = 8'hD9;
                19: init_byte = 8'hF1;
                20: init_byte = 8'hDB;
                21: init_byte = 8'h40;
                22: init_byte = 8'hA4;
                23: init_byte = 8'hA6;
                24: init_byte = 8'hAF;
                default: init_byte = 8'hAE;
            endcase
        end
    endfunction

    // =====================================================
    // FONT ROM: 5 x 7
    // =====================================================

    function [7:0] glyph_col;
        input [7:0] character;
        input [2:0] column;

        begin

            glyph_col = 0;

            case (character)

                "H": case (column)
                    0: glyph_col = 8'h7F;
                    1: glyph_col = 8'h08;
                    2: glyph_col = 8'h08;
                    3: glyph_col = 8'h08;
                    4: glyph_col = 8'h7F;
                endcase

                "E": case (column)
                    0: glyph_col = 8'h7F;
                    1: glyph_col = 8'h49;
                    2: glyph_col = 8'h49;
                    3: glyph_col = 8'h49;
                    4: glyph_col = 8'h41;
                endcase

                "L": case (column)
                    0: glyph_col = 8'h7F;
                    1: glyph_col = 8'h40;
                    2: glyph_col = 8'h40;
                    3: glyph_col = 8'h40;
                    4: glyph_col = 8'h40;
                endcase

                "O": case (column)
                    0: glyph_col = 8'h3E;
                    1: glyph_col = 8'h41;
                    2: glyph_col = 8'h41;
                    3: glyph_col = 8'h41;
                    4: glyph_col = 8'h3E;
                endcase

                "A": case (column)
                    0: glyph_col = 8'h7E;
                    1: glyph_col = 8'h11;
                    2: glyph_col = 8'h11;
                    3: glyph_col = 8'h11;
                    4: glyph_col = 8'h7E;
                endcase

                "R": case (column)
                    0: glyph_col = 8'h7F;
                    1: glyph_col = 8'h09;
                    2: glyph_col = 8'h19;
                    3: glyph_col = 8'h29;
                    4: glyph_col = 8'h46;
                endcase

                "S": case (column)
                    0: glyph_col = 8'h46;
                    1: glyph_col = 8'h49;
                    2: glyph_col = 8'h49;
                    3: glyph_col = 8'h49;
                    4: glyph_col = 8'h31;
                endcase

                "I": case (column)
                    0: glyph_col = 8'h00;
                    1: glyph_col = 8'h41;
                    2: glyph_col = 8'h7F;
                    3: glyph_col = 8'h41;
                    4: glyph_col = 8'h00;
                endcase

                "T": case (column)
                    0: glyph_col = 8'h01;
                    1: glyph_col = 8'h01;
                    2: glyph_col = 8'h7F;
                    3: glyph_col = 8'h01;
                    4: glyph_col = 8'h01;
                endcase

                default: glyph_col = 0;

            endcase

        end
    endfunction

    function [7:0] text_character;
        input [3:0] index;

        begin
            case (index)
                0: text_character = "H";
                1: text_character = "E";
                2: text_character = "L";
                3: text_character = "L";
                4: text_character = "O";
                5: text_character = " ";
                6: text_character = "H";
                7: text_character = "A";
                8: text_character = "R";
                9: text_character = "S";
                10: text_character = "H";
                11: text_character = "I";
                12: text_character = "T";
                default: text_character = " ";
            endcase
        end
    endfunction

    // =====================================================
    // MAIN CONTROLLER
    // =====================================================

    localparam ST_BOOT         = 5'd0;
    localparam ST_INIT_SEND    = 5'd1;
    localparam ST_INIT_WAIT    = 5'd2;
    localparam ST_PAGE_SEND    = 5'd3;
    localparam ST_PAGE_WAIT    = 5'd4;
    localparam ST_LOW_SEND     = 5'd5;
    localparam ST_LOW_WAIT     = 5'd6;
    localparam ST_HIGH_SEND    = 5'd7;
    localparam ST_HIGH_WAIT    = 5'd8;
    localparam ST_CLEAR_SEND   = 5'd9;
    localparam ST_CLEAR_WAIT   = 5'd10;
    localparam ST_TEXT_PAGE    = 5'd11;
    localparam ST_TEXT_LOW     = 5'd12;
    localparam ST_TEXT_HIGH    = 5'd13;
    localparam ST_TEXT_SEND    = 5'd14;
    localparam ST_TEXT_WAIT    = 5'd15;
    localparam ST_DONE         = 5'd16;

    reg [4:0] state = ST_BOOT;

    reg [31:0] boot_count = 0;

    reg [4:0] init_index = 0;

    reg [2:0] page_index = 0;
    reg [6:0] column_index = 0;

    reg [3:0] text_index = 0;
    reg [2:0] text_column = 0;

    always @(posedge clk) begin

        tx_start <= 1'b0;

        case (state)

            // POWER-UP DELAY: 500 ms

            ST_BOOT: begin
                if (boot_count >= 32'd25_000_000) begin
                    boot_count <= 0;
                    init_index <= 0;
                    state <= ST_INIT_SEND;
                end
                else
                    boot_count <= boot_count + 1'b1;
            end

            // OLED INITIALIZATION

            ST_INIT_SEND: begin
                if (!i2c_busy) begin
                    packet1 <= 8'h00;
                    packet2 <= init_byte(init_index);
                    tx_start <= 1'b1;
                    state <= ST_INIT_WAIT;
                end
            end

            ST_INIT_WAIT: begin
                if (tx_done) begin
                    if (init_index == 24) begin
                        page_index <= 0;
                        column_index <= 0;
                        state <= ST_PAGE_SEND;
                    end
                    else begin
                        init_index <= init_index + 1'b1;
                        state <= ST_INIT_SEND;
                    end
                end
            end

            // PAGE ADDRESS

            ST_PAGE_SEND: begin
                if (!i2c_busy) begin
                    packet1 <= 8'h00;
                    packet2 <= 8'hB0 | page_index;
                    tx_start <= 1'b1;
                    state <= ST_PAGE_WAIT;
                end
            end

            ST_PAGE_WAIT: begin
                if (tx_done)
                    state <= ST_LOW_SEND;
            end

            // LOW COLUMN ADDRESS

            ST_LOW_SEND: begin
                if (!i2c_busy) begin
                    packet1 <= 8'h00;
                    packet2 <= 8'h00;
                    tx_start <= 1'b1;
                    state <= ST_LOW_WAIT;
                end
            end

            ST_LOW_WAIT: begin
                if (tx_done)
                    state <= ST_HIGH_SEND;
            end

            // HIGH COLUMN ADDRESS

            ST_HIGH_SEND: begin
                if (!i2c_busy) begin
                    packet1 <= 8'h00;
                    packet2 <= 8'h10;
                    tx_start <= 1'b1;
                    state <= ST_HIGH_WAIT;
                end
            end

            ST_HIGH_WAIT: begin
                if (tx_done) begin
                    column_index <= 0;
                    state <= ST_CLEAR_SEND;
                end
            end

            // CLEAR 8 PAGES x 128 COLUMNS

            ST_CLEAR_SEND: begin
                if (!i2c_busy) begin
                    packet1 <= 8'h40;
                    packet2 <= 8'h00;
                    tx_start <= 1'b1;
                    state <= ST_CLEAR_WAIT;
                end
            end

            ST_CLEAR_WAIT: begin
                if (tx_done) begin

                    if (column_index == 127) begin

                        if (page_index == 7) begin
                            state <= ST_TEXT_PAGE;
                        end
                        else begin
                            page_index <= page_index + 1'b1;
                            state <= ST_PAGE_SEND;
                        end

                    end
                    else begin
                        column_index <= column_index + 1'b1;
                        state <= ST_CLEAR_SEND;
                    end

                end
            end

            // SET TEXT PAGE 3

            ST_TEXT_PAGE: begin
                if (!i2c_busy) begin
                    packet1 <= 8'h00;
                    packet2 <= 8'hB3;
                    tx_start <= 1'b1;
                    state <= ST_TEXT_LOW;
                end
            end

            ST_TEXT_LOW: begin
                if (tx_done) begin
                    packet1 <= 8'h00;
                    packet2 <= 8'h09;
                    tx_start <= 1'b1;
                    state <= ST_TEXT_HIGH;
                end
            end

            ST_TEXT_HIGH: begin
                if (tx_done) begin
                    packet1 <= 8'h00;
                    packet2 <= 8'h10;
                    tx_start <= 1'b1;
                    text_index <= 0;
                    text_column <= 0;
                    state <= ST_TEXT_SEND;
                end
            end

            // SEND CHARACTER COLUMNS

            ST_TEXT_SEND: begin
                if (!i2c_busy) begin

                    packet1 <= 8'h40;

                    if (text_column == 5)
                        packet2 <= 8'h00;
                    else
                        packet2 <= glyph_col(
                            text_character(text_index),
                            text_column
                        );

                    tx_start <= 1'b1;
                    state <= ST_TEXT_WAIT;

                end
            end

            ST_TEXT_WAIT: begin
                if (tx_done) begin

                    if (text_column == 5) begin

                        text_column <= 0;

                        if (text_index == 12)
                            state <= ST_DONE;
                        else begin
                            text_index <= text_index + 1'b1;
                            state <= ST_TEXT_SEND;
                        end

                    end
                    else begin
                        text_column <= text_column + 1'b1;
                        state <= ST_TEXT_SEND;
                    end

                end
            end

            ST_DONE: begin
                state <= ST_DONE;
            end

            default:
                state <= ST_BOOT;

        endcase

    end

endmodule
