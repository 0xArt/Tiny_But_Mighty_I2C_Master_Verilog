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


module testbench;

localparam  DATA_WIDTH          =   8;
localparam  REGISTER_WIDTH      =   8;
localparam  ADDRESS_WIDTH       =   7;
localparam  CLOCK_FREQUENCY     =   50_000_000;
localparam  CLOCK_PERIOD        =   1e9/CLOCK_FREQUENCY;

reg             clock           =   0;
reg             reset_n         =   1;
wire            scl;
wire            sda;
reg             enable          =   0;
reg             rw              =   0;
reg     [7:0]   reg_addr        =   0;
reg     [6:0]   device_addr     =   7'b001_0001;
reg     [15:0]  divider         =   16'h0003;
reg     [7:0]   data_to_write   =   8'h00;


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

i2c_master #(.DATA_WIDTH(DATA_WIDTH),.REGISTER_WIDTH(REGISTER_WIDTH),.ADDRESS_WIDTH(ADDRESS_WIDTH))
i2c_master(
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


i2c_slave i2c_slave(
    .scl(scl),
    .sda(sda)
);


//clock generation
initial begin
    clock   =   0;
    
    forever begin
        #(CLOCK_PERIOD/2);
        clock   =   ~clock;
    end
end


initial begin
    @(posedge clock)
    reset_n = 1;
    #100;
    @(posedge clock)
    reset_n = 0;
    #100;
    @(posedge clock)
    reset_n = 1;
    #100;

    $display("Running case 000");
    case_000();
    $display("Running case 001");
    case_001();
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