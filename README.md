# 8-bit-processor

* This project aims to construct an 8-bit processor in verilog. The code works on Ubuntu 16.04.

## Installation

* First install iverilog using `sudo apt-get install iverilog`.

* Next, install gtkwave using `sudo apt-get install gtkwave`.

## Usage

* Let the name of the test fixture be `test_fixture.v` and the name of the module file be `modulefile.v`.

* Go to the terminal and type: `iverilog -o pro test_fixture.v modulefile.v`. This creates an executable file called `pro`.

* Now, type `vvp pro` to create a .vcd file, say test.vcd.

* Then, type `gtkwave test.vcd` to view the simulation.

## Architecture

