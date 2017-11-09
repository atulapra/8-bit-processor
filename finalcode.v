`timescale 1 ns / 1 ps
////////////////////////////////////////////////////////////
//Execution Unit
//flag_register[0] is zero flag
//flag_register[1] is compare flag
//flag_register[2] is shifted out bit flag
//flag_register[3] is carry flag
//R0 and R1 are standard input registers. 
//R0 is the standard output register
module execution_unit(ld,write,enable_alu,en_Memory,addr,indata,outdata,fn_sel,flag_register);
input ld,write,enable_alu,en_Memory;
input [7:0] indata;												//Input data
wire [7:0] Databus;												//Databus
input [2:0] addr;												//Address bus
reg [7:0] mem_value;
output reg [3:0] flag_register = 0;
reg [8:0] output9bit=0;										//Holds the 9-bit output of some operations like add,subtract
output [7:0] outdata;
reg [7:0] Memory [0:5];										//Registers
input [2:0] fn_sel;											//Function select lines
assign outdata = mem_value;
assign Databus = ld ? indata : mem_value;						//When ld = 1, load input data in databus. Else, when ld = 0, load databus with value which has been read

//Data Memory
always @(*)
begin
if (en_Memory)
    begin
		if (write) 
		Memory [addr] <= Databus;	// Write
		else 
        mem_value <= Memory [addr];		// Read
    end

//ALU
if(enable_alu)
begin
case(fn_sel)
	3'b000: begin  				//add
			output9bit = Memory [0]+Memory [1];
			Memory [0] = output9bit [7:0];				//R0 is standard output register
			flag_register [3] = output9bit [8];
			if (Memory [0] == 8'b00000000)
			flag_register [0] = 1; 
			else 
			flag_register [0] = 0;
			end
	3'b001: begin  				//subtract
			output9bit  = Memory [0]-Memory [1];
			Memory [0] = output9bit [7:0];
		    flag_register [3] = output9bit [8]; 
			if (Memory [0] == 8'b00000000)
			flag_register [0] = 1;
			else 
			flag_register [0] = 0;
			end
	3'b010: begin  				//and
			 Memory [0] = Memory [0]&Memory [1];
			 if (Memory [0] == 8'b00000000)
			 flag_register [0] = 1;
			 else 
			 flag_register [0] = 0;
			 end
	3'b011: begin     			//or
	         Memory [0] = Memory [0]|Memory [1];
			 if (Memory [0] == 8'b00000000)
			 flag_register [0] = 1;
			 else 
			 flag_register [0] = 0;
			 end
	3'b100: begin     			//left shift
			 flag_register [2] = Memory [0] [7];	//bit shifted out
			 Memory [0] = Memory [0]<<1;
			 if (Memory [0] == 8'b00000000)
			 flag_register [0] = 1;
			 else 
			 flag_register [0] = 0;
			 end
	3'b101: begin          		//right shift
			 flag_register [2] = Memory [0] [0];
			 Memory [0] = Memory [0]>>1;
			 if (Memory [0] == 8'b00000000)
			 flag_register [0] = 1;
			 else 
			 flag_register [0] = 0;
			 end
	3'b110: begin               //compare 
			 output9bit  = Memory [1]-Memory [0];
			 flag_register [1] = output9bit [8];			//Becomes 1 when Memory[0] > Memory[1]
			 if (output9bit == 9'b000000000)
			 flag_register [0] = 1;
			 else 
			 flag_register [0] = 0;
			 end
	3'b111: begin  				//increment
			 output9bit = Memory [0] + 1;
			 flag_register [3] = output9bit [8];
			 Memory [0] = output9bit [7:0];
			 if (Memory [0] == 0)
			 flag_register [0] = 1;
			 else
			 flag_register [0] = 0;
			 end
endcase
end 
end

endmodule


///////////////////////////////////////////////////////////////////
//Instruction Decoder
module instruction_decoder(instructions,op1,op2,op3,data,opcode,ram_address);
input [30:0] instructions;
output [2:0] op1,op2,op3;
output [7:0] data;
output [3:0] opcode;
output [9:0] ram_address;
assign ram_address = instructions [30:21];
assign data = instructions [20:13];
assign op1 = instructions [12:10];
assign op2 = instructions [9:7];
assign op3 = instructions [6:4];
assign opcode = instructions [3:0];
endmodule

//////////////////////////////////////////////////////////////
//Execution Unit Control Logic
module eucl(clock,op1,op2,op3,data,opcode,dataout,p_c,output_pc,en_ram,wram,str,load_ram);
input [7:0] p_c;											//Input value of PC
input [2:0] op1,op2,op3;									//Operands
input [3:0] opcode;
output [7:0] output_pc;										//Output value of PC
input [7:0] data;
wire [3:0] flag;
output reg en_ram,wram,str,load_ram;
reg [7:0] branch;
reg p_c_val,check_branch; 
input clock;
output [7:0] dataout;
reg ld,write,enable_alu,en_Memory;
reg [2:0] addr;											
reg [2:0] control_bus;
reg [4:0] state = 5'b00000;									//State machine
assign output_pc = check_branch ? branch : p_c + p_c_val;			
initial 
begin 
branch=0;
p_c_val = 0;
check_branch=0;
load_ram=0;
str=0;
ld=0;
write=0;
enable_alu=0;
en_Memory=0;
wram=0;
en_ram=0;
end
execution_unit EU(.ld(ld),.write(write),.enable_alu(enable_alu),.en_Memory(en_Memory),.addr(addr),.indata(data),.outdata(dataout),.fn_sel(control_bus),.flag_register(flag));

always @(posedge clock)
begin

check_branch <=0;
ld<=0;
write<=0;
enable_alu<=0;
en_Memory <=0;
p_c_val<=0;
wram <= 0;
en_ram <= 0;
branch <= data;
load_ram <= 0;
str <= 0;

if (state==5'b01111) //Increments value of program counter 
begin
state<=5'b00000;	//Reset to zero state
p_c_val<=1;
end 

else if (state==5'b11111) //Branching
begin
check_branch <= 1;
state <= 5'b00000;
end

else if(opcode==4'b0001) // move from op1 to op2
begin
if (state==5'b00000)
begin
addr <= op1;
en_Memory <= 1;											//Memory is enabled for read
state <= 5'b00001;
end 
else if (state==5'b00001)
begin
addr <=op2;
en_Memory <= 1;					
write <= 1;											
state <= 5'b01111;										//Increment PC
end
end

else if (opcode==4'b0010) //load to memory
begin
if (state==5'b00000)
begin
addr <= op1;
ld <= 1;				//Load memory
en_Memory <= 1;
write <= 1;
state <= 5'b01111;
end
end

else if (opcode==4'b0011) //add
begin
if (state==5'b00000)
begin
addr <= op1;
en_Memory <= 1;
state <= 5'b00001;
end 
else if (state==5'b00001)
begin
addr <=3'b000;									//Write op1 to R0
en_Memory <= 1;
write <= 1;
state <= 5'b00010;
end
else if (state==5'b00010)
begin
addr <= op2;
en_Memory <= 1;
state <= 5'b00011;
end 
else if (state==5'b00011)
begin
addr <=3'b001;									//Write op2 to R1
en_Memory <= 1;
write <= 1;
state <= 5'b00100;
end
else if (state==5'b00100)
begin
control_bus <= 3'b000;
enable_alu <= 1 ;
state <= 5'b00101;
end
else if (state==5'b00101)
begin
addr <= 3'b000 ;								//Read the value stored in R0(the standard output register)
en_Memory <= 1;
state <= 5'b00110;
end
else if (state==5'b00110)
begin
addr <= op3;									//Write value of R0 to op3
en_Memory <= 1;
write <= 1;
state <= 5'b01111;
end
end

else if (opcode==4'b0100) //subtract
begin
if (state==5'b00000)
begin
addr <= op1;
en_Memory <= 1;
state <= 5'b00001;
end 
else if (state==5'b00001)
begin
addr <=3'b000;
en_Memory <= 1;
write <= 1;
state <= 5'b00010;
end
else if (state==5'b00010)
begin
addr <= op2;
en_Memory <= 1;
state <= 5'b00011;
end 
else if (state==5'b00011)
begin
addr <=3'b001;
en_Memory <= 1;
write <= 1;
state <= 5'b00100;
end
else if (state==5'b00100)
begin
control_bus <= 3'b001;
enable_alu <= 1 ;
state <= 5'b00101;
end
else if (state==5'b00101)
begin
addr <= 3'b000 ;
en_Memory <= 1;
state <= 5'b00110;
end
else if (state==5'b00110)
begin
addr <= op3;
en_Memory <= 1;
write <= 1;
state <= 5'b01111;
end
end

else if (opcode==4'b0101) //and
begin
if (state==5'b00000)
begin
addr <= op1;
en_Memory <= 1;
state <= 5'b00001;
end 
else if (state==5'b00001)
begin
addr <=3'b000;
en_Memory <= 1;
write <= 1;
state <= 5'b00010;
end
else if (state==5'b00010)
begin
addr <= op2;
en_Memory <= 1;
state <= 5'b00011;
end 
else if (state==5'b00011)
begin
addr <=3'b001;
en_Memory <= 1;
write <= 1;
state <= 5'b00100;
end
else if (state==5'b00100)
begin
control_bus <= 3'b010;
enable_alu <= 1 ;
state <= 5'b00101;
end
else if (state==5'b00101)
begin
addr <= 3'b000 ;
en_Memory <= 1;
state <= 5'b00110;
end
else if (state==5'b00110)
begin
addr <= op3;
en_Memory <= 1;
write <= 1;
state <= 5'b01111;
end
end

else if (opcode==4'b0110) //or
begin
if (state==5'b00000)
begin
addr <= op1;
en_Memory <= 1;
state <= 5'b00001;
end 
else if (state==5'b00001)
begin
addr <=3'b000;
en_Memory <= 1;
write <= 1;
state <= 5'b00010;
end
else if (state==5'b00010)
begin
addr <= op2;
en_Memory <= 1;
state <= 5'b00011;
end 
else if (state==5'b00011)
begin
addr <=3'b001;
en_Memory <= 1;
write <= 1;
state <= 5'b00100;
end
else if (state==5'b00100)
begin
control_bus <= 3'b011;
enable_alu <= 1 ;
state <= 5'b00101;
end
else if (state==5'b00101)
begin
addr <= 3'b000 ;
en_Memory <= 1;
state <= 5'b00110;
end
else if (state==5'b00110)
begin
addr <= op3;
en_Memory <= 1;
write <= 1;
state <= 5'b01111;
end
end

else if (opcode==4'b0111) //left shift
begin
if (state==5'b00000)
begin
addr <= op1;
en_Memory <= 1;
state <= 5'b00001;
end 
else if (state==5'b00001)
begin
addr <=3'b000;
en_Memory <= 1;
write <= 1;
state <= 5'b00010;
end
else if (state==5'b00010)
begin
control_bus <= 3'b100;
enable_alu <= 1 ;
state <= 5'b00011;
end
else if (state==5'b00011)
begin
addr <= 3'b000 ;
en_Memory <= 1;
state <= 5'b00100;
end
else if (state==5'b00100)
begin
addr <= op1;
en_Memory <= 1;
write <= 1;
state <= 5'b01111;
end
end

else if (opcode==4'b1000) //right shift
begin
if (state==5'b00000)
begin
addr <= op1;
en_Memory <= 1;
state <= 5'b00001;
end 
else if (state==5'b00001)
begin
addr <=3'b000;
en_Memory <= 1;
write <= 1;
state <= 5'b00010;
end
else if (state==5'b00010)
begin
control_bus <= 3'b101;
enable_alu <= 1 ;
state <= 5'b00011;
end
else if (state==5'b00011)
begin
addr <= 3'b000 ;
en_Memory <= 1;
state <= 5'b00100;
end
else if (state==5'b00100)
begin
addr <= op1;
en_Memory <= 1;
write <= 1;
state <= 5'b01111;
end
end

else if (opcode==4'b1001) //store in RAM from memory
begin
if (state==5'b00000)
begin
addr <= op1;
en_Memory <= 1;
state <= 5'b00001;
end
else if (state==5'b00001)
begin
en_ram <= 1;
wram <= 1;
str <= 1;							//data_out
state <= 5'b01111;
end
end

else if (opcode==4'b1010) //compare flag set if op1 > op2
begin
if (state==5'b00000)
begin
addr <= op1;
en_Memory <= 1;
state <= 5'b00001;
end 
else if (state==5'b00001)
begin
addr <=3'b000;
en_Memory <= 1;
write <= 1;
state <= 5'b00010;
end
else if (state==5'b00010)
begin
addr <= op2;
en_Memory <= 1;
state <= 5'b00011;
end 
else if (state==5'b00011)
begin
addr <=3'b001;
en_Memory <= 1;
write <= 1;
state <= 5'b00100;
end
else if (state==5'b00100)
begin
control_bus <= 3'b110;
enable_alu <= 1 ;
state <= 5'b01111;
end
end

else if (opcode==4'b1011) //Branch if greater
begin
if (state==5'b00000)
begin
if (flag [1])
state <= 5'b11111;							//Branch
else
state <= 5'b01111;							//Don't branch
end
end

else if (opcode==4'b1100) //Branch if zero
begin
if (state==5'b00000)
begin
if (flag [0])
state <= 5'b11111;
else
state <= 5'b01111;
end
end

else if (opcode==4'b1101) //Branch if shifted out bit 
begin
if (state==5'b00000)
begin
if (flag [2])
state <= 5'b11111;
else
state <= 5'b01111;
end
end

else if (opcode==4'b1110) //load to Memory from RAM
begin
if (state==5'b00000)
begin
en_ram <= 1;
load_ram <= 1;  						//Read from RAM			
state <= 5'b00001;
end
else if (state==5'b00001)
begin
load_ram <= 1;
addr <= op1;
ld <= 1;
en_Memory <= 1;
write <= 1;							//Write to memory
state <= 5'b01111;
end
end

else if (opcode==4'b1111) //Load to RAM immediate
begin
en_ram <= 1;
wram <= 1;
state <= 5'b01111;
end

end
endmodule

////////////////////////////////////////////////////////
//Program Memory
module program_Memory(p_c,instr);
input [7:0] p_c;								//Line of program
reg [30:0] p_memory [0:255];					//Program memory
output [30:0] instr;
initial begin
//Add
p_memory [0] = 31'b0000000000000001100100000000010;	//Load 6. op1 = 010
p_memory [1] = 31'b0000000000000010001000000000010;	//Load 8. op1 = 100
p_memory [2] = 31'b0000000000000000001000100100011;  //Add 100 and 010. Store in 010.
//Sub
p_memory [3] = 31'b0000000000000001100100000000010;	//Load 6. op1 = 010
p_memory [4] = 31'b0000000000000001001000000000010;	//Load 4. op1 = 100
p_memory [5] = 31'b0000000000000000000101000100100;  //Subtract 010 - 100. Store in 010.
//And
p_memory [6] = 31'b0000000000000001010100000000010;	//Load 5. op1 = 010
p_memory [7] = 31'b0000000000000000111000000000010;	//Load 3. op1 = 100
p_memory [8] = 31'b0000000000000000000101000100101;  //And both. Store in 010.
//Or
p_memory [9] = 31'b0000000000000001100100000000010;	//Load 6. op1 = 010
p_memory [10] = 31'b0000000000000000111000000000010;	//Load 3. op1 = 100
p_memory [11] = 31'b0000000000000000000101000100110;  //Or both. Store in 010.
//Left shift
p_memory [12] = 31'b0000000000011001100100000000010;	//Load 6. op1 = 010
p_memory [13] = 31'b0000000000000000000100000000111;	//Logical shift left
//Right shift
p_memory [14] = 31'b0000000000011001100100000000010;	//Load 6. op1 = 010
p_memory [15] = 31'b0000000000000000000100000001000;	//Logical shift right
//Compare         
p_memory [16] = 31'b0000000000000001100100000000010;	//Load 6. op1 = 010 
p_memory [17] = 31'b0000000000000010001000000000010;	//Load 8. op1 = 100        
p_memory [18] = 31'b0000000000000000000101000001010;	//compare    
//Branch if greater         
p_memory [19] = 31'b0000000000000001100100000000010;	//Load 6. op1 = 010 
p_memory [20] = 31'b0000000000000010001000000000010;	//Load 8. op1 = 100         
p_memory [21] = 31'b0000000000000000000010000001011;	       
//Branch if zero         
p_memory [22] = 31'b0000000000011001100100000000010;	//Load 6. op1 = 010
p_memory [23] = 31'b0000000000000010001000000000010;	//Load 8. op1 = 100          
p_memory [24] = 31'b0000000000000000000010000001100;	        
//Branch if a bit is shifted out         
p_memory [25] = 31'b0000000000011001100100000000010;	//Load 6. op1 = 010
p_memory [26] = 31'b0000000000000010001000000000010;	//Load 8. op1 = 100          
p_memory [27] = 31'b0000000000000000000010000001101;	        
//Load from Memory         
p_memory [28] = 31'b0000000000011001100100000000010;	//Load 6. op1 = 010 
p_memory [29] = 31'b0000000000000010001000000000010;	//Load 8. op1 = 100         
p_memory [30] = 31'b0000000000000000000010000001110;	         
//Load Memory (RAM) immediate         
p_memory [31] = 31'b0000000000011001100100000000010;	//Load 6. op1 = 010 
p_memory [32] = 31'b0000000000000010001000000000010;	//Load 8. op1 = 100         
p_memory [33] = 31'b0000000000000000000010000001111;	         
end         
assign instr = p_memory [p_c];         
endmodule

////////////////////////////////////////////////////////
//Main Memory (RAM)
module main_Memory (enable, Write, Address, Databus, DataOut);
	input Write,enable;
	input [7: 0] Databus;
	input [9: 0] Address;			//10-bit address
	output reg [7: 0] DataOut;
	reg [7: 0] Memory [0: 1023]; 	// 1024 x 8 Memory
	always @ (*)
    begin
    if (enable)
    begin
		if (Write) 
		Memory [Address] <= Databus;	// Write
		else 
        DataOut <= Memory [Address];	//Read
    end
    end
endmodule

///////////////////////////////////////////////////////
//Control Unit
module control_unit(clock,data_out,temp);
input clock;
wire [9:0] ram_ad;
reg [7:0] p_c = 0;
wire [7:0] pfcl,data,ram_out,ram_in,data_eucl;
wire [2:0] op1,op2,op3;
wire [3:0] opcode;
wire [30:0] instr;
wire en_ram,ram_w,str,load_ram;
output [7:0] data_out,temp;
assign ram_in = str ? data_out : data;  	    //store vs load immediate
assign data_eucl = load_ram ? ram_out : data; 	//load immediate reg vs load  
program_Memory PM(.p_c(pfcl),.instr(instr));
instruction_decoder IDE(.instructions(instr),.op1(op1),.op2(op2),.op3(op3),.data(data),.opcode(opcode),.ram_address(ram_ad));
eucl EUCL(.clock(clock),.op1(op1),.op2(op2),.op3(op3),.data(data_eucl),.opcode(opcode),.dataout(data_out),.p_c(p_c),.output_pc(pfcl),.en_ram(en_ram),.wram(ram_w),.str(str),.load_ram(load_ram));
main_Memory RAM(.enable(en_ram),.Write(ram_w),.Address(ram_ad),.Databus(ram_in),.DataOut(ram_out));
always @(posedge clock)
begin
p_c <= pfcl;
end
endmodule