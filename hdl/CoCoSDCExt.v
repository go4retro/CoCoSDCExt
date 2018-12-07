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

wire flag_program;
wire flag_ram_8b;
wire flag_ram_cf;
wire ce_mem;
wire flag_ram;
wire we_reg_bank;
wire ce_ymf;
reg [7:0]data_out;
reg [7:0]bdata_out;
wire [18:14]bank;

assign _we =               r_w;
assign data =              data_out;
assign bdata =             bdata_out;
assign _cts_out =          !(_rom_enable & !_cts);
assign ce_ymf =            (!_scs & address[5:2] == 4'b0100);       // $ff50-53
assign _ce_ymf =           !ce_ymf;
assign ce_mem =            !_cts | (flag_program & clock & !r_w & (address[15:13] == 3'b110)); // $c000-$dfff
assign _ce_flash =         !(!flag_ram & ce_mem);
assign _ce_sram =          !(flag_ram & ce_mem);
assign we_reg_bank =       (!_scs & (address[5:0] == 6'b011111));    // $ff5f
assign we_reg_flags =      (!_scs & (address[5:0] == 6'b011110));    // $ff5e
assign _reset_audio =      !(_ce_ymf & r_w & (address[1:0] == 2));   // read of $ff52;
assign baddress =          bank + address[14];

register #(.WIDTH(5))		reg_bank(clock, !_reset, we_reg_bank, data[4:0], bank);
register #(.WIDTH(1))		reg_program(clock, !_reset, we_reg_flags, data[0], flag_program);
register #(.WIDTH(1))		reg_memtype(clock, !_reset, we_reg_flags, data[1], flag_ram);

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
