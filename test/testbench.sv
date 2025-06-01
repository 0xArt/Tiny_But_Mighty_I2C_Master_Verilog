`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:       www.circuitden.com
// Engineer:      Artin Isagholian
//                artinisagholian@gmail.com
// 
// Create Date:    15:43:35 10/22/2020 
// Design Name: 
// Module Name:    testbench
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`include "./case_000/case_000.svh"
`include "./case_001/case_001.svh"
`include "./case_002/case_002.svh"
`include "./case_003/case_003.svh"


module testbench;

localparam NUMBER_OF_DATA_BYTES     = 1;
localparam NUMBER_OF_REGISTER_BYTES = 1;
localparam DATA_WIDTH               = (NUMBER_OF_DATA_BYTES*8);
localparam REGISTER_WIDTH           = (NUMBER_OF_REGISTER_BYTES*8);
localparam ADDRESS_WIDTH            = 7;
localparam CLOCK_FREQUENCY          = 50_000_000;
localparam CLOCK_PERIOD             = 1e9/CLOCK_FREQUENCY;
localparam SLAVE_0_ADDRESS          = 7'b001_0001;
localparam SLAVE_1_ADDRESS          = 7'b101_1010;


reg                             clock           =   0;
reg                             reset_n         =   1;
reg                             enable          =   0;
reg                             rw              =   0;
reg     [REGISTER_WIDTH-1:0]    reg_addr        =   0;
reg     [6:0]                   device_addr     =   7'b001_0001;
reg     [15:0]                  divider         =   'h0003;
reg     [DATA_WIDTH-1:0]        data_to_write   =   'h00;


wire                            i2c_master_clock;
wire                            i2c_master_reset_n;
wire                            i2c_master_enable;
wire                            i2c_master_read_write;
wire    [DATA_WIDTH-1:0]        i2c_master_mosi_data;
wire    [REGISTER_WIDTH-1:0]    i2c_master_register_address;
wire    [ADDRESS_WIDTH-1:0]     i2c_master_device_address;

wire    [15:0]                  i2c_master_divider;
wire    [DATA_WIDTH-1:0]        i2c_master_miso_data;
wire                            i2c_master_busy;

wire                            scl;
wire                            sda;

i2c_master #(
    .NUMBER_OF_DATA_BYTES           (NUMBER_OF_DATA_BYTES),
    .NUMBER_OF_REGISTER_BYTES       (NUMBER_OF_REGISTER_BYTES),
    .ADDRESS_WIDTH                  (ADDRESS_WIDTH),
    .CHECK_FOR_CLOCK_STRETCHING     (1),
    .CLOCK_STRETCHING_MAX_COUNT     ('hFF)
) i2c_master(
            .clock                  (i2c_master_clock),
            .reset_n                (i2c_master_reset_n),
            .enable                 (i2c_master_enable),
            .read_write             (i2c_master_read_write),
            .mosi_data              (i2c_master_mosi_data),
            .register_address       (i2c_master_register_address),
            .device_address         (i2c_master_device_address),

            .divider                (i2c_master_divider),
            .miso_data              (i2c_master_miso_data),
            .busy                   (i2c_master_busy),

            .external_serial_data   (sda),
            .external_serial_clock  (scl)
);


pullup pullup_scl(scl); // pullup scl line
pullup pullup_sda(sda); // pullup sda line


i2c_slave #(
    .I2C_ADR        (SLAVE_0_ADDRESS),
    .SLAVE_NUMBER   (0)
) i2c_slave_0(
    .scl    (scl),
    .sda    (sda)
);

i2c_slave #(
    .I2C_ADR        (SLAVE_1_ADDRESS),
    .SLAVE_NUMBER   (1)
) i2c_slave_1(
    .scl    (scl),
    .sda    (sda)
);


//clock generation
initial begin
    clock   =   0;
    
    forever begin
        #(CLOCK_PERIOD/2);
        clock   = ~clock;
    end
end


initial begin
    @(posedge clock)
    reset_n = 1;
    @(posedge clock)
    reset_n = 0;
    @(posedge clock)
    reset_n = 1;
    @(posedge clock)

    case_000();
    case_001();
    case_002();
    case_003();
    $display("Tests have finsihed");
    $stop();
end


assign i2c_master_clock             =   clock;
assign i2c_master_reset_n           =   reset_n;
assign i2c_master_enable            =   enable;
assign i2c_master_read_write        =   rw;
assign i2c_master_mosi_data         =   data_to_write;
assign i2c_master_device_address    =   device_addr;
assign i2c_master_register_address  =   reg_addr;
assign i2c_master_divider           =   divider;

endmodule