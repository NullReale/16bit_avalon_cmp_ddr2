module cmp1(
    input   wire        a,
    input   wire        b,
    input   wire        fi_big,
    input   wire        fi_equal,
    input   wire        fi_small,
 
    output      reg         fo_big,
    output      reg         fo_equal,
    output      reg         fo_small
);
 
     
    always@(*) begin
        if(fi_big == 1'b1)begin
                fo_big  = 1'b1;
                fo_equal    = 1'b0;
                fo_small = 1'b0;
            end
        else if(fi_equal == 1'b1)begin
                fo_big  = a&~b | fi_big;
                fo_equal = (~a&~b) | (a&b);
                fo_small = ~a&b;   
            end
        else if(fi_small == 1'b1)begin
                fo_big  = 1'b0;
                fo_equal    = 1'b0;
                fo_small = 1'b1;
            end
        else
            begin
                fo_big  = 1'b0;
                fo_equal    = 1'b1;
                fo_small = 1'b0;
            end
    end
 
endmodule