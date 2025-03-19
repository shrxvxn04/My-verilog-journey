module roller(
    input clk,
    input rst,
    output reg [6:0] h0,
    output reg [6:0] h1,
    output reg [6:0] h2,
    output reg [6:0] h3,
    output reg [6:0] h4,
    output reg [6:0] h5
);
    integer count;
    reg clk_1hz;
    reg [6:0] a [0:5];
    integer cnt;
   
    initial begin
        a[0] = 7'b0000000;
        a[1] = 7'b0001000;
        a[2] = 7'b1000111;
        a[3] = 7'b0001000;
        a[4] = 7'b1110000;
        a[5] = 7'b1111001;
    end
   
    always @(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            count <= 0;
            clk_1hz <= 1'b0;
        end
        else
        begin
            count <= count + 1;
            if(count <= 25000000)
                clk_1hz <= 1'b0;
            else if (count > 25000000 && count < 50000000)
                clk_1hz <= 1'b1;
            else
                count <= 0;
        end
    end

    always @(posedge clk_1hz or posedge rst)
    begin
        if(rst)
            cnt <= 0;
        else if(cnt == 6)
            cnt <= 0;
        else
        begin
            cnt <= cnt + 1;
        end
    end
   
    always @(posedge clk_1hz or posedge rst)
    begin
        if(rst) begin
            h5 <= a[0];
            h4 <= a[1];
            h3 <= a[2];
            h2 <= a[3];
            h1 <= a[4];
            h0 <= a[5];
        end
        else begin
            h5 <= a[(cnt + 0) % 6];
            h4 <= a[(cnt + 1) % 6];
            h3 <= a[(cnt + 2) % 6];
            h2 <= a[(cnt + 3) % 6];
            h1 <= a[(cnt + 4) % 6];
            h0 <= a[(cnt + 5) % 6];
        end
    end
endmodule