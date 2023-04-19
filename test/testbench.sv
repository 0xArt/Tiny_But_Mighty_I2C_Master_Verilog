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
module testbench(

);

localparam  DATA_WIDTH      =   8;
localparam  REGISTER_WIDTH  =   8;
localparam  ADDRESS_WIDTH   =   7;

real    clockDelay50    = ((1/ (50e6))/2)*(1e9);
reg     clock           = 0;
reg     reset_n         = 0;

//clock gen
always begin
    #clockDelay50;
    clock = ~clock;
end

wire scl;
wire sda;

pullup p1(scl); // pullup scl line
pullup p2(sda); // pullup sda line

reg             enable          = 0;
reg             rw              = 0;
reg     [7:0]   mosi            = 0;
reg     [7:0]   reg_addr        = 0;
reg     [6:0]   device_addr     = 7'b001_0001;
reg     [15:0]  divider         = 16'h0003;
wire    [7:0]   miso;
wire            busy;

reg     [7:0]   read_data       = 0;
reg     [7:0]   data_to_write   = 8'hDC;
reg     [7:0]   proc_cntr       = 0;


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

i2c_slave i2c_slave(
    .scl(scl),
    .sda(sda)
);



    always@(posedge clock)begin
        if(proc_cntr < 20 && proc_cntr > 5)begin
            proc_cntr <= proc_cntr + 1;
        end
        case (proc_cntr)
            0: begin
                reset_n     <= 0;
                proc_cntr   <= proc_cntr + 1;
            end
            1: begin
                reset_n     <= 1;
                proc_cntr   <= proc_cntr + 1;
            end
            //set configration first
            2: begin
                rw            <= 0; //write operation
                reg_addr      <= 8'h00; //writing to slave register 0
                data_to_write <= 8'hAC;
                device_addr   <= 7'b001_0001; //slave address
                divider       <= 16'hFFFF; //divider value for i2c serial clock
                proc_cntr     <= proc_cntr + 1;
            end
            3: begin
                //if master is not busy set enable high
                if(busy == 0)begin
                    enable      <= 1;
                    $display("Enabled write");
                    proc_cntr   <= proc_cntr + 1;
                end
            end
            4: begin
                //once busy set enable low
                if(busy == 1)begin
                    enable      <= 0;
                    proc_cntr   <= proc_cntr + 1;
                end
            end
            5: begin
                //as soon as busy is low again an operation has been completed
                if(busy == 0) begin
                    proc_cntr <= proc_cntr + 1;
                    $display("Master done writing");
                end
            end
            20: begin
                rw          <= 1; //write operation
                reg_addr    <= 8'h00; //writing to slave register 0
                mosi        <= data_to_write; //data to be written
                device_addr <= 7'b001_0001; //slave address
                divider     <= 16'hFFFF; //divider value for i2c serial clock
                proc_cntr   <= proc_cntr + 1;
            end
            21: begin
                if(busy == 0)begin
                    enable      <= 1;
                    $display    ("Enabled read");
                    proc_cntr   <= proc_cntr + 1;
                end
            end
            22: begin
                if(busy == 1)begin
                    enable <= 0;
                    proc_cntr <= proc_cntr + 1;
                end
            end
            23: begin
                if(busy == 0)begin
                    read_data <= miso;
                    proc_cntr <= proc_cntr + 1;
                    $display("Master done reading");
                end
            end
            24: begin
                if(read_data == data_to_write)begin
                    $display("Read back correct data!");
                end
                else begin
                    $display("Read back incorrect data!");
                end
                $stop;
            end
            11: begin
                //do nothing
            end

        endcase 

    end


assign i2c_master_clock             =   clock;
assign i2c_master_reset_n           =   reset_n;
assign i2c_master_enable            =   enable;
assign i2c_master_read_write        =   rw;
assign i2c_master_mosi_data         =   data_to_write;
assign i2c_master_device_address    =   device_addr;
assign i2c_master_register_address  =   reg_addr;
assign i2c_master_divider           =   divider;

assign miso                         =   i2c_master_miso_data;
assign busy                         =   i2c_master_busy;


endmodule
