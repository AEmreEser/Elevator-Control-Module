`timescale 1ns / 1ps

module elevator(

input clk_50hz, rst,

// calling the elevator from the outside:
input floor_0_p,
floor_1_p,
floor_2_p,
floor_3_p,
floor_4_p,

direction_1, // pick direction at floor 1
direction_2, // ` ` at floor 2
direction_3, // ` ` at floor 3 

// inside the elevator: from low to high: wanna go to the floor-- should set the switch back to low
floor_0_d,
floor_1_d,
floor_2_d,
floor_3_d,
floor_4_d,

// inside LEDs: one for each destination: will be on until reaching the destination
output reg led_inside_0,
led_inside_1,
led_inside_2,
led_inside_3,
led_inside_4,

// outside LEDs: denote the floor the elevator is called from : will be on until reaching that floor
led_outside_0,
led_outside_1,
led_outside_2,
led_outside_3,
led_outside_4,

led_busy, // on for not busy / waiting for people / stopped, off for busy

reg [7:0] a,b,c,d,e,f,g,p


);

//***********Your code goes here**************//
reg [2:0] floor; 
reg [1:0] state; // 00 idle , 01 up, 10 down
reg validCall;
reg [2:0] idleCallerTargetFloor;
reg [2:0] interruptingCallerTargetFloor;
// counter control states:
reg initialIdleState;
reg ongoingCounter;
reg [14:0] currentCount;
reg doneCounting;
parameter toggleValue = 8'd250; 
reg [2:0] prevWaitingFloor;
reg [2:0] currentWaitingFloor;
reg [2:0] prevStopWithLedBusyOn;
reg decrementFloorAfterCounter;
reg incrementFloorAfterCounter;
reg callerDirection; // 1 up, 0 down
reg [2:0] callerFloorTemp;
reg ledBusyOn;

always @(state) begin

    // - in ssd 7
    a[7] <= 1;
    b[7] <= 1;
    c[7] <= 1;
    d[7] <= 1;
    e[7] <= 1; 
    f[7] <= 1;
    g[7] <= 0;
    
    // - in ssd 6
    a[6] <= 1;
    b[6] <= 1;
    c[6] <= 1;
    d[6] <= 1;
    e[6] <= 1; 
    f[6] <= 1;
    g[6] <= 0;
    
    if (state == 2'b01) begin // up
        a[5] <= 1;
        b[5] <= 0;
        c[5] <= 0;
        d[5] <= 0;
        e[5] <= 0; 
        f[5] <= 0;
        g[5] <= 1;
        
        a[4] <= 0;
        b[4] <= 0;
        c[4] <= 1;
        d[4] <= 1;
        e[4] <= 0; 
        f[4] <= 0;
        g[4] <= 0;
    
    end
    else if (state == 2'b10) begin // down
    
        a[5] <= 1;
        b[5] <= 0;
        c[5] <= 0;
        d[5] <= 0;
        e[5] <= 0; 
        f[5] <= 1;
        g[5] <= 0;
        
        a[4] <= 1;
        b[4] <= 1;
        c[4] <= 0;
        d[4] <= 0;
        e[4] <= 0; 
        f[4] <= 1;
        g[4] <= 0;
    
    end
    else begin // idle
        a[5] <= 1;
        b[5] <= 0;
        c[5] <= 0;
        d[5] <= 1;
        e[5] <= 1; 
        f[5] <= 1;
        g[5] <= 1;
        
        a[4] <= 1;
        b[4] <= 0;
        c[4] <= 0;
        d[4] <= 0;
        e[4] <= 0; 
        f[4] <= 1;
        g[4] <= 0;
    
    end
end

always @ (floor) begin 
// 'F' in ssd[3]
    a[3] <= 0;
    b[3] <= 1;
    c[3] <= 1;
    d[3] <= 1;
    e[3] <= 0;
    f[3] <= 0;
    g[3] <= 0;
    
// 'L' in ssd[2]
    a[2] <= 1;
    b[2] <= 1;
    c[2] <= 1;
    d[2] <= 0;
    e[2] <= 0; 
    f[2] <= 0;
    g[2] <= 1;

// '-' in ssd[1]
    a[1] <= 1;
    b[1] <= 1;
    c[1] <= 1;
    d[1] <= 1;
    e[1] <= 1; 
    f[1] <= 1;
    g[1] <= 0;

// floor number : [0, 4] in ssd[0]
    if (floor == 3'b100) begin // floor 4
        a[0] <= 1;
        b[0] <= 0;
        c[0] <= 0;
        d[0] <= 1;
        e[0] <= 1;
        f[0] <= 0;
        g[0] <= 0;
    end 
    else if (floor == 3'b011) begin // floor 3
        a[0] <= 0;
        b[0] <= 0;
        c[0] <= 0;
        d[0] <= 0;
        e[0] <= 1;
        f[0] <= 1;
        g[0] <= 0;
    end
    else if (floor == 3'b010) begin // floor 2
        a[0] <= 0;
        b[0] <= 0;
        c[0] <= 1;
        d[0] <= 0;
        e[0] <= 0;
        f[0] <= 1;
        g[0] <= 0;
    end
    else if (floor == 3'b001) begin // floor 1
        a[0] <= 1;
        b[0] <= 0;
        c[0] <= 0;
        d[0] <= 1;
        e[0] <= 1;
        f[0] <= 1;
        g[0] <= 1;
    end
    else begin // floor 0 - default -- any erroneous floor values will be reset to ground floor 
        a[0] <= 0;
        b[0] <= 0;
        c[0] <= 0;
        d[0] <= 0;
        e[0] <= 0;
        f[0] <= 0;
        g[0] <= 1;
    end
end


function automatic isValidCall( input reg [1:0] state, input reg [2:0] currentFloor, input reg [2:0] oldCallFloor, 
                                                        input reg [2:0] newCallFloor, input reg callerDirection);
    begin
    
        if (state == 2'b01) begin // up
            
            isValidCall = (oldCallFloor > newCallFloor && currentFloor < newCallFloor && callerDirection == 1);
            
        end
        else if (state == 2'b10) begin // down
             isValidCall = (oldCallFloor < newCallFloor && currentFloor > newCallFloor  && callerDirection == 0);
        end
        else begin // idle
            isValidCall = 1'b1;
        end
    
    end
endfunction

always @ ( posedge clk_50hz or posedge rst) begin
    
    
    if (rst) begin // TO DO :: ADD STATUS UPDATES HERE - IDLE, DOWN, UP ETC.
        
        {idleCallerTargetFloor, interruptingCallerTargetFloor, floor} = 9'b0;
         state = 2'b00;
        
        { led_inside_0,
        led_inside_1,
        led_inside_2,
        led_inside_3,
        led_inside_4,
        // outside LEDs: denote the floor the elevator is called from : will be on until reaching that floor
        led_outside_0,
        led_outside_1,
        led_outside_2,
        led_outside_3,
        led_outside_4,
        led_busy } <= 11'b0;
       
       p <= 8'b11111111;
        
        initialIdleState <= 1;
        ongoingCounter <= 0;
        doneCounting <= 1;
        currentCount <= 15'b0;
        
        ledBusyOn <= 0;
        
        incrementFloorAfterCounter <= 0;
        decrementFloorAfterCounter <= 0;
        
        prevWaitingFloor <= 3'b111;
        currentWaitingFloor <= 3'b000;
        
    end
    else begin
       
    
    // ACCEPT / REFUSE COMING REQUESTS
    if (floor_1_p == 1 || floor_1_d == 1) begin // floor 1
    
        callerDirection = direction_1;    
        callerFloorTemp = 3'b001;
        validCall = isValidCall (state, floor, idleCallerTargetFloor, callerFloorTemp, callerDirection);
        
        
    end
    else if (floor_2_p == 1 || floor_2_d == 1) begin
    
        callerDirection = direction_2;   
        callerFloorTemp = 3'b010;
        validCall = isValidCall (state, floor, idleCallerTargetFloor, callerFloorTemp, callerDirection);
        
                
            
    end
    else if (floor_3_p == 1 || floor_3_d == 1) begin
    
        callerDirection = direction_3;   
        callerFloorTemp = 3'b011;
        validCall = isValidCall (state, floor, idleCallerTargetFloor, callerFloorTemp, callerDirection);
        
                
    end 
    else if (floor_4_p == 1 || floor_4_d == 1) begin
    
        callerDirection = 0;
        callerFloorTemp = 3'b100;
        validCall = isValidCall (state, floor, idleCallerTargetFloor, callerFloorTemp, callerDirection);
        
                                
        
    end 
    else if (floor_0_p || floor_0_d) begin // floor 0
    
        callerDirection = 1; 
        callerFloorTemp = 3'b000;
        validCall = isValidCall (state, floor, idleCallerTargetFloor, callerFloorTemp, callerDirection);
        
        
    end
    else begin
        
        state = state;
        callerFloorTemp = callerFloorTemp;
        
    end
    // END OF ACCEPTING / REFUSING REQUESTS
    
    
    // ADJUST STATE BASED ON LAST CALL (IF VALID) -- up down idle
     if (validCall && callerFloorTemp != prevWaitingFloor) begin
       
       initialIdleState = 0;
       
       if (floor != callerFloorTemp) begin
           case (callerFloorTemp)
                3'b000 : begin led_outside_0 = 1; led_inside_0 = 1; end
                3'b001 : begin led_outside_1 = 1; led_inside_1 = 1; end
                3'b010 : begin led_outside_2 = 1; led_inside_2 = 1; end
                3'b011 : begin led_outside_3 = 1; led_inside_3 = 1; end
                3'b100 : begin led_outside_4 = 1; led_inside_4 = 1; end
           endcase
       end
       
       if (state == 2'b00 && led_busy != 1) begin // if idle
           idleCallerTargetFloor = callerFloorTemp;
           
           if (idleCallerTargetFloor > floor) begin
               state = 2'b01; // up
           end
           else if (idleCallerTargetFloor < floor) begin
               state = 2'b10;
           end
           else begin
               state = 2'b00;
           end 
           
       end 
       else if (state == 2'b01 && led_busy != 1) begin // up and moving, not stopped
            interruptingCallerTargetFloor = callerFloorTemp;
       end
       else if (state == 2'b10 && led_busy != 1) begin
            interruptingCallerTargetFloor = callerFloorTemp;
       end
       else begin
            // do nothing
       end
       
   end
   else begin
    // do nothing
   end // if (validcall) 
    
    
    
    // MOVE ELEVATOR:
    if (floor == idleCallerTargetFloor) begin // DROP OFF LAST PASSENGER, BECOME IDLE
        
        interruptingCallerTargetFloor <= floor;
        
        case (floor)
            3'b000 : begin led_outside_0 <= 0; led_inside_0 <= 0; end
            3'b001 : begin led_outside_1 <= 0; led_inside_1 <= 0; end
            3'b010 : begin led_outside_2 <= 0; led_inside_2 <= 0; end
            3'b011 : begin led_outside_3 <= 0; led_inside_3 <= 0; end
            3'b100 : begin led_outside_4 <= 0; led_inside_4 <= 0; end
        endcase
  
        if (~initialIdleState  && prevStopWithLedBusyOn != floor) begin
            ongoingCounter <= 1;
        end
        else if (doneCounting) begin
            state <= 2'b00;
        end
        else begin
            ongoingCounter <= ongoingCounter;
        end

    end
    else if (floor == interruptingCallerTargetFloor) begin // DROP OF DISCURSIVE PASSENGER
        
       callerFloorTemp <= idleCallerTargetFloor;
        
        case (floor)
           3'b000 : begin led_outside_0 <= 0; led_inside_0 <= 0; end
           3'b001 : begin led_outside_1 <= 0; led_inside_1 <= 0; end
           3'b010 : begin led_outside_2 <= 0; led_inside_2 <= 0; end
           3'b011 : begin led_outside_3 <= 0; led_inside_3 <= 0; end
           3'b100 : begin led_outside_4 <= 0; led_inside_4 <= 0; end
        endcase
        
       
        
        if (~initialIdleState && prevStopWithLedBusyOn != floor && state) begin
            ongoingCounter <= 1;
        end
        else if (doneCounting) begin
            
            if (state == 2'b01) begin
                incrementFloorAfterCounter <= 1;
                ongoingCounter <= 1;
            end
            else if (state == 2'b10) begin
                decrementFloorAfterCounter <= 1;
                ongoingCounter <= 1;
            end
            else begin
                floor <= floor;
            end
           
        end
        else begin
            ongoingCounter <= ongoingCounter;
        end
        
        
    end
    else begin
        
        if (prevWaitingFloor != floor) begin
            ongoingCounter <= 1;
            prevWaitingFloor <= floor;
        end
        else begin
            if (state == 2'b01 && ongoingCounter != 1 && led_busy != 1 && (floor != idleCallerTargetFloor || floor != interruptingCallerTargetFloor)) begin // up
                floor <= floor + 1;
            end
            else if (state == 2'b10 && ongoingCounter != 1 && led_busy != 1 && (floor != idleCallerTargetFloor || floor != interruptingCallerTargetFloor)) begin // down
                floor <= floor - 1;
            end
            else begin // idle
                ongoingCounter <= ongoingCounter;
            end
        end
        
    end

    
    // COUNTER COUNTING PART: 
    if (ongoingCounter) begin
    
        if (currentCount >= toggleValue) begin
            doneCounting <= 1;  
            currentCount <= 0;
            ongoingCounter <= 0;
            
            prevWaitingFloor <= floor;
            
            if (decrementFloorAfterCounter) begin
                decrementFloorAfterCounter <= 0;
                floor <= floor - 1;
            end
            else if (incrementFloorAfterCounter) begin
                incrementFloorAfterCounter <= 0;
                floor <= floor + 1;
            end
            else begin
                
            end
    
        end
        else begin
            doneCounting <= 0;
            currentCount <= currentCount + 1;
            ongoingCounter <= 1;
            
        end
    end
    else begin
        ;
    end
    
    // led busy logic
     if ( (floor == idleCallerTargetFloor) && ongoingCounter && ~doneCounting) begin
           led_busy <= 1;
           prevStopWithLedBusyOn <= floor;
           prevWaitingFloor <= floor;
       end
       else if ( (floor == interruptingCallerTargetFloor ) && ongoingCounter && ~doneCounting) begin
            led_busy <= 1;
            prevStopWithLedBusyOn <= floor;
            prevWaitingFloor <= floor;
       end
       else if (doneCounting || (floor != interruptingCallerTargetFloor && floor != idleCallerTargetFloor) ) begin
           led_busy <= 0;
       end
       else begin
           led_busy <= led_busy;
       end
    
    
end // always block


//***********Your code goes here**************//
end

endmodule
