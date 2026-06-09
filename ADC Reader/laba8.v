module laba8 (
    input  wire        CLOCK_50,
    input  wire [1:0]  KEY,
    // ADC (пины из мануала Table 3-12)
    output wire        ADC_CONVST,
    output wire        ADC_SCK,
    output wire        ADC_SDI,
    input  wire        ADC_SDO,
    // 7-сегментный дисплей
    output reg  [6:0]  SEG,
    output reg  [3:0]  DIG
);

// -------------------------------------------------------
// Сброс по KEY[0] (active-low)
// -------------------------------------------------------
wire reset_n = KEY[0];

// -------------------------------------------------------
// Генератор старта ADC — каждые ~1мс
// -------------------------------------------------------
reg [15:0] auto_cnt   = 0;
reg        auto_start = 0;

always @(posedge CLOCK_50 or negedge reset_n) begin
    if (!reset_n) begin
        auto_cnt   <= 0;
        auto_start <= 0;
    end else begin
        if (auto_cnt == 50000 - 1) begin
            auto_cnt   <= 0;
            auto_start <= 1;
        end else begin
            auto_cnt   <= auto_cnt + 1;
            auto_start <= 0;
        end
    end
end

// -------------------------------------------------------
// ADC контроллер
// -------------------------------------------------------
wire [11:0] adc_result;
wire        adc_valid;

adc_ltc2308 u_adc (
    .clk        (CLOCK_50),
    .reset_n    (reset_n),
    .start      (auto_start),
    .adc_convst (ADC_CONVST),
    .adc_sck    (ADC_SCK),
    .adc_sdi    (ADC_SDI),
    .adc_sdo    (ADC_SDO),
    .result     (adc_result),
    .valid      (adc_valid)
);

// -------------------------------------------------------
// Сохраняем последнее значение ADC
// adc_result [0..4095] = напряжение [0..4095] мВ
// при Vref = 4.096V: 1 LSB = 1 мВ
// -------------------------------------------------------
reg [11:0] voltage_mv = 0;

always @(posedge CLOCK_50 or negedge reset_n) begin
    if (!reset_n)
        voltage_mv <= 0;
    else if (adc_valid)
        voltage_mv <= adc_result;
end

// -------------------------------------------------------
// Разбивка на десятичные цифры (0000..4095 мВ)
// -------------------------------------------------------
wire [3:0] d3 = voltage_mv / 1000;
wire [3:0] d2 = (voltage_mv % 1000) / 100;
wire [3:0] d1 = (voltage_mv % 100)  / 10;
wire [3:0] d0 = voltage_mv % 10;

// -------------------------------------------------------
// Мультиплексирование дисплея
// Переключаем цифры каждые 25000 тактов = каждые 0.5мс
// Полный цикл 4 цифры = 2мс → глаз видит все одновременно
// -------------------------------------------------------
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

// -------------------------------------------------------
// Выбор активной цифры (active-low: Common Anode)
// -------------------------------------------------------
always @(*) begin
    case (mux_sel)
        2'd0: DIG = 4'b1110;  // единицы   (правая)
        2'd1: DIG = 4'b1101;  // десятки
        2'd2: DIG = 4'b1011;  // сотни
        2'd3: DIG = 4'b0111;  // тысячи    (левая)
    endcase
end

// -------------------------------------------------------
// Выбор данных для текущей цифры
// -------------------------------------------------------
reg [3:0] cur_digit;
always @(*) begin
    case (mux_sel)
        2'd0: cur_digit = d0;
        2'd1: cur_digit = d1;
        2'd2: cur_digit = d2;
        2'd3: cur_digit = d3;
    endcase
end

// -------------------------------------------------------
// Декодер цифра → сегменты
// Common Anode: 0 = сегмент горит, 1 = не горит
// Порядок битов SEG[6:0] = gfedcba
// -------------------------------------------------------
always @(*) begin
    case (cur_digit)
        4'd0: SEG = 7'b1000000;  // 0
        4'd1: SEG = 7'b1111001;  // 1
        4'd2: SEG = 7'b0100100;  // 2
        4'd3: SEG = 7'b0110000;  // 3
        4'd4: SEG = 7'b0011001;  // 4
        4'd5: SEG = 7'b0010010;  // 5
        4'd6: SEG = 7'b0000010;  // 6
        4'd7: SEG = 7'b1111000;  // 7
        4'd8: SEG = 7'b0000000;  // 8
        4'd9: SEG = 7'b0010000;  // 9
        default: SEG = 7'b1111111;
    endcase
end

endmodule