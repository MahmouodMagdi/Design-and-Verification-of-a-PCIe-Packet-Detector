///////////////////////////////////////////////////////////////////////////
//
//	AUTHOR		: MAHMOUD MAGDI
//	
//	Module Name : Packet Detector FSM Module 
//
//	Description	: An FSM that detects the Good Packets, their count, and Type
//				   
///////////////////////////////////////////////////////////////////////////


module PKT_Detector #(

    parameter   DATA_WIDTH    = 8   ,
                PKT_CNT_WIDTH = 4   ,
                OUT_PKT_WIDTH = 160 
				
) (

    // Input Ports 
    	input   logic                           reset     ,                                                     // Active-Low Asynchornous reset
    	input   logic                           clk       ,                                                     
    	input   logic   [DATA_WIDTH - 1 : 0]    data_in   ,                                                     // Input data       
    	input   logic   			dataK     ,                                                     // Set to one whenever STP or END symbols are intended      
    
    // Output Ports 
   	output  logic   [PKT_CNT_WIDTH - 1 : 0] PKT_count ,                                                     // Number of good packets received 
    	output  logic   [OUT_PKT_WIDTH - 1 : 0] PKT       ,                                                     // 20-byte PKT concatenated together 
    	output  logic                           MRd	  , 
	output 	logic 				MWr	  , 
	output 	logic				IORd	  , 
	output	logic				IOWr	  , 
	output	logic				CfgRd0    , 
	output	logic				CfgWr0    , 
	output	logic				CfgRd1    , 
	output	logic				CfgWr1    , 
	output	logic				Cpl	  , 
	output	logic				Cp1D        
   
);

logic [DATA_WIDTH    - 1 : 0] data_counter ;
logic [OUT_PKT_WIDTH - 1 : 0] PKT_REG;


//////////////////////////////
//      Define states       //
//////////////////////////////
typedef enum logic {
    
    	IDLE    ,
	active
	
} state_t;




state_t current_state , next_state;

always_ff @( posedge clk or negedge reset ) begin : data_count
    if (!reset) 
    begin
        
        	data_counter <= 'b0;
		PKT_REG <= 'b0;
		
    end 
    else 
    begin

	if(next_state == IDLE)
	begin
        	data_counter <= 'b0;	
		PKT_REG <= PKT_REG;	
	end
	else
	begin

        	data_counter <= data_counter + 1;	
		PKT_REG <= {data_in, PKT_REG[159:8]};

	end
    
    end
end

//////////////////////////////////////////////////
/////          Current State Logic           /////                           
//////////////////////////////////////////////////
always_ff @(posedge clk or negedge reset) begin : current_State_Logic

    if(!reset)
    begin
        current_state <= IDLE;
    end
    else
    begin
        current_state <= next_state;
    end

end


//////////////////////////////////////////////////
/////             Next State Logic           /////                           
//////////////////////////////////////////////////
always_comb begin : Next_State_Logic 
   

    	case (current_state)
        
        IDLE   : begin

                    if((data_in == 'hFB) && (dataK == 1'b1))
                    begin
                        next_state = active;
                    end
                    else
                    begin
                        next_state = IDLE;
                    end

                end

        active: begin
		
			if(data_counter == 20)
			begin
				next_state = IDLE;
			end
			else
			begin
				next_state = active;
			end		
					
		end

        
	default: next_state = IDLE;
   
   endcase 

end



//////////////////////////////////////////////////
/////             Output Logic               /////                           
//////////////////////////////////////////////////
always_ff @(posedge clk or negedge reset) begin : Output

    if(!reset)
    begin
    
        PKT       <= 'b0;
        PKT_count <= 'b0;
        MRd       <= 'b0;
        MWr       <= 'b0;
        IORd      <= 'b0;     
        IOWr      <= 'b0; 
        CfgRd0    <= 'b0; 
        CfgWr0    <= 'b0; 
        CfgRd1    <= 'b0;   
        CfgWr1    <= 'b0; 
        Cpl       <= 'b0; 
        Cp1D      <= 'b0;
        
    end
    else
    begin

		if((data_counter == 20) && (PKT_REG[159:152] == 8'hFD))
		begin
		
			PKT <= PKT_REG;
			PKT_count <= PKT_count + 1;
			
			case(PKT_REG[31:24])
			
				8'h00: MRd    <= 1'b1;
				8'h01: MWr    <= 1'b1;
				8'h02: IORd   <= 1'b1; 
				8'h42: IOWr   <= 1'b1;
				8'h04: CfgRd0 <= 1'b1;
				8'h44: CfgWr0 <= 1'b1; 
				8'h05: CfgRd1 <= 1'b1;
				8'h45: CfgWr1 <= 1'b1;
				8'h0a: Cpl    <= 1'b1;
				8'h4a: Cp1D   <= 1'b1;
				
				default: begin

					MRd    <= 1'b0;
					MWr    <= 1'b0;
					IORd   <= 1'b0; 
					IOWr   <= 1'b0;
					CfgRd0 <= 1'b0;
					CfgWr0 <= 1'b0; 
					CfgRd1 <= 1'b0;
					CfgWr1 <= 1'b0;
					Cpl    <= 1'b0;
					Cp1D   <= 1'b0;

				end
			endcase
		end 
		else
		begin
		
			PKT 	  <= PKT;
			PKT_count <= PKT_count;
			IORd      <= 1'b0;
			MRd       <= 1'b0;
			MWr       <= 1'b0;
			IORd      <= 1'b0; 
			IOWr      <= 1'b0;
			CfgRd0    <= 1'b0;
			CfgWr0    <= 1'b0; 
			CfgRd1    <= 1'b0;
			CfgWr1    <= 1'b0;
			Cpl       <= 1'b0;
			Cp1D      <= 1'b0;
			
		end
	
    end
    
end
    
endmodule
