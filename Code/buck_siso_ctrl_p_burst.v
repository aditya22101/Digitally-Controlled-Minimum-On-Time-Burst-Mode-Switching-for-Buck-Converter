`timescale 1ns / 1ps

module buck_siso_ctrl_p_burst #(
    parameter integer F_CLK_HZ = 50_000_000,
    parameter integer F_PWM_HZ = 100_000,
    parameter integer PWM_TOP  = 499,

    parameter integer BASE_DUTY_PCT = 60,
    parameter signed [15:0] Kp_Q8 = 16'd256,
    parameter signed [15:0] P_MAX = 16'sd512,
    parameter signed [15:0] P_MIN = -16'sd512,

    parameter [11:0] V_HIGH_CODE = 12'd1099,
    parameter [11:0] V_LOW_CODE  = 12'd1078,

    parameter START_ENABLED = 1
)(
    input  wire clk,
    input  wire reset,
    input  wire [11:0] adc_in,

    output wire pwm_output,
    output wire burst_enable,
    output wire burst_output,
    output wire final_output
);

    localparam integer PWM_DIV = (F_CLK_HZ / (F_PWM_HZ * (PWM_TOP+1))) < 1 ? 1 :
                                  (F_CLK_HZ / (F_PWM_HZ * (PWM_TOP+1)));

    reg [$clog2(PWM_DIV):0] divcnt = 0;
    reg pwm_tick = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin divcnt <= 0; pwm_tick <= 0; end
        else if (divcnt == PWM_DIV-1) begin divcnt <= 0; pwm_tick <= 1; end
        else begin divcnt <= divcnt + 1; pwm_tick <= 0; end
    end

    reg [$clog2(PWM_TOP+1)-1:0] pwm_cnt = 0;
    always @(posedge clk or posedge reset) begin
        if (reset) pwm_cnt <= 0;
        else if (pwm_tick)
            pwm_cnt <= (pwm_cnt == PWM_TOP) ? 0 : pwm_cnt + 1;
    end

    localparam integer BASE_DUTY = (BASE_DUTY_PCT * (PWM_TOP+1)) / 100;

    reg signed [12:0] error_s;
    reg signed [31:0] p_prod;
    reg signed [15:0] p_q8, p_sat;
    reg signed [19:0] duty_cand;
    reg [$clog2(PWM_TOP+1)-1:0] duty_req = BASE_DUTY;

    always @(posedge clk or posedge reset) begin
        if (reset) duty_req <= BASE_DUTY;
        else if (pwm_tick && pwm_cnt == 0) begin
            error_s <= -$signed({1'b0, adc_in});
            p_prod  <= Kp_Q8 * error_s;
            p_q8    <= p_prod[23:8];

            if      (p_q8 > P_MAX) p_sat <= P_MAX;
            else if (p_q8 < P_MIN) p_sat <= P_MIN;
            else                  p_sat <= p_q8;

            duty_cand = BASE_DUTY + p_sat;

            if (duty_cand <= 0) duty_req <= 0;
            else if (duty_cand >= PWM_TOP) duty_req <= PWM_TOP;
            else duty_req <= duty_cand;
        end
    end

    wire pwm_raw = (pwm_cnt <= duty_req);

    reg burst_en;
    always @(posedge clk or posedge reset) begin
        if (reset) burst_en <= START_ENABLED;
        else if (pwm_tick && pwm_cnt == 0) begin
            if (adc_in >= V_HIGH_CODE) burst_en <= 0;
            else if (adc_in <= V_LOW_CODE) burst_en <= 1;
        end
    end

    assign burst_enable = burst_en;
    assign pwm_output   = pwm_raw & burst_en;

    localparam BURST_ON = 3, BURST_OFF = 4, PERIOD = BURST_ON + BURST_OFF;
    reg [$clog2(PERIOD)-1:0] phase = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) phase <= 0;
        else if (pwm_tick && pwm_cnt == 0) begin
            if (!burst_en) phase <= 0;
            else phase <= (phase == PERIOD-1) ? 0 : phase + 1;
        end
    end

    wire in_packet = (phase < BURST_ON);
    assign burst_output = burst_en ? (in_packet ? pwm_raw : 0) : pwm_output;
    assign final_output = burst_en ? burst_output : pwm_output;

endmodule