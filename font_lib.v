
(* top *)
module mux21 (

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

    // ------------------------------------------------
    // CLOCK AND RESET
    // ------------------------------------------------

    localparam integer CLK_HZ = 50000000;
    localparam integer SPI_HZ = 12500000;

    reg logic_rst_n = 1'b0;

    always @(posedge clk)
        logic_rst_n <= 1'b1;

    assign clk_en = 1'b1;

    // ------------------------------------------------
    // DISPLAY OUTPUT ENABLES
    // ------------------------------------------------

    assign lcd_sck_oe       = 1'b1;
    assign lcd_mosi_oe      = 1'b1;
    assign lcd_cs_n_oe      = 1'b1;
    assign lcd_dc_oe        = 1'b1;
    assign lcd_reset_n_oe   = 1'b1;
    assign lcd_backlight_oe = 1'b1;

    assign lcd_backlight = 1'b1;

    // ------------------------------------------------
    // INTERNAL DISPLAY SIGNALS
    // ------------------------------------------------

    wire spi_sck;
    wire spi_mosi;
    wire display_cs_n;
    wire display_dc;
    wire display_rst_n;

    wire [15:0] pixel_x;
    wire [15:0] pixel_y;

    wire pixel_active;
    wire [15:0] pixel_rgb565;

    wire busy;
    wire done;
    wire init_done;
    wire start_ready;

    // ------------------------------------------------
    // MAP INTERNAL SIGNALS TO BOARD PINS
    // ------------------------------------------------

    assign lcd_sck     = spi_sck;
    assign lcd_mosi    = spi_mosi;
    assign lcd_cs_n    = display_cs_n;
    assign lcd_dc      = display_dc;
    assign lcd_reset_n = display_rst_n;

    // ------------------------------------------------
    // GRAPHICS RENDERER
    // ------------------------------------------------

    harshit_menu_shader menu (

        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_rgb565(pixel_rgb565)

    );

    // ------------------------------------------------
    // ONE-TIME FULL-SCREEN DRAW
    // ------------------------------------------------

    reg start = 1'b0;
    reg frame_started = 1'b0;

    always @(posedge clk) begin

        if (!logic_rst_n) begin
            start <= 1'b0;
            frame_started <= 1'b0;
        end
        else begin

            start <= 1'b0;

            if (init_done && start_ready && !frame_started) begin
                start <= 1'b1;
                frame_started <= 1'b1;
            end

        end

    end

    // ------------------------------------------------
    // YOUR EXISTING ST7789 LIBRARY
    // ------------------------------------------------

    shrike_gfx_st7789 #(

        .CLK_HZ(CLK_HZ),
        .SPI_HZ(SPI_HZ),

        .CS_PIN_PRESENT(1),
        .RESET_PIN_PRESENT(1),

        .X_OFFSET(0),
        .Y_OFFSET(0),

        .MADCTL_VAL(8'h00),
        .COLMOD_VAL(8'h55),

        .COORD_BITS(9)

    ) display (

        .clk(clk),
        .rst_n(logic_rst_n),

        .start(start),
        .start_ready(start_ready),

        .win_x0(16'd0),
        .win_y0(16'd0),
        .win_x1(16'd239),
        .win_y1(16'd239),

        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_active(pixel_active),

        .pixel_rgb565(pixel_rgb565),

        .busy(busy),
        .done(done),
        .init_done(init_done),

        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),

        .display_cs_n(display_cs_n),
        .display_dc(display_dc),
        .display_rst_n(display_rst_n)

    );

endmodule


// ====================================================
// HARSHIT MENU SHADER
// Uses the existing widget_text_rom.v
// ====================================================

module harshit_menu_shader (

    input wire [15:0] pixel_x,
    input wire [15:0] pixel_y,

    output reg [15:0] pixel_rgb565

);

    // ------------------------------------------------
    // COLORS: RGB565
    // ------------------------------------------------

    localparam [15:0] BACKGROUND = 16'h0841;
    localparam [15:0] MENU_BLUE  = 16'h18E3;
    localparam [15:0] CYAN       = 16'h07FF;
    localparam [15:0] WHITE      = 16'hFFFF;
    localparam [15:0] GREY       = 16'h7BEF;

    // ------------------------------------------------
    // TITLE POSITION
    // ------------------------------------------------

    // 5x7 font, enlarged by 4.
    // Character cell width = 24 pixels.
    // Seven characters = 168 pixels.
    // Starting X = 36.

    localparam [15:0] TEXT_X = 16'd36;
    localparam [15:0] TEXT_Y = 16'd100;

    wire [15:0] rel_y;
    wire [2:0] glyph_y;

    assign rel_y = pixel_y - TEXT_Y;
    assign glyph_y = rel_y[4:2];

    // ------------------------------------------------
    // CHARACTER X COORDINATES
    // ------------------------------------------------

    wire [15:0] x_h1;
    wire [15:0] x_a;
    wire [15:0] x_r;
    wire [15:0] x_s;
    wire [15:0] x_h2;
    wire [15:0] x_i;
    wire [15:0] x_t;

    assign x_h1 = pixel_x - 16'd36;
    assign x_a  = pixel_x - 16'd60;
    assign x_r  = pixel_x - 16'd84;
    assign x_s  = pixel_x - 16'd108;
    assign x_h2 = pixel_x - 16'd132;
    assign x_i  = pixel_x - 16'd156;
    assign x_t  = pixel_x - 16'd180;

    wire [2:0] gx_h1 = x_h1[4:2];
    wire [2:0] gx_a  = x_a[4:2];
    wire [2:0] gx_r  = x_r[4:2];
    wire [2:0] gx_s  = x_s[4:2];
    wire [2:0] gx_h2 = x_h2[4:2];
    wire [2:0] gx_i  = x_i[4:2];
    wire [2:0] gx_t  = x_t[4:2];

    // ------------------------------------------------
    // FONT ROM OUTPUTS
    // ------------------------------------------------

    wire p_h1;
    wire p_a;
    wire p_r;
    wire p_s;
    wire p_h2;
    wire p_i;
    wire p_t;

    // ------------------------------------------------
    // EXISTING FONT ROM INSTANCES
    // ------------------------------------------------

    widget_text_rom font_h1 (
        .char_code("H"),
        .glyph_x(gx_h1),
        .glyph_y(glyph_y),
        .pixel_on(p_h1)
    );

    widget_text_rom font_a (
        .char_code("A"),
        .glyph_x(gx_a),
        .glyph_y(glyph_y),
        .pixel_on(p_a)
    );

    widget_text_rom font_r (
        .char_code("R"),
        .glyph_x(gx_r),
        .glyph_y(glyph_y),
        .pixel_on(p_r)
    );

    widget_text_rom font_s (
        .char_code("S"),
        .glyph_x(gx_s),
        .glyph_y(glyph_y),
        .pixel_on(p_s)
    );

    widget_text_rom font_h2 (
        .char_code("H"),
        .glyph_x(gx_h2),
        .glyph_y(glyph_y),
        .pixel_on(p_h2)
    );

    widget_text_rom font_i (
        .char_code("I"),
        .glyph_x(gx_i),
        .glyph_y(glyph_y),
        .pixel_on(p_i)
    );

    widget_text_rom font_t (
        .char_code("T"),
        .glyph_x(gx_t),
        .glyph_y(glyph_y),
        .pixel_on(p_t)
    );

    // ------------------------------------------------
    // CHARACTER REGION DETECTION
    // ------------------------------------------------

    wire valid_y;
    wire hit_h1;
    wire hit_a;
    wire hit_r;
    wire hit_s;
    wire hit_h2;
    wire hit_i;
    wire hit_t;

    assign valid_y = (pixel_y >= TEXT_Y) &&
                     (rel_y < 16'd28);

    assign hit_h1 = valid_y && (x_h1 < 16'd20);
    assign hit_a  = valid_y && (x_a  < 16'd20) &&
                    (pixel_x >= 16'd60);
    assign hit_r  = valid_y && (x_r  < 16'd20) &&
                    (pixel_x >= 16'd84);
    assign hit_s  = valid_y && (x_s  < 16'd20) &&
                    (pixel_x >= 16'd108);
    assign hit_h2 = valid_y && (x_h2 < 16'd20) &&
                    (pixel_x >= 16'd132);
    assign hit_i  = valid_y && (x_i  < 16'd20) &&
                    (pixel_x >= 16'd156);
    assign hit_t  = valid_y && (x_t  < 16'd20) &&
                    (pixel_x >= 16'd180);

    wire title_pixel;

    assign title_pixel =
        (hit_h1 && p_h1) ||
        (hit_a  && p_a)  ||
        (hit_r  && p_r)  ||
        (hit_s  && p_s)  ||
        (hit_h2 && p_h2) ||
        (hit_i  && p_i)  ||
        (hit_t  && p_t);

    // ------------------------------------------------
    // MENU DESIGN
    // ------------------------------------------------

    always @* begin

        pixel_rgb565 = BACKGROUND;

        // Top menu bar
        if (pixel_y < 16'd34)
            pixel_rgb565 = MENU_BLUE;

        // Cyan separator
        if ((pixel_y >= 16'd34) &&
            (pixel_y < 16'd38))
            pixel_rgb565 = CYAN;

        // Small menu indicator
        if ((pixel_x >= 16'd14) &&
            (pixel_x < 16'd22) &&
            (pixel_y >= 16'd13) &&
            (pixel_y < 16'd21))
            pixel_rgb565 = CYAN;

        // Small decorative block on right
        if ((pixel_x >= 16'd218) &&
            (pixel_x < 16'd226) &&
            (pixel_y >= 16'd13) &&
            (pixel_y < 16'd21))
            pixel_rgb565 = CYAN;

        // Main title
        if (title_pixel)
            pixel_rgb565 = WHITE;

        // Decorative underline
        if ((pixel_x >= 16'd65) &&
            (pixel_x < 16'd175) &&
            (pixel_y >= 16'd143) &&
            (pixel_y < 16'd146))
            pixel_rgb565 = CYAN;

        // Small center accent
        if ((pixel_x >= 16'd112) &&
            (pixel_x < 16'd128) &&
            (pixel_y >= 16'd158) &&
            (pixel_y < 16'd162))
            pixel_rgb565 = GREY;

    end

endmodule
