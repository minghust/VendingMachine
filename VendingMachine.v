`timescale 1ns / 1ps

//
// Created by Ming Zhang on 17-09-04
//

module VendingMachine(reset, clk, SEG, AN, item1, item2, coin1, coin2, confirm_flag, buy, 
 is_sale, power_on, op_start, cancel_flag, hold_ind, drinktk_ind, charge_ind, is_sale_xdc); // top moudle

    /******** I/O Port ******/
    input reset, clk;
    input item1, item2, coin1, coin2, buy;
    input is_sale, op_start, cancel_flag, confirm_flag;
    output [7:0]SEG;
    output [7:0]AN;
    output reg is_sale_xdc;
    output reg power_on, hold_ind, charge_ind;
    output drinktk_ind;

    /****** Variables Definition & Initialization *****/
    reg [2:0] state;
    reg [4:0] chargeMoney;
    reg [2:0] cnt;
    reg cancel;
    wire ck;
    wire over;
    wire [4:0] money;
    reg hasBuy;
    wire is_charge;

    parameter off        =      0,
               start      =      1,
               toSale     =      2,
               chooseItem =      3,
               pay        =      4,
               charge     =      5;
    initial begin
        cnt = 0;
        power_on = 0;
        hold_ind = 0;
        state = 0;
        chargeMoney = 0;
        is_sale_xdc = 0;
        hasBuy = 0;
        cancel = 0;
    end
    
    Time timing(.state(state), .clk(clk), .hasBuy(hasBuy), .drinktk_ind(drinktk_ind), .over(over));
    Divider #(200_000) divider(.clk(clk), .ck(ck));
    Show show(.ck(ck), .item1(item1), .item2(item2), .state(state), .money(money), .chargeMoney(chargeMoney), .SEG(SEG), .AN(AN));
    Pay paymoney(.state(state), .buy(buy), .coin1(coin1), .coin2(coin2), .money(money));
    /***** Finite State Machine ******/
    always @(posedge clk) begin
        case (state)
            off: begin // 0
                power_on = 0;
                hold_ind = 0;
                is_sale_xdc = 0;
                charge_ind = 0;
                 if(reset)
                     state = start;
                 else 
                     state = off;
            end
            start: begin // 1
                power_on = 1;
                hold_ind = 0;
                is_sale_xdc = 0;
                charge_ind = 0;
                hasBuy = 0;
                cancel = 0;
                if(is_sale)
                    state = toSale;
                else
                    state = start;
                if(!reset)
                    state = off;
            end
            toSale: begin // 2
                power_on = 1;
                hold_ind = 0;
                is_sale_xdc = 1;
                charge_ind = 0;
                if(op_start) // user start to choose, op_start is a switch
                    state = chooseItem;
                else 
                    state = toSale;
                if(!is_sale)
                    state = start;
                if(!reset)
                    state = off;
            end
            chooseItem: begin // 3
                power_on = 1;
                hold_ind = 1;
                is_sale_xdc = 1;
                charge_ind = 0;
                if(confirm_flag)
                    state = pay;
                else
                    state = chooseItem;
                if(!op_start)
                    state = toSale;
                if(!reset)
                    state = off;
            end
            pay: begin
                power_on <= 1;
                hold_ind <= 1;
                is_sale_xdc <= 1;
                if(cancel_flag) begin
                    cancel <= 1;
                    if(money > 0) begin
                        state <= charge;
                        hasBuy <= 0;
                        charge_ind <= 1;
                    end
                    else if(money == 0)
                        state <= start;
                end
                else begin
                    if(item1) begin
                        if (money >= 3) begin
                            hasBuy <= 1;
                            charge_ind <= 1;
                            state <= charge;
                        end
                        else if(money < 3)
                            state <= pay;
                    end
                    else if(item2)begin
                        if(money >= 5) begin
                            hasBuy <= 1;
                            if(money > 5)
                                charge_ind <= 1;
                            else if(money == 5)
                                charge_ind <= 0;
                            state <= charge;
                        end
                        else if(money < 5)
                            state <= pay;
                    end
                end
            end
            charge: begin
                power_on = 1;
                hold_ind = 1;
                is_sale_xdc = 1;
                if(cancel) begin
                    chargeMoney = 2 * money;
                end
                else begin
                    if(item1) begin
                        chargeMoney = 2 * money - 5;
                    end
                    else if(item2)
                       chargeMoney = 2 * money - 10;              
                end
                if(over)
                    state = start;
                else
                    state = charge;
            end
        endcase
    end
endmodule

module Time(state, clk, hasBuy, drinktk_ind, over); // 10s timing
    input clk, hasBuy;
    input [2:0]state;
    output reg drinktk_ind, over;
    reg [31:0]cnt;

    initial begin
        drinktk_ind <= 0;
        cnt <= 0;
        over <= 0;
    end

    always@(posedge clk) begin
        if (state == 5) begin
            if(hasBuy)
                drinktk_ind = 1;
            else
                drinktk_ind = 0;
            if(cnt == 300_000_000) begin // wait for 3 seconds for deal over
                cnt = 0;
                over = 1;
            end
            else begin
                cnt = cnt + 1;
                over = 0;
            end     
        end
        else begin
            drinktk_ind <= 0; 
            over <= 0;
        end
    end 
endmodule


module Divider(clk, ck); // 1s
   input clk;
   output reg ck;

   reg [31:0]cnt;

   parameter dely1s = 200_000;

   initial begin
       cnt <= 0;
   end
   always @(posedge clk)
       begin
           cnt = cnt + 1;
           if(cnt == dely1s)
           begin
               ck = ~ck;
               cnt = 0;
           end
       end  
endmodule

module Pay(state, buy, coin1, coin2, money);
    input buy, coin1, coin2;
    input [2:0] state;
    output reg [4:0]money;
    initial begin
        money = 0;
    end
    always @(posedge buy) begin
        if (state == 4) begin
            if(coin1)
                money = money + 1;
            else if(coin2)
                money = money + 10;
        end
        else begin
            money = 0;
        end
    end
endmodule

module Show(ck, item1, item2, state, money, chargeMoney, SEG, AN);
    input ck;
    input item1, item2;
    input [2:0]state;
    input [4:0]money;
    input [4:0]chargeMoney;
    output reg [7:0]SEG;
    output reg [7:0]AN;
    reg [2:0]cnt;

    initial begin
        cnt = 0;
    end

    parameter  off        =      0,
               start      =      1,
               toSale     =      2,
               chooseItem =      3,
               pay        =      4,
               charge     =      5;

        always@(posedge ck) begin
        case(state)
            off: begin
                case(cnt)
                    0: begin
                        cnt <= 1;
                        SEG[7:0] <= 8'b11000000;
                        AN[7:0] <= 8'b11111011;
                    end
                    1: begin
                        cnt <= 2;
                        SEG[7:0] <= 8'b10001110;
                        AN[7:0] <= 8'b11111101; 
                    end
                    2: begin
                        cnt <= 0;
                        SEG[7:0] <= 8'b10001110;
                        AN[7:0] <= 8'b11111110;
                    end
                    default: cnt = 0;
                endcase
            end
            start: begin
                case (cnt)
                    0:begin
                        cnt <= 1;
                        SEG[7:0]<=8'b11000000; // O
                        AN[7:0]<=8'b11111110;
                    end
                    1:begin
                        cnt <= 2;
                        SEG[7:0] <= 8'b11000111; // L
                        AN[7:0] <= 8'b11111101;
                    end                
                    2:begin
                        cnt <= 3;
                        SEG[7:0] <= 8'b11000111; // L
                        AN[7:0] <= 8'b11111011;
                    end
                    3:begin 
                        cnt <= 4;
                        SEG[7:0] <= 8'b10000110; // E
                        AN[7:0] <= 8'b11110111;
                    end
                    4:begin
                        cnt <= 0;
                        SEG[7:0] <= 8'b10001001; // H
                        AN[7:0] <= 8'b11101111;
                    end
                    default: cnt = 0;
                endcase
            end
            toSale: begin
                case (cnt)
                    0:begin
                        cnt <= 1;
                        SEG[7:0]<=8'b11000000; // O
                        AN[7:0]<=8'b11111110;
                    end
                    1:begin
                        cnt <= 2;
                        SEG[7:0] <= 8'b11000111; // L
                        AN[7:0] <= 8'b11111101;
                    end                
                    2:begin
                        cnt <= 3;
                        SEG[7:0] <= 8'b11000111; // L
                        AN[7:0] <= 8'b11111011;
                    end
                    3:begin 
                        cnt <= 4;
                        SEG[7:0] <= 8'b10000110; // E
                        AN[7:0] <= 8'b11110111;
                    end
                    4:begin
                        cnt <= 0;
                        SEG[7:0] <= 8'b10001001; // H
                        AN[7:0] <= 8'b11101111;
                    end
                    default: cnt = 0;
                endcase
            end
            chooseItem: begin
                if(item1) begin
                    case(cnt)
                        0:begin
                            cnt <= 1;
                            SEG[7:0] <=  8'b10010010; // 5
                            AN[7:0] <= 8'b11111110;
                        end
                        1:begin
                            cnt <= 0;
                            SEG[7:0] <= 8'b00100100; // 2.
                            AN[7:0] <= 9'b11111101;
                        end
                        default: cnt = 0;
                    endcase
                end
                else if(item2) begin
                    SEG[7:0] <=  8'b10010010; // 5
                    AN[7:0] <= 8'b11111110;
                end
                else begin
                     case(cnt)
                        0:begin
                            cnt <= 1;
                            SEG[7:0] <= 8'b10010010; // 5
                            AN[7:0] <= 8'b11111110; 
                        end
                        1:begin
                            cnt <= 2;
                            SEG[7:0] <= 8'b00100100; // 2.
                            AN[7:0] <= 8'b11110111;
                        end
                        2:begin
                            cnt <= 0;
                            SEG[7:0] <= 8'b10010010; // 5
                            AN[7:0] <= 8'b11111011;
                        end
                        default: cnt = 0;
                    endcase
                 end 
            end
            pay: begin
                if(item1)begin
                    case (money)
                         0: begin
                                case(cnt)
                                    0: begin
                                        cnt <= 1;
                                        SEG[7:0] <= 8'b11000000;
                                        AN[7:0] <= 8'b11111110;                                    
                                    end
                                    1: begin
                                        cnt <= 2;
                                        SEG[7:0] <=  8'b10010010; // 5
                                        AN[7:0] <= 8'b11101111; 
                                    end
                                    2: begin
                                        cnt <= 0;
                                        SEG[7:0] <= 8'b00100100; // 2.
                                        AN[7:0] <= 9'b11011111;
                                    end
                                    default: cnt <= 0;
                                endcase
                        end
                        1: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b11111001;
                                    AN[7:0] <= 8'b11111110;                                    
                                end
                                1: begin
                                    cnt <= 2;
                                    SEG[7:0] <=  8'b10010010; // 5
                                    AN[7:0] <= 8'b11101111; 
                                end
                                2: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b00100100; // 2.
                                    AN[7:0] <= 9'b11011111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        2: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b10100100;
                                    AN[7:0] <= 8'b11111110;                                    
                                end
                                1: begin
                                    cnt <= 2;
                                    SEG[7:0] <=  8'b10010010; // 5
                                    AN[7:0] <= 8'b11101111; 
                                end
                                2: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b00100100; // 2.
                                    AN[7:0] <= 9'b11011111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        3: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b10110000;
                                    AN[7:0] <= 8'b11111110;                                    
                                end
                                1: begin
                                    cnt <= 2;
                                    SEG[7:0] <=  8'b10010010; // 5
                                    AN[7:0] <= 8'b11101111; 
                                end
                                2: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b00100100; // 2.
                                    AN[7:0] <= 9'b11011111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        4: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b10011001;
                                    AN[7:0] <= 8'b11111110;                                    
                                end
                                1: begin
                                    cnt <= 2;
                                    SEG[7:0] <=  8'b10010010; // 5
                                    AN[7:0] <= 8'b11101111; 
                                end
                                2: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b00100100; // 2.
                                    AN[7:0] <= 9'b11011111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        5: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b10010010;
                                    AN[7:0] <= 8'b11111110;                                    
                                end
                                1: begin
                                    cnt <= 2;
                                    SEG[7:0] <=  8'b10010010; // 5
                                    AN[7:0] <= 8'b11101111; 
                                end
                                2: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b00100100; // 2.
                                    AN[7:0] <= 9'b11011111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        10: begin
                             case(cnt)
                                 0: begin
                                     cnt <= 1;
                                     SEG[7:0] = 8'b11000000;
                                     AN[7:0] = 8'b11111110;
                                 end
                                 1: begin
                                     cnt <= 2;
                                     SEG[7:0] = 8'b11111001;
                                     AN[7:0] = 8'b11111101;
                                 end
                                2: begin
                                    cnt <= 3;
                                    SEG[7:0] <=  8'b10010010; // 5
                                    AN[7:0] <= 8'b11101111; 
                                end
                                3: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b00100100; // 2.
                                    AN[7:0] <= 9'b11011111;
                                end
                                default: cnt = 0;
                             endcase
                         end
                         default: cnt = 0;
                    endcase
                end
                else if(item2) begin
                    case (money)
                        0: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b11000000;
                                    AN[7:0] <= 8'b11111110;       
                                end
                                1: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b10010010;
                                    AN[7:0] <= 8'b11101111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        1: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b11111001;
                                    AN[7:0] <= 8'b11111110;       
                                end
                                1: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b10010010;
                                    AN[7:0] <= 8'b11101111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        2: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b10100100;
                                    AN[7:0] <= 8'b11111110;       
                                end
                                1: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b10010010;
                                    AN[7:0] <= 8'b11101111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        3: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b10110000;
                                    AN[7:0] <= 8'b11111110;       
                                end
                                1: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b10010010;
                                    AN[7:0] <= 8'b11101111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        4: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b10011001;
                                    AN[7:0] <= 8'b11111110;       
                                end
                                1: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b10010010;
                                    AN[7:0] <= 8'b11101111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        5: begin
                            case(cnt)
                                0: begin
                                    cnt <= 1;
                                    SEG[7:0] <= 8'b10010010;
                                    AN[7:0] <= 8'b11111110;       
                                end
                                1: begin
                                    cnt <= 0;
                                    SEG[7:0] <= 8'b10010010;
                                    AN[7:0] <= 8'b11101111;
                                end
                                default: cnt <= 0;
                            endcase
                        end
                        10: begin
                             case(cnt)
                                 0: begin
                                    cnt <= 1;
                                    SEG[7:0] = 8'b11000000;
                                    AN[7:0] = 8'b11111110;
                                 end
                                 1: begin
                                    cnt <= 2;
                                    SEG[7:0] = 8'b11111001;
                                    AN[7:0] = 8'b11111101;
                                 end
                                 2: begin
                                    cnt <= 0;
                                    SEG[7:0] = 8'b10010010;
                                    AN[7:0] = 8'b11101111; 
                                 end
                                 default: cnt = 0;
                             endcase
                        end
                        default: cnt = 0;
                    endcase    
                end
            end
            charge: begin
                 case(chargeMoney)
                     0: begin // real take charge 0
                         SEG[7:0] <= 8'b11000000;
                         AN[7:0] <= 8'b01111111;    
                     end
                     1: begin // 0.5
                         case(cnt)
                             0:begin
                                 cnt <= 1;
                                 SEG[7:0] <=  8'b10010010; // 5
                                 AN[7:0] <= 8'b10111111;
                             end
                             1:begin
                                 cnt <= 0;
                                 SEG[7:0] <= 8'b01000000; // 0.
                                 AN[7:0] <= 9'b01111111;
                             end
                             default: cnt = 0;
                         endcase
                     end
                     2: begin // 1
                         SEG[7:0] <= 8'b11111001;
                         AN[7:0] <= 8'b01111111;
                     end
                     4: begin // 2
                         SEG[7:0] <= 8'b10100100;                  
                         AN[7:0] <= 8'b01111111;
                     end
                     6: begin // 3
                         SEG[7:0] <= 8'b10110000;
                         AN[7:0] <= 8'b01111111;
                     end
                     8: begin // 4
                         SEG[7:0] <= 8'b10011001;
                         AN[7:0] <= 8'b01111111;
                     end
                     10: begin // 5
                         SEG[7:0] <= 8'b10010010;
                         AN[7:0] <= 8'b01111111;
                     end
                     12: begin // 6
                         SEG[7:0] = 8'b10000010;
                         AN[7:0] = 8'b01111111;
                     end
                     14: begin // 7
                         SEG[7:0] = 8'b11111000;
                         AN[7:0] = 8'b01111111;
                     end
                     15: begin // 7.5
                         case(cnt)
                             0:begin
                                 cnt <= 1;
                                 SEG[7:0] <=  8'b10010010; // 5
                                 AN[7:0] <= 8'b10111111;
                             end
                             1:begin
                                 cnt <= 0;
                                 SEG[7:0] <= 8'b01111000; // 7.
                                 AN[7:0] <= 9'b01111111;
                             end
                             default: cnt = 0;
                         endcase
                     end
                     16: begin // 8
                         SEG[7:0] = 8'b10000000;
                         AN[7:0] = 8'b01111111;
                     end
                     17: begin // 8.5
                         case(cnt)
                             0:begin
                                 cnt = 1;
                                 SEG[7:0] =  8'b10010010; // 5
                                 AN[7:0] = 8'b10111111;
                             end
                             1:begin
                                 cnt = 0;
                                 SEG[7:0] = 8'b00000000; // 8.
                                 AN[7:0] = 9'b01111111;
                             end
                             default: cnt = 0;
                         endcase
                     end
                     18: begin // 9
                         SEG[7:0] = 8'b10010000;
                         AN[7:0] = 8'b01111111;
                     end
                     19: begin // 9.5
                         case(cnt)
                             0:begin
                                 cnt = 1;
                                 SEG[7:0] =  8'b10010010; // 5
                                 AN[7:0] = 8'b10111111;
                             end
                             1:begin
                                 cnt = 0;
                                 SEG[7:0] = 8'b00010000; // 9.
                                 AN[7:0] = 9'b01111111;
                             end
                             default: cnt = 0;
                         endcase
                     end
                     default: cnt = 0;
                 endcase
            end
        endcase
    end
endmodule