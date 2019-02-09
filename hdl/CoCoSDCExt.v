`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:12:03 12/06/2018 
// Design Name: 
// Module Name:    CoCoSDCExt 
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
module CoCoSDCExt(
                  input _reset,
                  input clock,
                  input [15:0]address,
                  output [18:14]baddress,
                  inout [7:0]data,
                  inout [7:0]bdata,
                  input r_w,
                  input _cts,
                  output _cts_out,
                  input _scs,
                  input _slenb,
                  input _rom_enable,
                  output _ce_flash,
                  output _ce_sram,
                  output _ce_ymf,
                  output _we,    // should see if we can remove this from the PCB and wire !we to r/w
                  output _reset_audio
                 );

parameter FAM_ZZ =         4'h3;  // ZippsterZone (Ed Snider)
parameter ID_YMF =         4'h5;  // YMF_AUDIO
parameter VER_YMF =        4'h2;  // second version (first being the one on the Mega-Mini-MPI

parameter FAM_RI =         4'h2;  // RETRO Innovations
parameter ID_CME =         4'h3;  // CocoMemExpander
parameter VER_CME =        4'h1;  // first version

wire ce_mem;
wire [1:0]mem_type;
wire we_reg_bank;
wire ce_ymf;
reg [7:0]data_out;
reg [7:0]bdata_out;
wire [18:14]bank;
wire rom_enable;
wire flag_memset;

// mem_type:
// 00 = off
// 01 = ROM
// 10 = R/O RAM
// 11 = R/W RAM

assign rom_enable =        !_rom_enable & !flag_memset | (mem_type == 2'b10);
assign _we =               r_w;
assign data =              data_out;
assign bdata =             bdata_out;

// cts out should be active if we aren't using internal memory OR external rom is enabled and no one has selected memory
assign _cts_out =          !(!_cts & (((mem_type == 0) & flag_memset) | (_rom_enable & !flag_memset)));
assign ce_ymf =            (!_scs & address[5:2] == 4'b0100);     // $ff50-53
assign _ce_ymf =           !ce_ymf;
// select memory if cts lo or we're in program mode and write and address in range
assign ce_mem =            !_cts | (mem_type[0] & clock & !r_w & (address[15:13] == 3'b110)); // $c000-$dfff
assign _ce_flash =         !(rom_enable & ce_mem);
assign _ce_sram =          !(mem_type[1] & ce_mem);
assign we_reg_bank =       (!_scs & (address[5:0] == 6'b011111));    // $ff5f
assign we_reg_flags =      (!_scs & (address[5:0] == 6'b011110));    // $ff5e
assign _reset_audio =      !(ce_ymf & r_w & (address[1:0] == 2));   // read of $ff52;
assign baddress =          bank + address[14];

register #(.WIDTH(5))		reg_bank(clock, !_reset, we_reg_bank, data[4:0], bank);
register #(.WIDTH(1))		reg_memset(clock, !_reset, we_reg_flags, 1, flag_memset);
register #(.WIDTH(2))		reg_memtype(clock, !_reset, we_reg_flags, data[1:0], mem_type);

always @(*)
begin
   if(ce_ymf & r_w & clock & (address[1:0] == 1))
      data_out = {FAM_ZZ, ID_YMF};
   else if (ce_ymf & r_w & clock & (address[1:0] == 3))
      data_out = {VER_YMF, 4'b0};
   else if (ce_ymf & r_w & clock)
      data_out = bdata;
   else
      data_out = 8'bz;
end

always @(*)
begin
   if(ce_ymf & !r_w)
      bdata_out = data;
   else
      bdata_out = 8'bz;
end

endmodule
