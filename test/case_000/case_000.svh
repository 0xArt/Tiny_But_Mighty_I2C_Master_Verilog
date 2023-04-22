//////////////////////////////////////////////////////////////////////////////////
// Company:       www.circuitden.com
// Engineer:      Artin Isagholian
//                artinisagholian@gmail.com
//
// Create Date:    15:43:35 4/22/2020
// Design Name:
// Module Name:    case_000
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
`ifndef _case_000_svh_
`define _case_000_svh_

task case_000();

    $display(" Writing value 8'hAC to address 0");
    $display("Configuring master");
    @(posedge testbench.clock);
    testbench.rw            = 0;            //write operation
    testbench.reg_addr      = 8'h00;        //writing to slave register 0
    testbench.data_to_write = 8'hAC;
    testbench.device_addr   = 7'b001_0001;  //slave address
    testbench.divider       = 16'hFFFF;     //divider value for i2c serial clock
    @(posedge testbench.clock);
    $display("Enabling master");
    testbench.enable        = 1;
    @(posedge testbench.i2c_master_busy)
    $display("Master has started writing");
    testbench.enable        = 0;
    @(negedge testbench.i2c_master_busy);
    $display("Master has finsihed writing");

    $display("Reading from address 0");
    $display("Configuring master");
    @(posedge testbench.clock);
    testbench.rw            = 1;            //read operation
    testbench.reg_addr      = 8'h00;        //reading from slave register 0
    testbench.data_to_write = 8'h00;
    testbench.device_addr   = 7'b001_0001;  //slave address
    @(posedge testbench.clock);
    $display("Enabling master");
    testbench.enable        = 1;
    @(posedge testbench.i2c_master_busy)
    $display("Master has started reading");
    testbench.enable        = 0;
    @(negedge testbench.i2c_master_busy);
    $display("Master has finsihed reading");
    assert (testbench.i2c_master_miso_data == 8'hAC) $display ("Read correct data from address 0");
        else $error("Read back incorrect data from address 0. Expected %h but got %h", 8'hAC, testbench.i2c_master_miso_data);

endtask: case_000

`endif