module randt (
    input clk,
    input rst,
    input i_Rx_Serial,
    output o_Rx_DV,
    output [7:0] o_Rx_Byte,
    output active,
    output reg tx
);

    parameter IDLE = 3'b000;
    parameter START = 3'b001;
    parameter DATA_STATE = 3'b010;
    parameter STOP = 3'b011;
    parameter CLEAN = 3'b100;

    parameter clks_bit = 434;

    reg [2:0] current_state = IDLE;
    reg [8:0] clk_count = 0;
    reg [2:0] index_bit = 0;
    reg [7:0] data = 0;
    reg active_reg = 0;

    // Receive FSM States
    parameter S_IDLE = 3'b000;
    parameter S_RX_START_BIT = 3'b001;
    parameter S_RX_DATA_BITS = 3'b010;
    parameter S_RX_STOP_BIT = 3'b011;
    parameter S_CLEANUP = 3'b100;

    reg r_Rx_Data_R = 1'b1;
    reg r_Rx_Data = 1'b1;

    reg [12:0] r_Clock_Count = 0;
    reg [2:0] r_Bit_Index = 0;
    reg [7:0] r_Rx_Byte = 0;
    reg r_Rx_DV = 0;
    reg [2:0] r_SM_Main = S_IDLE;

    reg start_received = 0;
    reg stop_received = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_Rx_Data_R <= 1'b1;
            r_Rx_Data <= 1'b1;
        end else begin
            r_Rx_Data_R <= i_Rx_Serial;
            r_Rx_Data <= r_Rx_Data_R;
        end
    end

    // Receive FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_SM_Main <= S_IDLE;
            r_Rx_DV <= 1'b0;
            r_Clock_Count <= 0;
            r_Bit_Index <= 0;
            r_Rx_Byte <= 8'b0;
            start_received <= 0;
            stop_received <= 0;
        end else begin
            case (r_SM_Main)
                S_IDLE: begin
                    r_Rx_DV <= 1'b0;
                    r_Clock_Count <= 0;
                    r_Bit_Index <= 0;
                    if (r_Rx_Data == 1'b0) 
                        r_SM_Main <= S_RX_START_BIT;
                end

                S_RX_START_BIT: begin
                    if (r_Clock_Count == (clks_bit - 1) / 2) begin
                        if (r_Rx_Data == 1'b0) begin
                            r_Clock_Count <= 0;
                            r_SM_Main <= S_RX_DATA_BITS;
                        end else begin
                            r_SM_Main <= S_IDLE;
                        end
                    end else begin
                        r_Clock_Count <= r_Clock_Count + 1;
                    end
                end

                S_RX_DATA_BITS: begin
                    if (r_Clock_Count < clks_bit - 1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                    end else begin
                        r_Clock_Count <= 0;
                        r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
                        if (r_Bit_Index < 7) begin
                            r_Bit_Index <= r_Bit_Index + 1;
                        end else begin
                            r_SM_Main <= S_RX_STOP_BIT;
                        end
                    end
                end

                S_RX_STOP_BIT: begin
                    if (r_Clock_Count < clks_bit - 1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                    end else begin
                        r_Rx_DV <= 1'b1;
                        r_Clock_Count <= 0;
                        r_SM_Main <= S_CLEANUP;
                    end
                end

                S_CLEANUP: begin
                    r_SM_Main <= S_IDLE;
                    r_Rx_DV <= 1'b0;
                end
            endcase
        end
    end

    assign o_Rx_DV = r_Rx_DV;
    assign o_Rx_Byte = r_Rx_Byte;

    // Transmit FSM
  always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= IDLE;
        tx <= 1'b1;
        active_reg <= 0;
        clk_count <= 0;
        index_bit <= 0;
    end else begin
        case (current_state)
            IDLE: begin
                if (o_Rx_DV) begin
                    data <= o_Rx_Byte;
                    active_reg <= 1'b1;
                    index_bit <= 0;  // Reset bit index
                    current_state <= START;
                end
            end

            START: begin
                tx <= 1'b0;
                if (clk_count < clks_bit - 1) clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    current_state <= DATA_STATE;
                end
            end

            DATA_STATE: begin
                tx <= data[index_bit];
                if (clk_count < clks_bit - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    if (index_bit < 7) begin
                        index_bit <= index_bit + 1;
                    end else begin
                        current_state <= STOP;
                    end
                end
            end

            STOP: begin
                tx <= 1'b1;
                if (clk_count < clks_bit - 1) clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    current_state <= IDLE;  // 🔹 Restart for next byte
                end
            end
        endcase
    end
end


    assign active = active_reg;

endmodule
