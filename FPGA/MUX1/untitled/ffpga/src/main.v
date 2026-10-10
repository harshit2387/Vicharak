`timescale 1ns / 1ps

module top (
    input  wire       clk,
    input  wire       mcu_cs,
    input  wire       mcu_rd_wr,
    inout  wire [7:0] mcu_data,
    output reg        fpga_ready,
    output reg        user_led
);

    // Internal storage for the MCU data byte
    reg [7:0] data_register;

    // Write operation: Capture MCU data on the rising edge of clk
    // Condition: MCU must actively assert CS (low) and write command (low)
    always @(posedge clk) begin
        if (!mcu_cs) begin
            if (!mcu_rd_wr) begin
                data_register <= mcu_data;
            end
        end
    end

    // Output and status generation
    always @(posedge clk) begin
        fpga_ready <= 1'b1;
        user_led   <= data_register[0];
    end

    // Read operation / Tri-state buffer control:
    // If CS is active (low) and read is requested (high), drive the bus with data_register.
    // Otherwise, release the bus (high-impedance 'z').
    assign mcu_data = (!mcu_cs && mcu_rd_wr) ? data_register : 8'bzzzzzzzz;

endmodule
