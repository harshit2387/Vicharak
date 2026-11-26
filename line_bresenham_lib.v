
// ============================================================
// Project : FPGA Bresenham Line Renderer
// Board   : Vicharak Shrike-Lite (1120 LUT)
// Display : ST7789 240x240 RGB565
//
// Background : RED
// Line       : WHITE
//
// Architecture:
// ST7789 Stream -> Pixel Coordinates -> Bresenham Renderer
//                -> RGB565 -> ST7789 SPI
// ============================================================

(* top *)

module mux21 #(

    parameter integer CLK_HZ = 50000000,

    parameter [15:0] LCD_WIDTH  = 16'd240,
    parameter [15:0] LCD_HEIGHT = 16'd240,

    parameter [15:0] SPI_HALF_PERIOD = 16'd25,

    parameter [7:0] MADCTL_VAL = 8'h00,
    parameter [7:0] COLMOD_VAL = 8'h55,

    // LINE START
    parameter [15:0] LINE_X0 = 16'd20,
    parameter [15:0] LINE_Y0 = 16'd20,

    // LINE END
    parameter [15:0] LINE_X1 = 16'd200,
    parameter [15:0] LINE_Y1 = 16'd150,

    // RGB565 COLORS
    parameter [15:0] LINE_COLOR = 16'hFFFF,
    parameter [15:0] BACKGROUND_COLOR = 16'hF800,

    parameter integer CS_PIN_PRESENT = 1,
    parameter integer RESET_PIN_PRESENT = 1,

    parameter integer X_OFFSET = 0,
    parameter integer Y_OFFSET = 0

)(

    (* iopad_external_pin, clkbuf_inhibit *)
    input wire clk,

    (* iopad_external_pin *)
    output wire clk_en,

    (* iopad_external_pin *)
    output wire lcd_sck,

    (* iopad_external_pin *)
    output wire lcd_sck_oe,

    (* iopad_external_pin *)
    output wire lcd_mosi,

    (* iopad_external_pin *)
    output wire lcd_mosi_oe,

    (* iopad_external_pin *)
    output wire lcd_cs_n,

    (* iopad_external_pin *)
    output wire lcd_cs_n_oe,

    (* iopad_external_pin *)
    output wire lcd_dc,

    (* iopad_external_pin *)
    output wire lcd_dc_oe,

    (* iopad_external_pin *)
    output wire lcd_reset_n,

    (* iopad_external_pin *)
    output wire lcd_reset_n_oe,

    (* iopad_external_pin *)
    output wire lcd_backlight,

    (* iopad_external_pin *)
    output wire lcd_backlight_oe

);

    // ========================================================
    // CLOCK CONFIGURATION
    // ========================================================

    function integer clog2;

        input integer value;

        integer v;

        begin

            v = value - 1;
            clog2 = 0;

            while (v > 0) begin

                clog2 = clog2 + 1;
                v = v >> 1;

            end

            if (clog2 < 1)
                clog2 = 1;

        end

    endfunction

    localparam integer SPI_HZ =
        CLK_HZ / (2 * SPI_HALF_PERIOD);

    localparam integer DISPLAY_MAX_DIM =
        (LCD_WIDTH > LCD_HEIGHT) ?
        LCD_WIDTH : LCD_HEIGHT;

    localparam integer COORD_BITS =
        clog2(DISPLAY_MAX_DIM);

    localparam [15:0] X_END =
        LCD_WIDTH - 16'd1;

    localparam [15:0] Y_END =
        LCD_HEIGHT - 16'd1;


    // ========================================================
    // DISPLAY SIGNALS
    // ========================================================

    reg logic_rst_n = 1'b0;

    wire start_ready;

    wire [15:0] pixel_x;
    wire [15:0] pixel_y;

    wire pixel_active;

    wire display_busy;
    wire display_done;
    wire init_done;

    reg [15:0] pixel_rgb565;


    // ========================================================
    // BRESENHAM CONSTANTS
    // ========================================================

    // 9-bit coordinates

    localparam [8:0] X0_C = LINE_X0[8:0];
    localparam [8:0] Y0_C = LINE_Y0[8:0];

    localparam [8:0] X1_C = LINE_X1[8:0];
    localparam [8:0] Y1_C = LINE_Y1[8:0];

    // Absolute X distance

    localparam [8:0] DX_ABS =
        (X1_C >= X0_C) ?
        (X1_C - X0_C) :
        (X0_C - X1_C);

    // Absolute Y distance

    localparam [8:0] DY_ABS =
        (Y1_C >= Y0_C) ?
        (Y1_C - Y0_C) :
        (Y0_C - Y1_C);

    // Major axis

    localparam [8:0] MAJOR =
        (DX_ABS >= DY_ABS) ?
        DX_ABS : DY_ABS;


    // ========================================================
    // COORDINATE-BASED BRESENHAM RENDERER
    // ========================================================

    function line_contains;

        input [15:0] px;
        input [15:0] py;

        reg [8:0] qx;
        reg [8:0] qy;

        reg [17:0] product_x;
        reg [17:0] product_y;

        reg signed [18:0] cross2;

        begin

            line_contains = 1'b0;

            qx = 9'd0;
            qy = 9'd0;

            product_x = 18'd0;
            product_y = 18'd0;

            cross2 = 19'sd0;

            // ----------------------------------------
            // CHECK DISPLAY COORDINATES
            // ----------------------------------------

            if ((px < LCD_WIDTH) &&
                (py < LCD_HEIGHT)) begin

                // ------------------------------------
                // BOUNDING BOX
                // ------------------------------------

                if ((px[8:0] >=
                    ((X0_C < X1_C) ? X0_C : X1_C)) &&

                    (px[8:0] <=
                    ((X0_C > X1_C) ? X0_C : X1_C)) &&

                    (py[8:0] >=
                    ((Y0_C < Y1_C) ? Y0_C : Y1_C)) &&

                    (py[8:0] <=
                    ((Y0_C > Y1_C) ? Y0_C : Y1_C))) begin

                    // --------------------------------
                    // NORMALIZED COORDINATES
                    // --------------------------------

                    if (X1_C >= X0_C)
                        qx = px[8:0] - X0_C;
                    else
                        qx = X0_C - px[8:0];

                    if (Y1_C >= Y0_C)
                        qy = py[8:0] - Y0_C;
                    else
                        qy = Y0_C - py[8:0];

                    // --------------------------------
                    // SINGLE PIXEL LINE
                    // --------------------------------

                    if (MAJOR == 0) begin

                        line_contains =
                            ((px[8:0] == X0_C) &&
                             (py[8:0] == Y0_C));

                    end

                    else begin

                        // --------------------------------
                        // CROSS PRODUCT
                        // --------------------------------

                        product_x = qy * DX_ABS;

                        product_y = qx * DY_ABS;

                        cross2 =
                            ($signed({1'b0,product_x}) -
                             $signed({1'b0,product_y})) <<< 1;

                        // --------------------------------
                        // BRESENHAM NEAREST-PIXEL TEST
                        // --------------------------------

                        if ((cross2 >
                             -$signed({10'd0,MAJOR})) &&

                            (cross2 <=
                             $signed({10'd0,MAJOR}))) begin

                            line_contains = 1'b1;

                        end

                    end

                end

            end

        end

    endfunction


    // ========================================================
    // RGB565 COLOR GENERATOR
    // ========================================================

    always @* begin

        pixel_rgb565 = BACKGROUND_COLOR;

        if (line_contains(pixel_x, pixel_y)) begin

            pixel_rgb565 = LINE_COLOR;

        end

    end


    // ========================================================
    // FPGA OUTPUT ENABLES
    // ========================================================

    assign clk_en = 1'b1;

    assign lcd_sck_oe = 1'b1;
    assign lcd_mosi_oe = 1'b1;

    assign lcd_cs_n_oe = 1'b1;
    assign lcd_dc_oe = 1'b1;

    assign lcd_reset_n_oe = 1'b1;

    assign lcd_backlight = 1'b1;
    assign lcd_backlight_oe = 1'b1;


    // ========================================================
    // RESET GENERATION
    // ========================================================

    always @(posedge clk)

        logic_rst_n <= 1'b1;


    // ========================================================
    // ST7789 DISPLAY DRIVER
    // ========================================================

    shrike_gfx_st7789 #(

        .CLK_HZ(CLK_HZ),

        .SPI_HZ(SPI_HZ),

        .CS_PIN_PRESENT(CS_PIN_PRESENT),

        .RESET_PIN_PRESENT(RESET_PIN_PRESENT),

        .X_OFFSET(X_OFFSET),

        .Y_OFFSET(Y_OFFSET),

        .MADCTL_VAL(MADCTL_VAL),

        .COLMOD_VAL(COLMOD_VAL),

        .COORD_BITS(COORD_BITS)

    ) display (

        .clk(clk),

        .rst_n(logic_rst_n),

        .start(start_ready),

        .start_ready(start_ready),

        .win_x0(16'd0),

        .win_y0(16'd0),

        .win_x1(X_END),

        .win_y1(Y_END),

        .pixel_x(pixel_x),

        .pixel_y(pixel_y),

        .pixel_active(pixel_active),

        .pixel_rgb565(pixel_rgb565),

        .busy(display_busy),

        .done(display_done),

        .init_done(init_done),

        .spi_sck(lcd_sck),

        .spi_mosi(lcd_mosi),

        .display_cs_n(lcd_cs_n),

        .display_dc(lcd_dc),

        .display_rst_n(lcd_reset_n)

    );

endmodule
