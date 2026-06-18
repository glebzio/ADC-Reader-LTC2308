module adc_ltc2308 
(
input wire clk,
input wire reset_n,
input  wire start,
output reg adc_convst,
output reg adc_sck,
output reg adc_sdi,
input wire adc_sdo,
output reg [11:0] result,
output reg valid
);

localparam CLK_DIV = 2;
localparam CH0_CFG = 8'b10110000;
parameter IDLE = 0;
parameter CONVST = 1;
parameter WAIT = 2;
parameter TRANSFER = 3;

reg [2:0] state = IDLE;
reg [4:0] bit_cnt = 0;
reg [1:0] clk_cnt= 0;
reg [11:0] shift_in  = 0;
reg [7:0] shift_out = 0;
reg [7:0] wait_cnt = 0;

always @(posedge clk or negedge reset_n) begin
if (!reset_n) begin
state <= IDLE;
adc_convst <= 0;
adc_sck <= 0;
adc_sdi <= 0;
valid <= 0;
bit_cnt <= 0;
clk_cnt <= 0;
wait_cnt <= 0;
shift_in <= 0;
shift_out <= 0;
result <= 0;
end
else begin
valid <= 0;

case (state)

            IDLE: begin
                adc_sck <= 0;
                adc_sdi <= 0;
                adc_convst <= 0;
                if (start)
                    state <= CONVST;
            end

            CONVST: begin
                adc_convst <= 1;
                if (wait_cnt == 1) begin
                    wait_cnt <= 0;
                    state <= WAIT;
                end else
                    wait_cnt <= wait_cnt + 1;
            end

            WAIT: begin
                adc_convst <= 0;
                if (wait_cnt == 75) begin
                    wait_cnt <= 0;
                    bit_cnt <= 0;
                    clk_cnt <= 0;
                    shift_out <= CH0_CFG;
                    shift_in <= 0;
                    state <= TRANSFER;
                end else
                    wait_cnt <= wait_cnt + 1;
            end

            TRANSFER: begin
                clk_cnt <= clk_cnt + 1;
                if (clk_cnt == CLK_DIV - 1) begin
                    adc_sck <= 1;
                    if (bit_cnt < 8)
                        adc_sdi <= shift_out[7 - bit_cnt];
                    else
                        adc_sdi <= 0;
                end

                else if (clk_cnt == 2*CLK_DIV - 1) begin
                    adc_sck <= 0;
                    clk_cnt <= 0;

                    if (bit_cnt >= 1 && bit_cnt <= 12)
                        shift_in <= {shift_in[10:0], adc_sdo};

                    if (bit_cnt == 15) begin
                        result <= shift_in;
                        valid <= 1;
                        state <= IDLE;
                    end else
                        bit_cnt <= bit_cnt + 1;
                end
            end

        endcase
    end
end

endmodule
