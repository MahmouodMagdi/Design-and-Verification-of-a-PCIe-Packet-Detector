//////////////////////////////////////////////////////////////////////////////////////
//
//	**********  PCIe Packet Detector VERIFICATION ENVIORNMENT  **********
//
//	AUTHOR		: MAHMOUD MAGDI
//	
//	Module Name : Classes Package 
//
//	Description	: A SystemVerilog Package that contains all the  
//				  Environment Components used in the Environment 
//				  
//////////////////////////////////////////////////////////////////////////////////////


package pkg;


	//////////////////////////////////////////////////////////////
	////////////////       Transaction Class       ///////////////
	//////////////////////////////////////////////////////////////
	class transaction #(

	  parameter   DATA_WIDTH    = 8   ,
	  parameter   PKT_CNT_WIDTH = 4   ,
	  parameter   OUT_PKT_WIDTH = 160 

	);



	  rand bit   [DATA_WIDTH    - 1 : 0] data_in[];
	  rand bit  			   			   dataK[];

		   bit   [PKT_CNT_WIDTH - 1 : 0] PKT_count;
		   bit   [OUT_PKT_WIDTH - 1 : 0] PKT      ;
		   bit                           MRd  	  ;
		   bit 			       		     MWr	  ;
		   bit						     IORd	  ;
		   bit						     IOWr	  ;
		   bit						     CfgRd0   ;
		   bit						     CfgWr0   ;
		   bit						     CfgRd1   ;
		   bit						     CfgWr1   ;
		   bit						     Cpl	  ;
		   bit						     Cp1D     ;




	  constraint data_inSize {data_in.size == 20 ;};
	  constraint dataK_Size {dataK.size == data_in.size ;};
	  constraint data_in_C {

		foreach(data_in[i]) if(i == 0) data_in[i] dist{8'hFB := 43, 8'hed := 5, 8'hac := 3, 8'hda := 2, 8'hbe := 4}; else if(i == 19) data_in[i] dist{8'hFD := 39, 8'hca := 2, 8'h45 := 4, 8'h87 := 3, 8'h36 := 1}; else if (i == 3) data_in[i] dist {8'h00 := 10, 8'h01 := 7, 8'h02 := 6, 8'h04 := 4, 8'h05 := 9, 8'h42 := 8, 8'h44 := 6, 8'h45 := 7, 8'h0a := 5, 8'h4a := 8, [8'haa: 8'hff] := 1}; else data_in[i] inside {[8'h00:8'hff]}; 

	  };

	  constraint dataK_cons {

		foreach(dataK[j]) if( ((j == 0) && (data_in[j] == 8'hFB)) || ((j == 19) && (data_in[j] == 8'hFD))) dataK[j] == 1'b1; else dataK[j] == 1'b0;


	  };

	  function new ();

	  endfunction


	endclass //Transaction



//	*****************************************************************************************************************




	//////////////////////////////////////////////////////////////
	////////////////        Sequencer Class        ///////////////
	//////////////////////////////////////////////////////////////
	class Sequencer;

	  rand transaction #(8,4,160)trn;


	  // Creating a Mailbox is used to send the randomized transaction to Driver
	  mailbox mbox;

	  // Adding a variable to control the number of random packets to be created
	  int repeat_count;


	  //  Adding an event to indicate the completion of the generation process, 
	  //  the event will be triggered on the completion of the Generation process.
	  event completed;


	  // Constructor
	  function new(mailbox mbox, event completed);			

		// getting the mailbox handle from env
		this.mbox   = mbox;
		this.completed = completed;

	  endfunction //new()


	  // Main task that creates and randomize the stimulus and puts into the mailbox
	  task stimulus ();

		repeat(repeat_count)
		  begin

			for(int i = 0; i < 20; i++)
			  begin
				trn = new();
				if (!trn.randomize ()) $fatal("Gen::trans randomization field");
				mbox.put(trn);

				#5;
			  end
		  end
		-> completed;
	  endtask 

	endclass //Sequencer



//	*****************************************************************************************************************



	//////////////////////////////////////////////////////////////
	////////////////         Driver Class          ///////////////
	//////////////////////////////////////////////////////////////
	class driver;


	  // Transcations Counter 
	  int trans_count;


	  // Creating virtual interface handle 
	  virtual PKT_IF pkt_vif;


	  // Creating Mailbox handle
	  mailbox mbox;



	  // Constructor 
	  function new(virtual PKT_IF pkt_vif, mailbox mbox);

		// Geting the interface 
		this.pkt_vif = pkt_vif;

		// Getting the mailbox handle from  environment 
		this.mbox = mbox;

	  endfunction //new()

	  // Adding a reset task, which initializes the Interface signals to default values
	  task reset();

		wait(!pkt_vif.reset);

		$display("Time = %0t --------- Drivier Reset Task Started --------- \n", $time);
		pkt_vif.data_in  <= 'b0;
		pkt_vif.dataK    <= 'b0;

		wait(pkt_vif.reset);
		$display("Time = %0t --------- Drivier Reset Task Ended   --------- \n", $time);

	  endtask



	  // Driving the transaction items to the Packet interface 
	  task drive();

		$display("Time = %0t	-------- Driver Task Started  --------	\n", $time);
		forever
		  begin

			transaction#(8,4,160)trans;
			mbox.get(trans);
			
			for(int i = 0; i < 20; i++)
			  begin
				@(negedge pkt_vif.clk)
				pkt_vif.data_in <= trans.data_in[i];
				pkt_vif.dataK   <= trans.dataK[i];

			  end
			trans_count++;
		  end

	  endtask

	endclass //driver



//	*****************************************************************************************************************



	//////////////////////////////////////////////////////////////
	////////////////         Monitor Class         ///////////////
	//////////////////////////////////////////////////////////////

	class Monitor;


	  // Creating Packet virtual interface handle 
	  virtual PKT_IF pkt_vif;


	  // Mailbox from monitor into the subscriber
	  mailbox mon_to_scb;
	  mailbox mon_to_sub;

	  // Constructor
	  function new(virtual PKT_IF pkt_vif, mailbox mon_to_scb, mailbox mon_to_sub);

		// Getting the Packet Interface
		this.pkt_vif = pkt_vif;

		// Getting the mailbox handles from the Environment Class
		this.mon_to_scb = mon_to_scb;
		this.mon_to_sub = mon_to_sub;

	  endfunction


	  // Sampling logic and sending the sampled transaction to the scoreboard and Subscriber
	  task mont_task;

		$display("Time = %0t --------- MONITOR TASK STARTED --------- \n", $time);

		forever
		  begin

			transaction#(8,4,160)trans;
			trans = new();
			trans.data_in = new[20];
			trans.dataK = new[20];
		   
			wait((pkt_vif.dataK) && (pkt_vif.data_in == 8'hFB));
			for(int i = 0; i < 20; i++)
			  begin
				@(posedge pkt_vif.clk)
				begin

				  trans.data_in[i] = pkt_vif.data_in    ;
				  trans.dataK[i]   = pkt_vif.dataK      ;
				  trans.PKT_count  = pkt_vif.PKT_count  ;   
				  trans.PKT        = pkt_vif.PKT        ;   
				  trans.MRd		   = pkt_vif.MRd		;   	
				  trans.MWr		   = pkt_vif.MWr		;   	
				  trans.IORd	   = pkt_vif.IORd	    ; 	 
				  trans.IOWr	   = pkt_vif.IOWr	    ; 	 
				  trans.CfgRd0     = pkt_vif.CfgRd0     ;   
				  trans.CfgWr0     = pkt_vif.CfgWr0     ;   
				  trans.CfgRd1     = pkt_vif.CfgRd1     ;   
				  trans.CfgWr1     = pkt_vif.CfgWr1     ;   
				  trans.Cpl		   = pkt_vif.Cpl		;   	
				  trans.Cp1D       = pkt_vif.Cp1D       ;

				end

			  end
			mon_to_scb.put(trans);
			mon_to_sub.put(trans);

		  end


	  endtask

	endclass // Monitor 



//	*****************************************************************************************************************



	//////////////////////////////////////////////////////////////
	////////////////       Scoreboard Class        ///////////////
	//////////////////////////////////////////////////////////////
	class Scoreboard;

	  static real GOOD_PACKET;
	  static real BAD_PACKET;



	  // Mailbox handle
	  mailbox mon_to_scb;


	  // An integer to count the number of transactions
	  int trans_count;


	  // Creating an array that will be used as a PKT memory
	  bit [7:0] PKT_mem[20];
	  bit [159:0] pkt;

	  function new(mailbox mon_to_scb);

		// Getting the mailbox handles from environment class
		this.mon_to_scb = mon_to_scb;

	  endfunction


	  string packet_type;

	  // Forming a 160-bit packets in the reference model and compare the PKT out signal with stored data
	  task scb_task;

		$display("-------------- Subscriber Task Started ----------- \n");
		forever
		  begin

			transaction#(8,4,160)trans;
			trans = new();
			mon_to_scb.get(trans);

			if(trans.dataK[0] && trans.dataK[19]);
			begin


			  if(pkt == trans.PKT)
				begin
				  GOOD_PACKET++;
				  case(trans.PKT[31:24])
					8'h00: packet_type = "MRd";
					8'h01: packet_type = "MWr";
					8'h02: packet_type = "IORd"; 
					8'h42: packet_type = "IOWr";
					8'h04: packet_type = "CfgRd0";
					8'h44: packet_type = "CfgWr0"; 
					8'h05: packet_type = "CfgRd1";
					8'h45: packet_type = "CfgWr1";
					8'h0a: packet_type = "Cpl";
					8'h4a: packet_type = "Cp1D";
					default: packet_type = " type is out of table";
				  endcase
				  $display("\n ----------------------------------------------------------- \n");
				  $display("   ************************   Good PACKET TEST PASSED !   ************************   \n\nRefernce Model PACEKT = %0h\nOUTPUT PACKET         = %0h\n\n1st Byte of Header    = 8'h%0h\nPACKET TYPE           = %0s\n\nPACKET Count          = %0d\n", pkt, trans.PKT,pkt[31:24], packet_type, trans.PKT_count);
				  $display("\n ----------------------------------------------------------- \n");
				end
			  else
				begin
				  BAD_PACKET++;
				  $display("\n ----------------------------------------------------------- \n");
				  $display("Bad Packet TEST Passed ! \n\nBAD PACEKT = %0h\n",pkt);
				  $display("\n ----------------------------------------------------------- \n");

				end
			  for(int i = 0; i<20; i++)
				begin
				  PKT_mem[i] = trans.data_in[i];
				  pkt = {PKT_mem[i], pkt[159:8]};
				end


			end
			$display("\n ----------------------------------------------------------- \n");
			$display("NUMBER of Total Packets = %0d \n",(GOOD_PACKET+BAD_PACKET));
			$display("Number of Good Packets  = %0d \n",GOOD_PACKET);
			$display("Number of Bad Packets   = %0d \n",BAD_PACKET);
			$display("Good Packets Percent    = %0f",(((GOOD_PACKET/(GOOD_PACKET+BAD_PACKET))*100)));
			$display("Bad Packets Percent     = %0f\n",(((BAD_PACKET/(GOOD_PACKET+BAD_PACKET))*100)));
			$display("\n ----------------------------------------------------------- \n");
		   
		  end

	  endtask // Scoreboard

	endclass

//	*****************************************************************************************************************



	//////////////////////////////////////////////////////////////
	////////////////       Subscriber Class        ///////////////
	//////////////////////////////////////////////////////////////
	class subscriber;

	  transaction#(8,4,160)trans;
	  mailbox mon_to_sub;

	  covergroup cg_out;

		STP_cp: coverpoint trans.PKT[7:0]{		

		  bins STP = {8'hFB};


		}

		END_cp: coverpoint trans.PKT[159:152]{		

		  bins END = {8'hFD};


		}	


		type_cp: coverpoint trans.PKT[31:24]{

		  bins	MRd		= {8'h00};
		  bins  MWr		= {8'h01};
		  bins  IORd	= {8'h02};
		  bins  IOWr	= {8'h42};
		  bins  CfgRd0  = {8'h04};
		  bins  CfgWr0  = {8'h44};
		  bins  CfgRd1  = {8'h05};
		  bins  CfgWr1  = {8'h45};
		  bins  Cpl		= {8'h0a};
		  bins  Cp1D    = {8'h4a};

		}


		packet_cp: coverpoint trans.PKT{


		  bins reset = {160'b0};

		}


		counter_cp: coverpoint trans.PKT_count;

		cross counter_cp,STP_cp, END_cp;


	  endgroup



	  function new(mailbox mon_to_sub);

		this.mon_to_sub = mon_to_sub;
		cg_out = new();
		trans = new();

	  endfunction

	  task coverage;

		forever	
		  begin
		  
			mon_to_sub.get(trans);
			cg_out.sample;
			$display("\n ----------------------------------------------------------- \n");
			$display("\nTime[%0t] ******** 	COVERAGE = %f 	********\n", $time, cg_out.get_coverage());
			$display("\n ----------------------------------------------------------- \n");
		  end	

	  endtask


	endclass // Subscriber



//	*****************************************************************************************************************



//////////////////////////////////////////////////////////////
////////////////       Environment Class       ///////////////
//////////////////////////////////////////////////////////////
class environment;


  // Sequencer, Driver, Monitor, Subscriber, and Scoreboard Instances
  Sequencer  Seq ;
  driver 	 drv ;
  Monitor    mont;
  Scoreboard scb ;
  subscriber sub ;



  // Virtual interface
  virtual PKT_IF pkt_vif;

  // Mailbox handle
  mailbox mbox;
  mailbox mon_to_scb;
  mailbox mon_to_sub;

  // Synchronize between the Drvier and the Sequencer through an Event
  event sync;


  function new(virtual PKT_IF pkt_vif );

    // Get the interface from the test
    this.pkt_vif = pkt_vif;

    // Creating a mailbox handle, it will be shared across the Sequencer and Driver
    mbox = new();
    mon_to_scb = new();
    mon_to_sub = new();

    // Creating the Sequencer, Driver, Monitor, and Scoreboard
    Seq  = new(mbox, sync);
    drv  = new(pkt_vif, mbox);
    mont = new(pkt_vif, mon_to_scb, mon_to_sub);
    scb  = new(mon_to_scb);
    sub  = new(mon_to_sub);

  endfunction

	/*

		For better accessibility: I will divide the test operation on 3 tasks

		1. pre-test  task --> Method to call the initialization reset task
		2. test      task --> Method to generate the stimulus and drive it to the memory interface
		3. post-test task --> Method to wait for the compeletion of the Sequencer and Driver operations

	*/

  task pre_test();

    drv.reset();

  endtask


  task test;

    fork

      Seq.stimulus()  ;
      drv.drive()	  ;
      mont.mont_task();
      scb.scb_task()  ;
      sub.coverage()  ;

    join_any

  endtask


  task post_test;

    wait(sync.triggered);
    wait(Seq.repeat_count == drv.trans_count);
    $display("\n\ntrans_count = %0d, repeat_count = %0d\n\n",drv.trans_count, Seq.repeat_count);


  endtask


  // Test Run Task
  task run();

    pre_test();
    test();
    post_test();

    $finish;

  endtask

endclass // Environment


endpackage // pkg
