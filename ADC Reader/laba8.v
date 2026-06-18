module laba8
(
input wire CLOCK_50,
input  wire [1:0]  KEY,
output wire ADC_CONVST,
output wire ADC_SCK,
output wire ADC_SDI,
input  wire ADC_SDO,
output wire [7:0] LED,
output reg [6:0] SEG,
output reg [3:0] DIG
);

wire reset_n = KEY[0];

reg [15:0] auto_cnt = 0;
reg auto_start = 0;

always @(posedge CLOCK_50 or negedge reset_n) begin
    if (!reset_n) begin
        auto_cnt  <= 0;
        auto_start <= 0;
    end else begin
        if (auto_cnt == 50000 - 1) begin
            auto_cnt <= 0;
            auto_start <= 1;
        end else begin
            auto_cnt <= auto_cnt + 1;
            auto_start <= 0;
        end
    end
end

wire [11:0] adc_result;
wire adc_valid;

adc_ltc2308 u_adc 
(
    .clk (CLOCK_50),
    .reset_n (reset_n),
    .start (auto_start),
    .adc_convst (ADC_CONVST),
    .adc_sck (ADC_SCK),
    .adc_sdi (ADC_SDI),
    .adc_sdo (ADC_SDO),
    .result (adc_result),
    .valid (adc_valid)
);

reg [11:0] voltage_mv = 0;

always @(posedge CLOCK_50 or negedge reset_n) begin
    if (!reset_n)
        voltage_mv <= 0;
    else if (adc_valid)
        voltage_mv <= adc_result;
end

assign LED[0] = adc_valid;
assign LED[1] = ADC_CONVST;
assign LED[2] = ADC_SCK;
assign LED[3] = ADC_SDO;
assign LED[7:4] = voltage_mv[11:8];

wire [3:0] d3 = voltage_mv / 1000;
wire [3:0] d2 = (voltage_mv % 1000) / 100;
wire [3:0] d1 = (voltage_mv % 100)  / 10;
wire [3:0] d0 = voltage_mv % 10;

reg [16:0] mux_cnt = 0;
reg [1:0]  mux_sel = 0;

always @(posedge CLOCK_50 or negedge reset_n) begin
    if (!reset_n) begin
        mux_cnt <= 0;
        mux_sel <= 0;
    end else begin
        if (mux_cnt == 25000 - 1) begin
            mux_cnt <= 0;
            mux_sel <= mux_sel + 1;
        end else
            mux_cnt <= mux_cnt + 1;
    end
end

always @(*) begin
    case (mux_sel)
        2'd0: DIG = 4'b1110;
        2'd1: DIG = 4'b1101;
        2'd2: DIG = 4'b1011;
        2'd3: DIG = 4'b0111;
    endcase
end


reg [3:0] cur_digit;
always @(*) begin
    case (mux_sel)
        2'd0: cur_digit = d0;
        2'd1: cur_digit = d1;
        2'd2: cur_digit = d2;
        2'd3: cur_digit = d3;
    endcase
end

always @(*) begin
    case (cur_digit)
        4'd0: SEG = 7'b0111111;
        4'd1: SEG = 7'b0000110;
        4'd2: SEG = 7'b1011011;
        4'd3: SEG = 7'b1001111;
        4'd4: SEG = 7'b1100110;
        4'd5: SEG = 7'b1101101;
        4'd6: SEG = 7'b1111101;
        4'd7: SEG = 7'b0000111;
        4'd8: SEG = 7'b1111111;
        4'd9: SEG = 7'b1101111;
        default: SEG = 7'b0000000;
    endcase
end

endmodule
