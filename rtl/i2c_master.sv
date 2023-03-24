`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  www.circuitden.com
// Engineer: Artin Isagholian
//           artinisagholian@gmail.com
// 
// Create Date: 01/20/2021 05:47:22 PM
// Design Name: 
// Module Name: i2c_master
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c_master#(
    parameter DATA_WIDTH      = 8,
    parameter REGISTER_WIDTH  = 8,
    parameter ADDR_WIDTH      = 7
)(
    input                               clock,
    input                               reset,
    input                               enable,
    input                               read_write,
    input       [DATA_WIDTH-1:0]        i_mosi_data,
    input       [REGISTER_WIDTH-1:0]    i_reg_addr,
    input       [ADDR_WIDTH-1:0]        i_device_addr,
    input  wire [15:0]                  divider,
    output reg  [DATA_WIDTH-1:0]        miso_data,
    output reg                          o_busy = 0,
    inout                               io_sda,
    inout                               io_scl
);

 /*INSTANTATION TEMPLATE
i2c_master #(.DATA_WIDTH(8),.REG_WIDTH(8),.ADDR_WIDTH(7))
        i2c_master_inst(
            .clock(),
            .reset(),
            .enable(),
            .i_rw(),
            .i_mosi_data(),
            .i_reg_addr(),
            .i_device_addr(),
            .i_divider(),
            .o_miso_data(),
            .o_busy(),
            .io_sda(),
            .io_scl()
        );
*/

    localparam S_IDLE                =       8'h00;
    localparam S_START               =       8'h01;
    localparam S_WRITE_ADDR_W        =       8'h02;
    localparam S_CHECK_ACK           =       8'h03;
    localparam S_WRITE_REG_ADDR      =       8'h04;
    localparam S_RESTART             =       8'h05;
    localparam S_WRITE_ADDR_R        =       8'h06;
    localparam S_READ_REG            =       8'h07;
    localparam S_SEND_NACK           =       8'h08;
    localparam S_SEND_STOP           =       8'h09;
    localparam S_WRITE_REG_DATA      =       8'h0A;
    localparam S_WRITE_REG_ADDR_MSB  =       8'h0B;
    localparam S_WRITE_REG_DATA_MSB  =       8'h0C;
    localparam S_READ_REG_MSB        =       8'h0D;
    localparam S_SEND_ACK            =       8'h0E;

    reg                       serial_clock;
    reg                       _serial_clock;
    reg [7:0]                 state;
    reg                       _state;
    reg [7:0]                 post_state;
    reg [7:0]                 _post_state;
    reg [ADDR_WIDTH:0]        saved_device_address;
    reg [ADDR_WIDTH:0]        _saved_device_address;
    reg [REGISTER_WIDTH-1:0]  saved_register_address;
    reg [REGISTER_WIDTH-1:0]  _saved_register_address;
    reg [DATA_WIDTH-1:0]      saved_mosi_data;
    reg [DATA_WIDTH-1:0]      _saved_mosi_data;
    reg [1:0]                 process_counter;
    reg [1:0]                 _process_counter;
    reg [7:0]                 bit_counter;
    reg [7:0]                 _bit_counter;
    reg                       serial_data;
    reg                       _serial_data;
    reg                       post_serial_data;
    reg                       _post_serial_data;
    reg                       last_acknowledge;
    reg                       _last_acknowledge;
    reg                       enable_delay;
    reg                       _enable_delay;
    reg                       _saved_read_write;
    reg                       saved_read_write;
    reg                       serial_data_enable;
    reg [15:0]                divider_counter;
    reg [15:0]                _divider_counter;
    reg                       divider_tick;
    reg [DATA_WIDTH-1:0]      _miso_data;

    wire sda_oe;
    assign sda_oe = (state!=S_IDLE && state!=S_CHECK_ACK && state!=S_READ_REG && state!=S_READ_REG_MSB);
    wire scl_oe;
    //when proc_counter = 1, we check for clock stretching from slave
    assign scl_oe = (state!=S_IDLE && proc_counter!=1 && proc_counter!=2);




//i2c divider tick geneartor

always_comb begin
    _divider_counter     = divider_counter;
    divider_tick         = 0;
    if (divider_counter == divider) begin
        _divider_counter = 0;
        divider_tick     = 1;
    end
    else begin
        _divider_counter = divider_counter + 1;
    end
end

always_ff@(posedge clock)begin
    if(reset)begin
        divider_counter <= 0;
    end
    else begin
        divider_counter <= _divider_counter;
    end
end


always_comb begin
    _state               = state;
    _post_state          = post_state;
    _process_counter     = process_counter;
    _bit_counter         = bit_counter;
    _last_acknowledge    = last_acknowledge;
    _miso_data           = miso_data;
    _saved_read_write    = saved_read_write;


    if (divider_tick) begin

        case (state)

            S_IDLE: begin
                _process_counter   = 0;
                _bit_counter       = 0;
                _last_acknowledge  = 0;
                _saved_read_write  = rw;


            end

        endcase

    end

end

always_ff @(posedge clock) begin
    if (reset) begin
        state            <= S_IDLE;
        post_state       <= S_IDLE;
        process_counter  <= 0;
        last_acknowledge <= 0;
        miso_data        <= 0;
        saved_read_write <= 0;
    end
    else begin
        state            <= _state;
        post_state       <= _post_state;
        process_counter  <= _process_counter;
        last_acknowledge <= _last_acknowledge;
        miso_data        <= _miso_data;
        saved_read_write <= _saved_read_write;
    end
 end


    always@(posedge clock)begin
        if(reset)begin
            sda_out <= 1;
            scl_out <= 1;
            proc_counter <= 0;
            bit_counter <= 0;
            ack_recieved <= 0;
            o_miso_data <= 0;
            saved_device_addr <= 0;
            saved_reg_addr <= 0;
            saved_mosi_data <= 0;
            enable <= 0;
            o_busy <= 0;
            rw <= 0;
            post_state <= S_IDLE;
            state <= S_IDLE;
        end
        else begin
            if(divider_tick)begin
                case(state)
                    S_IDLE: begin
                        proc_counter <= 0;
                        sda_out <= 1;
                        scl_out <= 1;
                        enable_delay      <= enable;
                        saved_device_addr <= {i_device_addr, 1'b0};
                        saved_reg_addr <= i_reg_addr;
                        saved_mosi_data <= i_mosi_data;
                        o_busy <= 0;
                        ack_recieved <= 0;
                        rw <= i_rw;
                        if(enable_delay)begin
                            state <= S_START;
                            post_state <= S_WRITE_ADDR_W;
                        end
                    end
                    
                    S_START: begin
                        case(proc_counter)
                            0: begin
                                proc_counter <= 1;
                                o_busy <= 1;
                                enable <= 0;
                            end
                            1: begin
                                sda_out <= 0;
                                proc_counter <= 2;
                            end
                            2: begin
                                proc_counter <= 3;
                                bit_counter <= 8;
                            end
                            3: begin
                                scl_out <= 0;
                                proc_counter <= 0;
                                state <= post_state;
                                sda_out <= saved_device_addr[ADDR_WIDTH];
                            end
                        endcase
                    end
                    
                    S_WRITE_ADDR_W: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                scl_out <= 0;
                                bit_counter <= bit_counter -1;
                                proc_counter <= 3;
                            end
                            3: begin
                                if(bit_counter == 0)begin
                                    post_sda_out <= saved_reg_addr[REG_WIDTH-1];
                                    if(REG_WIDTH == 16)begin
                                        post_state <= S_WRITE_REG_ADDR_MSB;
                                    end
                                    else begin
                                        post_state <= S_WRITE_REG_ADDR;
                                    end
                                    state <= S_CHECK_ACK;
                                    bit_counter <= 8;
                                end
                                else begin
                                  sda_out <= saved_device_addr[bit_counter-1];
                                end
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_CHECK_ACK: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    ack_recieved <= 0;
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                scl_out <= 0;
                                if(io_sda == 0)begin
                                    ack_recieved <= 1;
                                end
                                proc_counter <= 3;
                            end
                            3: begin
                                if(ack_recieved)begin
                                    state <= post_state;
                                    ack_recieved <= 0;
                                    sda_out <= post_sda_out;
                                end
                                else begin
                                    state <= S_IDLE;
                                end
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_WRITE_REG_ADDR_MSB: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    ack_recieved <= 0;
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                scl_out <= 0;
                                bit_counter <= bit_counter -1;
                                proc_counter <= 3;
                            end
                            3: begin
                                if(bit_counter == 0)begin
                                    post_state <= S_WRITE_REG_ADDR;
                                    post_sda_out <= saved_reg_addr[7];
                                    bit_counter <= 8; 
                                    sda_out <= 0;
                                    state <= S_CHECK_ACK;
                                end
                                else begin
                                  sda_out <= saved_reg_addr[bit_counter+7];
                                end
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_WRITE_REG_ADDR: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    ack_recieved <= 0;
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                scl_out <= 0;
                                bit_counter <= bit_counter -1;
                                proc_counter <= 3;
                            end
                            3: begin
                                if(bit_counter == 0)begin
                                    if(rw == 0)begin
                                        if(DATA_WIDTH == 16)begin
                                            post_state <= S_WRITE_REG_DATA_MSB;
                                            post_sda_out <= saved_mosi_data[15];
                                        end
                                        else begin
                                            post_state <= S_WRITE_REG_DATA;
                                            post_sda_out <= saved_mosi_data[7];
                                        end
                                    end
                                    else begin
                                        post_state <= S_RESTART;
                                        post_sda_out <= 1;
                                    end
                                    bit_counter <= 8; 
                                    sda_out <= 0;
                                    state <= S_CHECK_ACK;
                                end
                                else begin
                                    sda_out <= saved_reg_addr[bit_counter-1];
                                end
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_WRITE_REG_DATA_MSB: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    ack_recieved <= 0;
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                scl_out <= 0;
                                bit_counter <= bit_counter -1;
                                proc_counter <= 3;
                            end
                            3: begin
                                if(bit_counter == 0)begin
                                    state <= S_CHECK_ACK;
                                    post_state <= S_WRITE_REG_DATA;
                                    post_sda_out <= saved_mosi_data[7];
                                    bit_counter <= 8; 
                                    sda_out <= 0;
                                end
                                else begin
                                    sda_out <= saved_mosi_data[bit_counter+7];
                                end
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_WRITE_REG_DATA: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    ack_recieved <= 0;
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                scl_out <= 0;
                                bit_counter <= bit_counter -1;
                                proc_counter <= 3;
                            end
                            3: begin
                                if(bit_counter == 0)begin
                                    state <= S_CHECK_ACK;
                                    post_state <= S_SEND_STOP;
                                    post_sda_out <= 0;
                                    bit_counter <= 8; 
                                    sda_out <= 0;
                                end
                                else begin
                                    sda_out <= saved_mosi_data[bit_counter-1];
                                end
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_RESTART: begin
                        case(proc_counter)
                            0:begin
                                proc_counter <= 1;
                            end
                            1: begin
                                proc_counter <= 2;
                                scl_out <= 1;
                            end
                            2: begin
                                proc_counter <= 3;
                            end
                            3: begin
                                state <= S_START;
                                post_state <= S_WRITE_ADDR_R;
                                saved_device_addr[0] <= 1'b1;
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_WRITE_ADDR_R: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    ack_recieved <= 0;
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                scl_out <= 0;
                                bit_counter <= bit_counter -1;
                                proc_counter <= 3;
                            end
                            3: begin
                                if(bit_counter == 0)begin
                                    if(DATA_WIDTH == 16)begin
                                        post_state <= S_READ_REG_MSB;
                                        post_sda_out <= 0;
                                    end
                                    else begin
                                        post_state <= S_READ_REG;
                                        post_sda_out <= 0;
                                    end
                                    state <= S_CHECK_ACK;
                                    bit_counter <= 8;
                                end
                                else begin
                                  sda_out <= saved_device_addr[bit_counter-1];
                                end
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_READ_REG_MSB: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    ack_recieved <= 0;
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                scl_out <= 0; 
                                //sample data on this rising edge of scl
                                o_miso_data[bit_counter+7] <= io_sda;
                                bit_counter <= bit_counter -1;
                                proc_counter <= 3;
                            end
                            3: begin
                                if(bit_counter == 0)begin
                                    post_state <= S_READ_REG;
                                    state <= S_SEND_ACK;
                                    bit_counter <= 8;
                                    sda_out <= 0;
                                end
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_READ_REG: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    ack_recieved <= 0;
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                scl_out <= 0; 
                                //sample data on this rising edge of scl
                                o_miso_data[bit_counter-1] <= io_sda;
                                bit_counter <= bit_counter -1;
                                proc_counter <= 3;
                            end
                            3: begin
                                if(bit_counter == 0)begin
                                    state <= S_SEND_NACK;
                                    sda_out <= 1;
                                end
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_SEND_NACK: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                sda_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    ack_recieved <= 0;
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                proc_counter <= 3;
                                scl_out <= 0;
                            end
                            3: begin
                                state <= S_SEND_STOP;
                                proc_counter <= 0;
                                sda_out <= 0;
                            end
                        endcase
                    end
                    
                    S_SEND_ACK: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                                sda_out <= 0;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                proc_counter <= 3;
                                scl_out <= 0;
                            end
                            3: begin
                                state <= post_state;
                                proc_counter <= 0;
                            end
                        endcase
                    end
                    
                    S_SEND_STOP: begin
                        case(proc_counter)
                            0:begin
                                scl_out <= 1;
                                proc_counter <= 1;
                            end
                            1: begin
                                if(io_scl == 1)begin
                                    proc_counter <= 2;
                                end
                            end
                            2: begin
                                proc_counter <= 3;
                                sda_out <= 1;
                            end
                            3: begin
                                state <= S_IDLE;
                                proc_counter <= 0;
                            end
                        endcase
                    end

                endcase
            end
        end
    end
    
//tri state buffer for scl and sdo
assign io_scl = (serial_clock_enable) ? serial_clock : 1'bz;
assign io_sda = (serial_data_enable)  ? serial_data  : 1'bz;
    
endmodule
