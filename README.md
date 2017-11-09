# 8-bit-processor

* This project aims to construct an 8-bit processor in verilog. The code works on Ubuntu 16.04.

## Installation

* First install iverilog using `sudo apt-get install iverilog`.

* Next, install gtkwave using `sudo apt-get install gtkwave`.

## Usage

* Let the name of the test fixture be `test_fixture.v` and the name of the module file be `modulefile.v`.

* Go to the terminal and type: `iverilog -o pro test_fixture.v modulefile.v`. This creates an executable file called `pro`.

* Now, type `vvp pro` to create a .vcd file, say `test.vcd`.

* Then, type `gtkwave test.vcd` to view the simulation.

## Architecture

![Harvard Architecture](Harvard_architecture.png)

## Specifications

* 4-bit opcode
* 3-bit control bus
* 8-bit databus
* 1024 x 8 RAM

## Opcodes

* 0000 EOP
* 0001 move
* 0010 load immediate
* 0011 add
* 0100 subtract
* 0101 and
* 0110 or
* 0111 left shift
* 1000 right shift
* 1001 store
* 1010 compare flag set if op1 > op2
* 1011 branch if greater
* 1100 branch if equal
* 1101 branch if shifted out
* 1110 load from memory
* 1111 load memory(RAM) immediate