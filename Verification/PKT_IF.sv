///////////////////////////////////////////////////////////////////////////
//
//	**********  ICE POSITION ASSIGNMENT  **********
//
//	AUTHOR		: MAHMOUD MAGDI
//
//	Module Name : Packet Interface 
//	
//	Description	: A SystemVerilog Parametrized Interface for easier 
//			      connections and interactions between the DUT and different 
//				  environment components.
//
///////////////////////////////////////////////////////////////////////////




//////////////////////////////////////////////////////////////
////////////////       Packet Interface        ///////////////
//////////////////////////////////////////////////////////////
interface PKT_IF #(

	  parameter   DATA_WIDTH    = 8   ,
				  PKT_CNT_WIDTH = 4   ,
				  OUT_PKT_WIDTH = 160 


)( input logic clk, reset);


	  logic   [DATA_WIDTH    - 1 : 0] data_in  ;
	  logic   			    		  dataK    ;

	  logic   [PKT_CNT_WIDTH - 1 : 0] PKT_count;
	  logic   [OUT_PKT_WIDTH - 1 : 0] PKT      ;
	  logic                           MRd	   ;
	  logic 						  MWr	   ;
	  logic							  IORd	   ;
	  logic							  IOWr	   ;
	  logic							  CfgRd0   ;
	  logic							  CfgWr0   ;
	  logic							  CfgRd1   ;
	  logic							  CfgWr1   ;
	  logic							  Cpl	   ;
	  logic							  Cp1D     ;

endinterface // PKT_IF



