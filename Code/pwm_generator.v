`timescale 1ns / 1ps

module pwm_generator #(
    parameter integer F_CLK_HZ = 50_000_000,
    parameter integer F_PWM_HZ = 100_000,
    parameter integer PWM_TOP  = 499
)(
    input  wire clk,
    input  wire reset,
    input  wire [$clog2(PWM_TOP+1)-1:0] duty_in,

    output reg pwm_out,
    output reg pwm_tick
);

    localparam integer PWM_DIV = (F_CLK_HZ / (F_PWM_HZ * (PWM_TOP+1))) < 1 ? 1 :
                                  (F_CLK_HZ / (F_PWM_HZ * (PWM_TOP+1)));

    reg [$clog2(PWM_DIV):0] divcnt = 0;
    reg [$clog2(PWM_TOP+1)-1:0] pwm_cnt = 0;

    // Clock divider → generates PWM tick
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            divcnt  <= 0;
            pwm_tick <= 0;
        end else if (divcnt == PWM_DIV-1) begin
            divcnt  <= 0;
            pwm_tick <= 1;
        end else begin
            divcnt  <= divcnt + 1;
            pwm_tick <= 0;
        end
    end

    // PWM counter
    always @(posedge clk or posedge reset) begin
        if (reset)
            pwm_cnt <= 0;
        else if (pwm_tick)
            pwm_cnt <= (pwm_cnt == PWM_TOP) ? 0 : pwm_cnt + 1;
    end

    // PWM output
    always @(posedge clk or posedge reset) begin
        if (reset)
            pwm_out <= 0;
        else
            pwm_out <= (pwm_cnt <= duty_in);
    end

endmodule