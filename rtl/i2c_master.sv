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
    input       [DATA_WIDTH-1:0]        mosi_data,
    input       [REGISTER_WIDTH-1:0]    register_address,
    input       [ADDR_WIDTH-1:0]        device_address,
    input  wire [15:0]                  divider,
    output reg  [DATA_WIDTH-1:0]        miso_data,
    output reg                          o_busy = 0,
    inout                               external_serial_data,
    inout                               external_serial_clock
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
                _process_counter        =   0;
                _bit_counter            =   0;
                _last_acknowledge       =   0;
                _saved_read_write       =   read_write;
                _busy                   =   0;
                _saved_register_address =   register_address;
                _saved_device_address   =   device_address;
                _saved_mosi_data        =   mosi_data;
                _sda                    =   0;
                _scl                    =   0;
                if (enable) begin
                    _state      =   S_START;
                    _post_state =   S_WRITE_ADDR_W;
                end
            end

            S_START: begin
                case (process_counter) begin
                    0: begin
                        _busy               =   1;
                        _process_counter    =   1;
                    end
                    1: begin
                        _serial_data        =   0;
                        _process_counter    =   2;
                    end
                    2:  begin
                        _bit_counter        =   8;
                        _process_counter    =   3;
                    end
                    3:  begin
                        _serial_clock       =   0;
                        _process_counter    =   0;
                        _state              =   post_state;
                        _serial_data        =   saved_device_address[ADDR_WIDTH];
                    end
                endcase
            end
            S_WRITE_ADDR_W: begin
                case (process_counter) begin
                    0: begin
                        _serial_clock       =   1;
                        _process_counter    =   1;
                    end
                    1: begin
                        if (external_serial_clock == 1) begin
                            _process_counter    =   2;
                        end
                    end
                    2: begin
                        _serial_clock       =   0;
                        _bit_counter        =   bit_counter -   1;
                        _process_counter    =   3;
                    end
                    3: begin
                        if (bit_counter == 0) begin
                            _post_serial_data   =   saved_register_address[REGISTER_WIDTH-1];

                            if( REGISTER_WIDTH == 16) begin
                                _post_state =   S_WRITE_REG_ADDR_MSB;
                            end
                            else begin
                                _post_state =   S_WRITE_REG_ADDR;
                            end

                            _state          =   S_CHECK_ACK;
                            _bit_counter    =   8;
                        end
                        else begin
                            _serial_data    =   saved_device_address[bit_counter-1];
                        end
                        _process_counter    =   0;
                    end
                end
            end
            S_CHECK_ACK: begin
                case (process_counter)
                    0: begin
                        _serial_clock       =   1;
                        _process_counter    =   1;
                    end
                    1: begin
                        if (external_serial_clock == 1) begin
                            _last_acknowledge   =   0;
                            _process_counter    =   2;
                        end
                    end
                    2: begin
                        _serial_clock   =   0;

                        if (external_serial_data == 0) begin
                            _last_acknowledge   =   1;
                        end
                        _process_counter    =   3;
                    end
                    3:  begin
                        if (last_acknowledge == 1) begin
                            _last_acknowledge   =   0;
                            _serial_data        =   post_serial_data;
                            _state              =   post_state;
                        end
                        else begin
                            _state  =   S_IDLE;
                        end
                        _process_counter =   0;
                    end
                endcase
            end
            S_WRITE_REG_ADDR_MSB: begin
                case (process_counter)
                    0: begin
                        _serial_clock_out   =   1;
                        _process_counter    =   1;
                    end
                    1: begin
                        if (external_serial_clock == 1) begin
                            _last_acknowledge   =   0;
                            _process_counter    =   2;
                        end
                    end
                    2: begin
                        _serial_clock       =   0;
                        _bit_counter        =   bit_counter - 1;
                        _process_counter    =   3;
                    end
                    3: begin
                        if (bit_counter == 0) begin
                            _post_state         =   S_WRITE_REG_ADDR;
                            _post_serial_data   =   saved_register_address[7];
                            _bit_counter        =   8;
                            _serial_data        =   0;
                            _state              =   S_CHECK_ACK;
                        end
                        else begin
                            _serial_data        =   saved_register_address[bit_counter+7];
                        end
                        _process_counter        =   0;
                    end
                endcase
            end
            S_WRITE_REG_ADDR: begin
                case (process_counter) begin
                    0: begin
                        _serial_clock       =   1;
                        _process_counter    =   1;
                    end
                    1: begin
                        if (external_serial_clock == 1) begin
                            _last_acknowledge   =   0;
                            _process_counter    =   0;
                        end
                    end
                    2: begin
                        _serial_clock       =   0;
                        _bit_counter        =   bit_counter - 1;
                        _process_counter    =   3;
                    end
                    3: begin
                        if (bit_counter == 0) begin
                            if (read_write == 0) begin
                                if (DATA_WIDTH == 16) begin
                                    _post_state         =   S_WRITE_REG_DATA_MSB;
                                    _post_serial_data   =   saved_mosi_data[15];
                                end
                                else begin
                                    _post_state         =   S_WRITE_REG_DATA_MSB;
                                    post_sda_out        =   saved_mosi_data[7];
                                end
                            end
                            else begin
                                _post_state         =   S_RESTART;
                                _post_serial_data   =   1;
                            end
                            _bit_counter    =   8;
                            _serial_data    =   0;
                            _state          =   S_CHECK_ACK;
                        end
                        else begin
                            _serial_data    =   saved_register_address[bit_counter-1];
                        end
                        _process_counter    =   0;
                    end
                endcase
            end
            S_WRITE_REG_DATA_MSB: begin
                case (process_counter) begin

                end
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
    
endmodule
