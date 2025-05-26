//////////////////////////////////////////////////////////////////////////////////
// Company:       www.circuitden.com
// Engineer:      Artin Isagholian
//                artinisagholian@gmail.com
//
// Create Date:    5/27/2025
// Design Name:
// Module Name:    case_003
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
`ifndef _case_003_svh_
`define _case_003_svh_

task case_003();
    $display("Running case 003");
    $display(" Writing value 8'hEF to address 1 using slave 1");
    $display("Configuring master");
    @(posedge testbench.clock);
    testbench.rw            = 0;            //write operation
    testbench.reg_addr      = 8'h01;        //writing to slave register 1
    testbench.data_to_write = 8'hEF;
    testbench.device_addr   = 7'b101_1010;  //slave address
    testbench.divider       = 16'hFFFF;     //divider value for i2c serial clock
    @(posedge testbench.clock);
    $display("Enabling master");
    testbench.enable        = 1;
    @(posedge testbench.i2c_master_busy)
    $display("Master has started writing");
    testbench.enable        = 0;
    @(negedge testbench.i2c_master_busy);
    $display("Master has finsihed writing");

    $display("Reading from address 0 using slave 1");
    $display("Configuring master");
    @(posedge testbench.clock);
    testbench.rw            = 1;            //read operation
    testbench.reg_addr      = 8'h01;        //reading from slave register 1
    testbench.data_to_write = '0;
    testbench.device_addr   = 7'b101_1010;  //slave address
    @(posedge testbench.clock);
    $display("Enabling master");
    testbench.enable        = 1;
    @(posedge testbench.i2c_master_busy)
    $display("Master has started reading");
    testbench.enable        = 0;
    @(negedge testbench.i2c_master_busy);
    $display("Master has finsihed reading");
    assert (testbench.i2c_master_miso_data == 8'hEF) $display ("Read correct data from address 1 using slave 1");
        else $fatal(1, "Read back incorrect data from address 1 using slave 1. Expected %h but got %h", 8'hDC, testbench.i2c_master_miso_data);

endtask: case_003

`endif