`timescale 1ns/1ps

module adc_tb;

reg        clk     = 0;
reg        reset_n = 0;
reg        start   = 0;
reg        adc_sdo = 0;

wire       adc_convst;
wire       adc_sck;
wire       adc_sdi;
wire [11:0] result;
wire        valid;

adc_ltc2308 u_adc (
    .clk        (clk),
    .reset_n    (reset_n),
    .start      (start),
    .adc_convst (adc_convst),
    .adc_sck    (adc_sck),
    .adc_sdi    (adc_sdi),
    .adc_sdo    (adc_sdo),
    .result     (result),
    .valid      (valid)
);

always #10 clk = ~clk;

// -------------------------------------------------------
// Задача: выдать ответ ADC синхронно с SCK
// Выставляем SDO на posedge SCK (контроллер читает на negedge)
// -------------------------------------------------------
task respond_adc;
    input [11:0] val;
    integer i;
    begin
        // NULL бит (такт 0)
        @(posedge adc_sck); #1; adc_sdo <= 0;

        // D11..D0 (такты 1..12)
        for (i = 11; i >= 0; i = i - 1) begin
            @(posedge adc_sck); #1; adc_sdo <= val[i];
        end

        // Такты 13..15 — не важно
        repeat(3) begin
            @(posedge adc_sck); #1; adc_sdo <= 0;
        end
    end
endtask

// -------------------------------------------------------
// Задача: один полный тест
// -------------------------------------------------------
integer pass_cnt = 0;
integer fail_cnt = 0;

task run_test;
    input [11:0] send_val;
    input [11:0] expect_val;
    reg   [11:0] got;
    begin
        // Запускаем respond_adc и start одновременно
        fork
            // Поток 1: даём старт контроллеру
            begin
                @(posedge clk); #1;
                start <= 1;
                @(posedge clk); #1;
                start <= 0;
            end
            // Поток 2: отвечаем за ADC
            respond_adc(send_val);
        join

        // Ждём valid
        wait(valid == 1);
        @(posedge clk);
        got = result;

        if (got == expect_val) begin
            $display("  0x%03X → 0x%03X (%0d мВ)  ПРОЙДЕН ✓",
                     send_val, got, got);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  0x%03X → 0x%03X (ожидали 0x%03X)  ПРОВАЛЕН ✗",
                     send_val, got, expect_val);
            fail_cnt = fail_cnt + 1;
        end

        // Пауза перед следующим тестом
        repeat(10) @(posedge clk);
    end
endtask

// -------------------------------------------------------
// Главный тест
// -------------------------------------------------------
initial begin
    $display("=====================================");
    $display("   СИМУЛЯЦИЯ ADC LTC2308");
    $display("=====================================");

    reset_n = 0;
    repeat(10) @(posedge clk);
    reset_n = 1;
    repeat(10) @(posedge clk);

    $display("Тест 1: 0x000 =    0 мВ");
    run_test(12'h000, 12'h000);

    $display("Тест 2: 0xFFF = 4095 мВ");
    run_test(12'hFFF, 12'hFFF);

    $display("Тест 3: 0x800 = 2048 мВ");
    run_test(12'h800, 12'h800);

    $display("Тест 4: 0xCE4 = 3300 мВ");
    run_test(12'hCE4, 12'hCE4);

    $display("");
    $display("Итого: ПРОЙДЕНО=%0d  ПРОВАЛЕНО=%0d",
             pass_cnt, fail_cnt);
    $display("=====================================");
    #500;
    $stop;
end

endmodule