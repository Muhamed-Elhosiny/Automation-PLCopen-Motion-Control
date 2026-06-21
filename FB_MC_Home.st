FUNCTION_BLOCK FB_MC_Home

	VAR_INPUT
	  		  Execute : BOOL;
	END_VAR
	
	VAR_OUTPUT
			    Busy    : BOOL;
			    Done    : BOOL;
			     CommandAborted : BOOL;
			    Error   : BOOL;
			    ErrorID : DINT;
	END_VAR
	
	VAR_IN_OUT
	    		Axis : AXIS_REF_BACHMANN;
	END_VAR

	VAR
			    ExecuteOld  : BOOL;
			    ExecuteEdge : BOOL;
			    iState      : INT;
	END_VAR
	
	(*============================================ Execute rising edge detection ============================================== *)
	
	(*==== Default status ===== *)
	
	Error   	:= Axis.Error OR Axis.HomingError;
	ErrorID 	:= Axis.ErrorID;
	
	ExecuteEdge := Execute AND NOT ExecuteOld; (* Execute rising edge detection *)
	ExecuteOld 	:= Execute;
	
	Axis.Home 	:= FALSE; (* At the starting of each cycle by Default: Home command is only one-cycle pulse *) 
	
	(*	Busy 		:= Axis.HomingActive; *)
	
	
	(* TODO: check this state machine again to know, if it is in the best design*)
	
	CASE iState OF
	
	    0: (* Dormant / Ready *)
	        Busy    := FALSE;
	        Done    := FALSE;
			(*	        Error   := FALSE; *)
			(*	        ErrorID := 0; *)
	        Error := Axis.AxisManagerToPlc.Error;
			ErrorID := Axis.AxisManagerToPlc.ErrorID;
	
			(*IF ExecuteEdge AND NOT Axis.Error AND NOT Axis.HomingError THEN (*edge-triggered  not Level Controlled*) *)
	        
	         IF ExecuteEdge AND NOT Axis.AxisManagerToPlc.Error THEN
	         
	         	Axis.PlcToAxisManager.MotionMode := 6;
	          	Axis.PlcToAxisManager.Command := CMD_HOME; (*New *)
	          	
	            Axis.Home := TRUE;      (* one-cycle pulse to start homing *)
	            Busy      := TRUE;
	            iState    := 10;
	            
	        END_IF;
	
	
	    10: (* Executing *)
	    
	        Busy  := TRUE; (* The axis make homing now *)
	        Done  := FALSE;
	        Error := FALSE;
	       
	       
	       IF Axis.PlcToAxisManager.Stop THEN

			    IF Axis.PlcToAxisManager.Command = CMD_HOME THEN
			        Axis.PlcToAxisManager.Command := CMD_NONE;
			    END_IF;
			
			    Busy := FALSE;
			    Done := FALSE;
			    Error := FALSE;
			    CommandAborted := TRUE;
			    iState := 40;
			    
			END_IF;
	        
	       (* Homing ---->> aborted <<<---- by user releasing Execute or by MC_Stop *)
			IF NOT Execute THEN 
	        
			        IF Axis.PlcToAxisManager.Command = CMD_HOME THEN 
			        	Axis.PlcToAxisManager.Command := CMD_NONE; 
			        END_IF;
	        
			        Axis.Home := FALSE; 
			        Busy := FALSE; 
			        Done := FALSE; 
			        Error := FALSE; 
			        iState := 0;
	        
	        ELSIF Axis.Homed THEN
	            Busy   := FALSE;
	            Done   := TRUE;
	            iState := 20; (* Done *)

			(*ELSIF Axis.Error OR Axis.HomingError THEN *)
	        
	        ELSIF Axis.AxisManagerToPlc.Error THEN
	        
	            Busy    := FALSE;
	            Done    := FALSE;
	            Error   := TRUE;
	            ErrorID := Axis.AxisManagerToPlc.ErrorID;
	            iState  := 30;
	            
	        END_IF;
	
	
	    20: (* Done *) (* PLCopen ----->>> (Done ----> Done) if Execute = TRUE*)
	    
	        Busy  := FALSE;
	        Done  := TRUE; (* to let the user see FB_Home.Done and ((donot disappear immediately))*)
	        Error := FALSE;
	        (* PLCopen Behaviour: Done stays TRUE while Execute is TRUE -- Done --> Resetting*)
	 
			IF NOT Execute THEN
		
			    IF Axis.PlcToAxisManager.Command = CMD_HOME THEN
			        Axis.PlcToAxisManager.Command := CMD_NONE;
			    END_IF;
			
			    Done    := FALSE;
			    Busy 	:= FALSE;
			    iState  := 0;
		    END_IF;
			
	    30: (* Error *)
	    
	        Busy  := FALSE;
	        Done  := FALSE;
	        Error := TRUE; (* to let the user see FB_Home.Error*)
			ErrorID := Axis.AxisManagerToPlc.ErrorID;
	
	        (* Error stays TRUE until Execute becomes FALSE *)
	        IF NOT Execute THEN
				           	IF Axis.PlcToAxisManager.Command = CMD_HOME THEN
			        			Axis.PlcToAxisManager.Command := CMD_NONE;
			    			END_IF;
	    			
		            	Error   := FALSE;
		            	ErrorID := 0;
		            	iState  := 0;
		       		 END_IF;
		   40:
			
			    Busy := FALSE;
			    Done := FALSE;
			    Error := FALSE;
			
			    CommandAborted := TRUE;
			
			    IF NOT Execute THEN
			
			        CommandAborted := FALSE;
			
			        iState := 0;
			
			    END_IF;
		       		 
			ELSE (* Safety fallback *)
		
				 Busy    := FALSE;
				 Done    := FALSE;
				 Error   := TRUE;
				 ErrorID := -1;
				 Axis.Home 	:= FALSE;
				 iState 	:= 30;
				(* 40 = CommandAborted *)
				(* 50 = TimeOut *)
				(*60 = Resetting *)
			
			
	
			
			END_CASE;
;
END_FUNCTION_BLOCK