 (* TODO_1:  in this block wehen i get an error, the error cannot be reseted, even if i pressed the AckError in the main block of Ethercat, what should be done ?*)

FUNCTION_BLOCK FB_MC_MoveAbsolute
 
	VAR_INPUT
	    Execute  : BOOL;
	    Position : DINT; 
	    Velocity : DINT;
	END_VAR
	
	VAR_OUTPUT
	    Busy   : BOOL;
	    Active : BOOL;
	    Done   : BOOL;
	    Error  : BOOL;
	    ErrorID : DINT;
	END_VAR
	
	VAR_IN_OUT
	    Axis : AXIS_REF_BACHMANN;
	END_VAR
	
	VAR
	    ExecuteOld  : BOOL;
	    ExecuteEdge : BOOL;
	END_VAR

(* ===================================== Code ======================================================*)

	ExecuteEdge := Execute AND NOT ExecuteOld; (* Rising Edge *)
	ExecuteOld  := Execute;
	
	
	(*===== Default Error Status ==== *)
		(*		Error	:=  Axis.Error; *)
		(*		ErrorID :=  Axis.ErrorID; *)

		Error   := Axis.AxisManagerToPlc.Error;
		ErrorID := Axis.AxisManagerToPlc.ErrorID;

	IF Axis.AxisManagerToPlc.Error THEN (* Error *)
		 Busy 		:= FALSE;
		 Active 	:= FALSE;
		 Done 		:= FALSE;
	END_IF;
	
	IF ExecuteEdge THEN (* Start Positioning *)
	
		Axis.PlcToAxisManager.Command 	:= CMD_MOVE_ABSOLUTE;
		Axis.PlcToAxisManager.MotionMode := 1;

 		Axis.PlcToAxisManager.Position        := Position;
    	Axis.PlcToAxisManager.ProfileVelocity := Velocity;

   		Axis.TargetPosition  := Position;       (* Temporary *)
    	Axis.ProfileVelocity := Velocity;       (* Temporary *)
    
	    Axis.MoveAbsolute := TRUE;
	    Busy   := TRUE;
	    Active := TRUE;
	    Done   := FALSE; 
	END_IF;
	
	(* User released Execute signal. Abort the positioning command and clear the active motion state. *)
	(* Stop positioning when Execute is released. Required because the underlying CiA402 state machine exits the motion state when ExecuteMode = FALSE. *)
	
	IF NOT Execute THEN
	 		
	 		 IF Axis.PlcToAxisManager.Command = CMD_MOVE_ABSOLUTE THEN
        		Axis.PlcToAxisManager.Command := CMD_NONE;
        		Axis.PlcToAxisManager.TargetVelocity := 0;
    		END_IF;
		
			Axis.MoveAbsolute 	:= FALSE; 
			Done 				:= FALSE;
	    	Busy 				:= FALSE;
	    	Active 				:= FALSE;
	    	
	END_IF;
	
	IF Busy AND Axis.AxisManagerToPlc.TargetReached THEN (* Motion Finished *)
	    Busy 				:= FALSE;
	    Active 				:= FALSE;
	    Done 				:= TRUE;
	    Axis.MoveAbsolute 	:= FALSE;
	END_IF;
		
;
END_FUNCTION_BLOCK