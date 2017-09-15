`timescale 1ns / 1ps
module VendingMachine_tb();
    reg reset, clk, item1, item2, coin1, coin2, buy;
    reg is_sale, op_start, cancel_flag, confirm_flag;
    wire [7:0]SEG;
    wire [7:0]AN;
    wire is_sale_xdc, power_on, hold_ind, charge_ind, drinktk_ind;

    initial begin
        reset <= 0;
        clk <= 0;
        item1 <= 0;
        item2 <= 0;
        coin1 <= 0;
        coin2 <= 0;
        buy <= 0 ;
        is_sale <= 0;
        op_start <= 0;
        cancel_flag <= 0;
        confirm_flag <= 0;

        #2 reset = 1;
        #2 is_sale = 1;
        #2 op_start = 1;
        #2 item2 = 1;
        #2 confirm_flag = 1;#0.5 confirm_flag = 0;
        #2 coin1 = 1;
        #2 buy = 1; #0.5 buy = 0;
        #2 buy = 1;#0.5 buy = 0;
        #2 buy = 1;#0.5 buy = 0;
        #2 cancel_flag = 1;#0.5 cancel_flag = 0;
    end

    always
        #0.1 clk = ~clk;


    VendingMachine sim(.reset(reset), .clk(clk), .SEG(SEG), .AN(AN), .item1(item1), .item2(item2), .coin1(coin1), .coin2(coin2), .confirm_flag(confirm_flag), .buy(buy), 
    .is_sale(is_sale), .power_on(power_on), .op_start(op_start), .cancel_flag(cancel_flag), .hold_ind(hold_ind), .drinktk_ind(drinktk_ind), .charge_ind(charge_ind), .is_sale_xdc(is_sale_xdc));
endmodule

module Pay_tb();
    reg [2:0]state;
    reg coin1, coin2, buy;
    wire [4:0]money;
    initial begin
        state <= 4;
        coin1 <= 0;
        coin2 <= 0;
        buy <= 0;
        #1 coin1 = 1;
        #7 coin1 = 0;
        #1 state = 0;
        #1 state = 4;
        #1 coin2 = 1;
    end
    always
        #1 buy = ~buy;
    
    Pay sim(.state(state), .buy(buy), .coin1(coin1), .coin2(coin2), .money(money));
endmodule

module Time_tb();
    reg clk, hasBuy;
    reg [2:0]state;
    wire drinktk_ind, over;
    
    initial begin
        state <= 5;
        clk <= 0;
        hasBuy <= 0;
        #6 state = 0;
        #1 state = 5;
        #1 hasBuy = 1;
        #1 state = 0;
        #1 hasBuy = 0;
        #1 state = 5;
    end
    
    always
        #0.5 clk = ~clk;
    
    Time sim(.state(state), .clk(clk), .hasBuy(hasBuy), .drinktk_ind(drinktk_ind), .over(over));
endmodule

module Show_tb();
    reg ck;
    reg item1, item2;
    reg [2:0]state;
    reg [4:0]money;
    reg [4:0]chargeMoney;
    wire [7:0]SEG;
    wire [7:0]AN;
    
    initial begin
        ck <= 0;
        state <= 0;
        item1 <= 0;
        item2 <= 0;
        money <= 0;
        chargeMoney <= 0;
        
        #3 state = 1;
        #3 state = 2;
        #3 state = 3;
        #0.5 item1 = 1;
        #3 state = 4;
        #0.5 money = 3;
        #3 chargeMoney = 1;
        #3 state = 1;
    end
    
    always
        #0.2 ck = ~ck;
        
    Show sim(.ck(ck), .item1(item1), .item2(item2), .state(state), .money(money), .chargeMoney(chargeMoney), .SEG(SEG), .AN(AN));
    
endmodule