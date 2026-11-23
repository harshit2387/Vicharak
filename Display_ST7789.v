(* top *)
module mux21 #(
    parameter integer CLK_HZ             = 50000000,
    parameter [15:0]  LCD_WIDTH          = 16'd240,
    parameter [15:0]  LCD_HEIGHT         = 16'd240,
    parameter [15:0]  SPI_HALF_PERIOD    = 16'd25,
    parameter [7:0]   MADCTL_VAL         = 8'h00,
    parameter [7:0]   COLMOD_VAL         = 8'h55,
    parameter [15:0]  FILL_COLOR         = 16'hF800,
    parameter         BACKLIGHT_ON       = 1'b1,
    parameter         BACKLIGHT_OFF      = 1'b0
) (
    (* iopad_external_pin, clkbuf_inhibit *) input wire clk,
    (* iopad_external_pin *) output wire clk_en,

    (* iopad_external_pin *) output wire lcd_sck,
    (* iopad_external_pin *) output wire lcd_sck_oe,
    (* iopad_external_pin *) output wire lcd_mosi,
    (* iopad_external_pin *) output wire lcd_mosi_oe,
    (* iopad_external_pin *) output wire lcd_cs_n,
    (* iopad_external_pin *) output wire lcd_cs_n_oe,
    (* iopad_external_pin *) output wire lcd_dc,
    (* iopad_external_pin *) output wire lcd_dc_oe,
    (* iopad_external_pin *) output wire lcd_reset_n,
    (* iopad_external_pin *) output wire lcd_reset_n_oe,
    (* iopad_external_pin *) output wire lcd_backlight,
    (* iopad_external_pin *) output wire lcd_backlight_oe
);

    localparam [3:0]
        ST_POR        = 4'd0,
        ST_PWR_WAIT   = 4'd1,
        ST_RST_LOW    = 4'd2,
        ST_RST_POST   = 4'd3,
        ST_STEP_SETUP = 4'd4,
        ST_STEP_START = 4'd5,
        ST_STEP_WAIT  = 4'd6,
        ST_STEP_DELAY = 4'd7,
        ST_PIX_SETUP  = 4'd8,
        ST_PIX_HI     = 4'd9,
        ST_PIX_HI_W   = 4'd10,
        ST_PIX_LO     = 4'd11,
        ST_PIX_LO_W   = 4'd12,
        ST_DONE       = 4'd13;

    reg [3:0]  state     = ST_POR;
    reg [31:0] wait_cnt  = 32'd0;
    reg [4:0]  step_idx  = 5'd0;
    reg [31:0] pixel_cnt = 32'd0;

    reg cs_n_r  = 1'b1;
    reg dc_r    = 1'b0;
    reg rst_n_r = 1'b1;
    reg bl_r    = BACKLIGHT_ON;

    reg       tx_start = 1'b0;
    reg [7:0] tx_data  = 8'h00;

    wire tx_busy;
    wire tx_done;
    wire sck_w;
    wire mosi_w;

    wire [15:0] x_end =
        (LCD_WIDTH != 16'd0) ? (LCD_WIDTH - 16'd1) : 16'd0;

    wire [15:0] y_end =
        (LCD_HEIGHT != 16'd0) ? (LCD_HEIGHT - 16'd1) : 16'd0;

    wire [31:0] total_pixels =
        ({16'd0, LCD_WIDTH} * {16'd0, LCD_HEIGHT});

    assign clk_en           = 1'b1;
    assign lcd_sck_oe        = 1'b1;
    assign lcd_mosi_oe       = 1'b1;
    assign lcd_cs_n_oe       = 1'b1;
    assign lcd_dc_oe         = 1'b1;
    assign lcd_reset_n_oe    = 1'b1;
    assign lcd_backlight_oe  = 1'b1;

    assign lcd_sck       = sck_w;
    assign lcd_mosi      = mosi_w;
    assign lcd_cs_n      = cs_n_r;
    assign lcd_dc        = dc_r;
    assign lcd_reset_n   = rst_n_r;
    assign lcd_backlight = bl_r;

    spi_byte_tx #(
        .HALF_PERIOD(SPI_HALF_PERIOD)
    ) u_spi (
        .clk   (clk),
        .rst   (state == ST_POR),
        .start (tx_start),
        .data  (tx_data),
        .sck   (sck_w),
        .mosi  (mosi_w),
        .busy  (tx_busy),
        .done  (tx_done)
    );

    function [31:0] ms_ticks;
        input integer ms;
        reg [31:0] ticks;
        begin
            ticks = (CLK_HZ / 1000) * ms;
            ms_ticks = (ticks != 32'd0) ? (ticks - 32'd1) : 32'd0;
        end
    endfunction

    function step_is_data;
        input [4:0] idx;
        begin
            case (idx)
                5'd3, 5'd5,
                5'd10, 5'd11, 5'd12, 5'd13,
                5'd15, 5'd16, 5'd17, 5'd18:
                    step_is_data = 1'b1;
                default:
                    step_is_data = 1'b0;
            endcase
        end
    endfunction

    // Keep CS low from each parameterized command through its final parameter.
    // Also keep it low across RAMWR and the following pixel stream.
    function step_keep_cs_low;
        input [4:0] idx;
        begin
            case (idx)
                5'd2, 5'd4,
                5'd9, 5'd10, 5'd11, 5'd12,
                5'd14, 5'd15, 5'd16, 5'd17,
                5'd19:
                    step_keep_cs_low = 1'b1;
                default:
                    step_keep_cs_low = 1'b0;
            endcase
        end
    endfunction

    function [7:0] step_byte;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:    step_byte = 8'h01;          // SWRESET
                5'd1:    step_byte = 8'h11;          // SLPOUT
                5'd2:    step_byte = 8'h36;          // MADCTL
                5'd3:    step_byte = MADCTL_VAL;
                5'd4:    step_byte = 8'h3A;          // COLMOD
                5'd5:    step_byte = COLMOD_VAL;
                5'd6:    step_byte = 8'h21;          // INVON
                5'd7:    step_byte = 8'h13;          // NORON
                5'd8:    step_byte = 8'h29;          // DISPON
                5'd9:    step_byte = 8'h2A;          // CASET
                5'd10:   step_byte = 8'h00;          // X start high
                5'd11:   step_byte = 8'h00;          // X start low
                5'd12:   step_byte = x_end[15:8];     // X end high
                5'd13:   step_byte = x_end[7:0];      // X end low
                5'd14:   step_byte = 8'h2B;          // RASET
                5'd15:   step_byte = 8'h00;          // Y start high
                5'd16:   step_byte = 8'h00;          // Y start low
                5'd17:   step_byte = y_end[15:8];     // Y end high
                5'd18:   step_byte = y_end[7:0];      // Y end low
                5'd19:   step_byte = 8'h2C;          // RAMWR
                default: step_byte = 8'h00;
            endcase
        end
    endfunction

    function [31:0] step_delay_ticks;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:    step_delay_ticks = ms_ticks(150);
                5'd1:    step_delay_ticks = ms_ticks(120);
                5'd7:    step_delay_ticks = ms_ticks(10);
                5'd8:    step_delay_ticks = ms_ticks(100);
                default: step_delay_ticks = 32'd0;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        tx_start <= 1'b0;

        case (state)
            ST_POR: begin
                cs_n_r  <= 1'b1;
                dc_r    <= 1'b0;
                rst_n_r <= 1'b1;
                bl_r    <= BACKLIGHT_ON;
                wait_cnt <= ms_ticks(20);
                state    <= ST_PWR_WAIT;
            end

            ST_PWR_WAIT: begin
                if (wait_cnt == 32'd0) begin
                    rst_n_r  <= 1'b0;
                    wait_cnt <= ms_ticks(20);
                    state    <= ST_RST_LOW;
                end else begin
                    wait_cnt <= wait_cnt - 32'd1;
                end
            end

            ST_RST_LOW: begin
                if (wait_cnt == 32'd0) begin
                    rst_n_r  <= 1'b1;
                    wait_cnt <= ms_ticks(150);
                    state    <= ST_RST_POST;
                end else begin
                    wait_cnt <= wait_cnt - 32'd1;
                end
            end

            ST_RST_POST: begin
                if (wait_cnt == 32'd0) begin
                    step_idx <= 5'd0;
                    state    <= ST_STEP_SETUP;
                end else begin
                    wait_cnt <= wait_cnt - 32'd1;
                end
            end

            ST_STEP_SETUP: begin
                if (!tx_busy) begin
                    cs_n_r <= 1'b0;
                    dc_r   <= step_is_data(step_idx);
                    state  <= ST_STEP_START;
                end
            end

            ST_STEP_START: begin
                cs_n_r   <= 1'b0;
                dc_r     <= step_is_data(step_idx);
                tx_data  <= step_byte(step_idx);
                tx_start <= 1'b1;
                state    <= ST_STEP_WAIT;
            end

            ST_STEP_WAIT: begin
                if (tx_done) begin
                    if (!step_keep_cs_low(step_idx))
                        cs_n_r <= 1'b1;

                    if (step_delay_ticks(step_idx) != 32'd0) begin
                        wait_cnt <= step_delay_ticks(step_idx);
                        state    <= ST_STEP_DELAY;
                    end else if (step_idx == 5'd19) begin
                        pixel_cnt <= 32'd0;
                        state     <= ST_PIX_SETUP;
                    end else begin
                        step_idx <= step_idx + 5'd1;
                        state    <= ST_STEP_SETUP;
                    end
                end
            end

            ST_STEP_DELAY: begin
                if (wait_cnt == 32'd0) begin
                    if (step_idx == 5'd19) begin
                        pixel_cnt <= 32'd0;
                        state     <= ST_PIX_SETUP;
                    end else begin
                        step_idx <= step_idx + 5'd1;
                        state    <= ST_STEP_SETUP;
                    end
                end else begin
                    wait_cnt <= wait_cnt - 32'd1;
                end
            end

            ST_PIX_SETUP: begin
                if (!tx_busy) begin
                    cs_n_r <= 1'b0;
                    dc_r   <= 1'b1;
                    state  <= ST_PIX_HI;
                end
            end

            ST_PIX_HI: begin
                cs_n_r   <= 1'b0;
                dc_r     <= 1'b1;
                tx_data  <= FILL_COLOR[15:8];
                tx_start <= 1'b1;
                state    <= ST_PIX_HI_W;
            end

            ST_PIX_HI_W: begin
                if (tx_done)
                    state <= ST_PIX_LO;
            end

            ST_PIX_LO: begin
                cs_n_r   <= 1'b0;
                dc_r     <= 1'b1;
                tx_data  <= FILL_COLOR[7:0];
                tx_start <= 1'b1;
                state    <= ST_PIX_LO_W;
            end

            ST_PIX_LO_W: begin
                if (tx_done) begin
                    if ((pixel_cnt + 32'd1) >= total_pixels) begin
                        cs_n_r <= 1'b1;
                        state  <= ST_DONE;
                    end else begin
                        pixel_cnt <= pixel_cnt + 32'd1;
                        state     <= ST_PIX_HI;
                    end
                end
            end

            ST_DONE: begin
                cs_n_r <= 1'b1;
                bl_r   <= BACKLIGHT_ON;
            end

            default: begin
                state <= ST_POR;
            end
        endcase
    end

endmodule


module spi_byte_tx #(
    parameter [15:0] HALF_PERIOD = 16'd25
) (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] data,
    output reg sck,
    output reg mosi,
    output reg busy,
    output reg done
);

    localparam [15:0] DIV_MAX =
        (HALF_PERIOD != 16'd0) ? (HALF_PERIOD - 16'd1) : 16'd0;

    reg [15:0] div_cnt = 16'd0;
    reg [7:0]  shifter = 8'd0;
    reg [2:0]  bit_cnt = 3'd0;

    always @(posedge clk) begin
        done <= 1'b0;

        if (rst) begin
            div_cnt <= 16'd0;
            shifter <= 8'd0;
            bit_cnt <= 3'd0;
            sck     <= 1'b0;
            mosi    <= 1'b0;
            busy    <= 1'b0;
        end else if (!busy) begin
            sck     <= 1'b0;
            div_cnt <= 16'd0;

            if (start) begin
                shifter <= data;
                bit_cnt <= 3'd7;
                mosi    <= data[7];
                busy    <= 1'b1;
            end
        end else if (div_cnt == DIV_MAX) begin
            div_cnt <= 16'd0;

            if (!sck) begin
                sck <= 1'b1;
            end else begin
                sck <= 1'b0;

                if (bit_cnt == 3'd0) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    mosi <= 1'b0;
                end else begin
                    bit_cnt <= bit_cnt - 3'd1;
                    shifter <= {shifter[6:0], 1'b0};
                    mosi    <= shifter[6];
                end
            end
        end else begin
            div_cnt <= div_cnt + 16'd1;
        end
    end
  /*display rendring in red color*/

endmodule
