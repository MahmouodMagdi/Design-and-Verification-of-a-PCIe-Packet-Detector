///////////////////////////////////////////////////////////////////////////
//
//	**********  ICE POSITION VERIFICATION ENVIORNMENT  **********
//
//	AUTHOR		: MAHMOUD MAGDI
//	
//	Module Name : Test-Bench Environment Top Module 
//
//	Description	: A SystemVerilog Class-Based VERIFICATION Environment
//				  "UVM From Scratch" used to test the PKT detector 
//				  design.
//
//
///////////////////////////////////////////////////////////////////////////


// Include Classes Package, DUT Interface, and DUT Files

`include"pkg.sv"
`include"PKT_IF.sv"
`include"PKT_TOP.sv"


//////////////////////////////////////////////////////////////
////////////////        Test-Bench Top         ///////////////
//////////////////////////////////////////////////////////////
module PKT_Test_Top;

  parameter	  CLK_PER       = 10  ,
			  DATA_WIDTH    = 8   ,
			  PKT_CNT_WIDTH = 4   ,
			  OUT_PKT_WIDTH = 160 ;
			  
  bit clk;
  bit reset;

  // Pakcage Importion
  import pkg::*;
  
  // Packet Interface Instance 
  PKT_IF pkt_intf(clk,reset);


  // Environment Class Instance 
  environment env;



  // Clock Generation 
  always #(CLK_PER/2) clk = ~clk;


///////////////////////////
//    DUT INSTANTIATION  //
///////////////////////////
  PKT_Detector #(
  
		.DATA_WIDTH   (DATA_WIDTH   ),
		.PKT_CNT_WIDTH(PKT_CNT_WIDTH),
		.OUT_PKT_WIDTH(OUT_PKT_WIDTH)
	
  ) DUT (

		.reset      (pkt_intf.reset    ),                                                     
		.clk        (pkt_intf.clk      ),                                                     
		.data_in    (pkt_intf.data_in  ),                                                     
		.dataK      (pkt_intf.dataK    ),                                                          
		.PKT_count  (pkt_intf.PKT_count),                                                     
		.PKT        (pkt_intf.PKT      ),                                                     
		.MRd        (pkt_intf.MRd      ), 
		.MWr        (pkt_intf.MWr      ), 
		.IORd       (pkt_intf.IORd     ), 
		.IOWr       (pkt_intf.IOWr     ), 
		.CfgRd0     (pkt_intf.CfgRd0   ), 
		.CfgWr0     (pkt_intf.CfgWr0   ), 
		.CfgRd1     (pkt_intf.CfgRd1   ), 
		.CfgWr1     (pkt_intf.CfgWr1   ), 
		.Cpl        (pkt_intf.Cpl      ), 
		.Cp1D       (pkt_intf.Cp1D     ) 

  );


  initial 
    begin

      // Reset Assertion
      reset = 1'b0;	

      // Reset De-Assertion
      #(CLK_PER) reset = 1'b1;

      #10000  reset = 1'b0;
      #11000  reset = 1'b1;
      #100000 reset = 1'b0;
      #400000 reset = 1'b1;
      #9900000 $finish;

    end


  // Dump Generation
  initial
    begin

      $dumpfile("PACKET_DETECTOR_dump.vcd");
      $dumpvars;

    end


  initial 
    begin

      env  = new(pkt_intf);
      env.Seq.repeat_count = 10000;									

      // Calling the run test task from the Environment Class
      env.run();

    end
endmodule
