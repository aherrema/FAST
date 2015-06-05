!  FAST_Library.f90 
!
!  FUNCTIONS/SUBROUTINES exported from FAST_Library.dll:
!  FAST_Start  - subroutine 
!  FAST_Update - subroutine 
!  FAST_End    - subroutine 
!   
! DO NOT REMOVE or MODIFY LINES starting with "!DEC$" or "!GCC$"
! !DEC$ specifies attributes for IVF and !GCC$ specifies attributes for gfortran
!
!==================================================================================================================================  
MODULE FAST_Data

   USE, INTRINSIC :: ISO_C_Binding
   USE FAST_Subs   ! all of the ModuleName and ModuleName_types modules are inherited from FAST_Subs
                       
   IMPLICIT  NONE
   SAVE
   
      ! Local parameters:
   REAL(DbKi),     PARAMETER             :: t_initial = 0.0_DbKi                    ! Initial time

   INTEGER,        PARAMETER             :: IntfStrLen  = 1025                      ! length of strings through the C interface
   INTEGER(IntKi), PARAMETER             :: MAXOUTPUTS = 1000                       ! Maximum number of outputs
   INTEGER(IntKi), PARAMETER             :: MAXInitINPUTS = 10                      ! Maximum number of initialization values from Simulink
   INTEGER(IntKi), PARAMETER             :: NumFixedInputs = 8
   
   
      ! Global (static) data:
   TYPE(FAST_TurbineType)                :: Turbine                                 ! Data for each turbine
   INTEGER(IntKi)                        :: n_t_global                              ! simulation time step, loop counter for global (FAST) simulation
   INTEGER(IntKi)                        :: ErrStat                                 ! Error status
   CHARACTER(IntfStrLen-1)               :: ErrMsg                                  ! Error message
   
   
END MODULE FAST_Data
!==================================================================================================================================
subroutine FAST_Sizes(TMax, InitInpAry, InputFileName_c, AbortErrLev_c, NumOuts_c, dt_c, ErrStat_c, ErrMsg_c, ChannelNames_c) BIND (C, NAME='FAST_Sizes')
!DEC$ ATTRIBUTES DLLEXPORT::FAST_Sizes
   USE FAST_Data
   IMPLICIT NONE 
!GCC$ ATTRIBUTES DLLEXPORT :: FAST_Sizes
   REAL(C_DOUBLE),         INTENT(IN   ) :: TMax      
   REAL(C_DOUBLE),         INTENT(IN   ) :: InitInpAry(MAXInitINPUTS)      
   CHARACTER(KIND=C_CHAR), INTENT(IN   ) :: InputFileName_c(IntfStrLen)      
   INTEGER(C_INT),         INTENT(  OUT) :: AbortErrLev_c      
   INTEGER(C_INT),         INTENT(  OUT) :: NumOuts_c      
   REAL(C_DOUBLE),         INTENT(  OUT) :: dt_c      
   INTEGER(C_INT),         INTENT(  OUT) :: ErrStat_c      
   CHARACTER(KIND=C_CHAR), INTENT(  OUT) :: ErrMsg_c(IntfStrLen) 
   CHARACTER(KIND=C_CHAR), INTENT(  OUT) :: ChannelNames_c(ChanLen*MAXOUTPUTS+1)
   
   ! local
   CHARACTER(IntfStrLen)               :: InputFileName   
   INTEGER                             :: i, j, k
   TYPE(FAST_ExternInitType)           :: ExternInitData
   
      ! transfer the character array from C to a Fortran string:   
   InputFileName = TRANSFER( InputFileName_c, InputFileName )
   I = INDEX(InputFileName,C_NULL_CHAR) - 1            ! if this has a c null character at the end...
   IF ( I > 0 ) InputFileName = InputFileName(1:I)     ! remove it
   
      ! initialize variables:   
   n_t_global = 0
   
   ExternInitData%TMax       = TMax
   ExternInitData%SensorType = NINT(InitInpAry(1))   
   
   IF ( NINT(InitInpAry(2)) == 1 ) THEN
      ExternInitData%LidRadialVel = .true.
   ELSE
      ExternInitData%LidRadialVel = .false.
   END IF
   
   
   
   CALL FAST_InitializeAll_T( t_initial, 1_IntKi, Turbine, ErrStat, ErrMsg, InputFileName, ExternInitData )
                  
   AbortErrLev_c = AbortErrLev   
   NumOuts_c     = min(MAXOUTPUTS, 1 + SUM( Turbine%y_FAST%numOuts )) ! includes time
   dt_c          = Turbine%p_FAST%dt

   ErrStat_c     = ErrStat
   ErrMsg_c      = TRANSFER( TRIM(ErrMsg)//C_NULL_CHAR, ErrMsg_c )
   
#ifdef CONSOLE_FILE   
   if (ErrStat /= ErrID_None) call wrscr1(trim(ErrMsg))
#endif   
    
      ! return the names of the output channels
   IF ( ALLOCATED( Turbine%y_FAST%ChannelNames ) )  then
      k = 1;
      DO i=1,NumOuts_c
         DO j=1,ChanLen
            ChannelNames_c(k)=Turbine%y_FAST%ChannelNames(i)(j:j)
            k = k+1
         END DO
      END DO
      ChannelNames_c(k) = C_NULL_CHAR
   ELSE
      ChannelNames_c = C_NULL_CHAR
   END IF
   
   
end subroutine FAST_Sizes
!==================================================================================================================================
subroutine FAST_Start(NumInputs_c, NumOutputs_c, InputAry, OutputAry, ErrStat_c, ErrMsg_c) BIND (C, NAME='FAST_Start')
!DEC$ ATTRIBUTES DLLEXPORT::FAST_Start
   USE FAST_Data
   IMPLICIT NONE 
!GCC$ ATTRIBUTES DLLEXPORT :: FAST_Start
   INTEGER(C_INT),         INTENT(IN   ) :: NumInputs_c      
   INTEGER(C_INT),         INTENT(IN   ) :: NumOutputs_c      
   REAL(C_DOUBLE),         INTENT(IN   ) :: InputAry(NumInputs_c)
   REAL(C_DOUBLE),         INTENT(  OUT) :: OutputAry(NumOutputs_c)
   INTEGER(C_INT),         INTENT(  OUT) :: ErrStat_c      
   CHARACTER(KIND=C_CHAR), INTENT(  OUT) :: ErrMsg_c(IntfStrLen)      

   
   ! local
   CHARACTER(IntfStrLen)                 :: InputFileName   
   INTEGER                               :: i
   REAL(ReKi)                            :: Outputs(NumOutputs_c-1)
     
      ! initialize variables:   
   n_t_global = 0

#ifdef SIMULINK_DirectFeedThrough   
   IF(  NumInputs_c /= NumFixedInputs .AND. NumInputs_c /= NumFixedInputs+3 ) THEN
      ErrStat_c = ErrID_Fatal
      ErrMsg_c  = TRANSFER( "FAST_Start:size of InputAry is invalid."//C_NULL_CHAR, ErrMsg_c )
      RETURN
   END IF

   CALL FAST_SetExternalInputs(NumInputs_c, InputAry, Turbine%m_FAST)

#endif      
   !...............................................................................................................................
   ! Initialization of solver: (calculate outputs based on states at t=t_initial as well as guesses of inputs and constraint states)
   !...............................................................................................................................  
   CALL FAST_Solution0_T(Turbine, ErrStat, ErrMsg )      
   
      ! return outputs here, too
   IF(NumOutputs_c /= SIZE(Turbine%y_FAST%ChannelNames) ) THEN
      ErrStat = ErrID_Fatal
      ErrMsg  = trim(ErrMsg)//NewLine//"FAST_Start:size of NumOutputs is invalid."
      RETURN
   ELSE
      
      CALL FillOutputAry_T(Turbine, Outputs)   
      OutputAry(1)              = Turbine%m_FAST%t_global 
      OutputAry(2:NumOutputs_c) = Outputs 
      
   END IF
   
   ErrStat_c     = ErrStat
   ErrMsg_c      = TRANSFER( TRIM(ErrMsg)//C_NULL_CHAR, ErrMsg_c )
   
#ifdef CONSOLE_FILE   
   if (ErrStat /= ErrID_None) call wrscr1(trim(ErrMsg))
#endif   
      
end subroutine FAST_Start
!==================================================================================================================================
subroutine FAST_Update(NumInputs_c, NumOutputs_c, InputAry, OutputAry, ErrStat_c, ErrMsg_c) BIND (C, NAME='FAST_Update')
!DEC$ ATTRIBUTES DLLEXPORT::FAST_Update
   USE FAST_Data
   IMPLICIT NONE
!GCC$ ATTRIBUTES DLLEXPORT :: FAST_Update
   INTEGER(C_INT),         INTENT(IN   ) :: NumInputs_c      
   INTEGER(C_INT),         INTENT(IN   ) :: NumOutputs_c      
   REAL(C_DOUBLE),         INTENT(IN   ) :: InputAry(NumInputs_c)
   REAL(C_DOUBLE),         INTENT(  OUT) :: OutputAry(NumOutputs_c)
   INTEGER(C_INT),         INTENT(  OUT) :: ErrStat_c      
   CHARACTER(KIND=C_CHAR), INTENT(  OUT) :: ErrMsg_c(IntfStrLen)      
   
      ! local variables
   REAL(ReKi)                            :: Outputs(NumOutputs_c-1)
   INTEGER(IntKi)                        :: i
                 
   
   IF ( n_t_global > Turbine%p_FAST%n_TMax_m1 ) THEN !finish 
      
      ! we can't continue because we might over-step some arrays that are allocated to the size of the simulation

      IF (n_t_global == Turbine%p_FAST%n_TMax_m1 + 1) THEN  ! we call update an extra time in Simulink, which we can ignore until the time shift with outputs is solved
         n_t_global = n_t_global + 1
         ErrStat_c = ErrID_None
         ErrMsg_c = TRANSFER( C_NULL_CHAR, ErrMsg_c )
      ELSE     
         ErrStat_c = ErrID_Info
         ErrMsg_c  = TRANSFER( "Simulation completed."//C_NULL_CHAR, ErrMsg_c )
      END IF
      
   ELSEIF(NumOutputs_c /= SIZE(Turbine%y_FAST%ChannelNames) ) THEN
      ErrStat_c = ErrID_Fatal
      ErrMsg_c  = TRANSFER( "FAST_Update:size of OutputAry is invalid or FAST has too many outputs."//C_NULL_CHAR, ErrMsg_c )
      RETURN
   ELSEIF(  NumInputs_c /= NumFixedInputs .AND. NumInputs_c /= NumFixedInputs+3 ) THEN
      ErrStat_c = ErrID_Fatal
      ErrMsg_c  = TRANSFER( "FAST_Update:size of InputAry is invalid."//C_NULL_CHAR, ErrMsg_c )
      RETURN
   ELSE

      CALL FAST_SetExternalInputs(NumInputs_c, InputAry, Turbine%m_FAST)

      CALL FAST_Solution_T( t_initial, n_t_global, Turbine, ErrStat, ErrMsg )                  
      n_t_global = n_t_global + 1

      
      ! set the outputs for external code here...
      ! return y_FAST%ChannelNames
      
      ErrStat_c = ErrStat
      ErrMsg_c  = TRANSFER( TRIM(ErrMsg)//C_NULL_CHAR, ErrMsg_c )
   END IF
   
   CALL FillOutputAry_T(Turbine, Outputs)   
   OutputAry(1)              = Turbine%m_FAST%t_global 
   OutputAry(2:NumOutputs_c) = Outputs 

#ifdef CONSOLE_FILE   
   if (ErrStat /= ErrID_None) call wrscr1(trim(ErrMsg))
#endif   
      
end subroutine FAST_Update 
!==================================================================================================================================
subroutine FAST_SetExternalInputs(NumInputs_c, InputAry, m_FAST)

   USE, INTRINSIC :: ISO_C_Binding
   USE FAST_Types
   USE FAST_Data, only: NumFixedInputs
   
   IMPLICIT  NONE

   INTEGER(C_INT),         INTENT(IN   ) :: NumInputs_c      
   REAL(C_DOUBLE),         INTENT(IN   ) :: InputAry(NumInputs_c)                   ! Inputs from Simulink
   TYPE(FAST_MiscVarType), INTENT(INOUT) :: m_FAST                                  ! Miscellaneous variables
   
         ! set the inputs from external code here...
         ! transfer inputs from Simulink to FAST
      IF ( NumInputs_c < NumFixedInputs ) RETURN ! This is an error
      
      m_FAST%ExternInput%GenTrq      = InputAry(1)
      m_FAST%ExternInput%ElecPwr     = InputAry(2)
      m_FAST%ExternInput%YawPosCom   = InputAry(3)
      m_FAST%ExternInput%YawRateCom  = InputAry(4)
      m_FAST%ExternInput%BlPitchCom  = InputAry(5:7)
      m_FAST%ExternInput%HSSBrFrac   = InputAry(8)         
            
      IF ( NumInputs_c > NumFixedInputs ) THEN  ! NumFixedInputs is the fixed number of inputs
         IF ( NumInputs_c == NumFixedInputs + 3 ) &
             m_FAST%ExternInput%LidarFocus = InputAry(9:11)
      END IF   
      
end subroutine FAST_SetExternalInputs
!==================================================================================================================================
subroutine FAST_End() BIND (C, NAME='FAST_End')
!DEC$ ATTRIBUTES DLLEXPORT::FAST_End
   USE FAST_Data
   IMPLICIT NONE
!GCC$ ATTRIBUTES DLLEXPORT :: FAST_End

   CALL ExitThisProgram_T( Turbine, ErrID_None )
   
end subroutine FAST_End
!==================================================================================================================================
subroutine FAST_CreateCheckpoint(CheckpointRootName_c, ErrStat_c, ErrMsg_c) BIND (C, NAME='FAST_CreateCheckpoint')
!DEC$ ATTRIBUTES DLLEXPORT::FAST_CreateCheckpoint
   USE FAST_Data
   IMPLICIT NONE
!GCC$ ATTRIBUTES DLLEXPORT :: FAST_CreateCheckpoint
   CHARACTER(KIND=C_CHAR), INTENT(IN   ) :: CheckpointRootName_c(IntfStrLen)      
   INTEGER(C_INT),         INTENT(  OUT) :: ErrStat_c      
   CHARACTER(KIND=C_CHAR), INTENT(  OUT) :: ErrMsg_c(IntfStrLen)      
   
   ! local
   CHARACTER(IntfStrLen)                 :: CheckpointRootName   
   INTEGER(IntKi)                        :: I
   INTEGER(IntKi)                        :: Unit
             
   
      ! transfer the character array from C to a Fortran string:   
   CheckpointRootName = TRANSFER( CheckpointRootName_c, CheckpointRootName )
   I = INDEX(CheckpointRootName,C_NULL_CHAR) - 1                 ! if this has a c null character at the end...
   IF ( I > 0 ) CheckpointRootName = CheckpointRootName(1:I)     ! remove it
   
   Unit = -1
   CALL FAST_CreateCheckpoint_T(t_initial, n_t_global, 1, Turbine, CheckpointRootName, ErrStat, ErrMsg, Unit )

      ! transfer Fortran variables to C:      
   ErrStat_c = ErrStat
   ErrMsg_c  = TRANSFER( TRIM(ErrMsg)//C_NULL_CHAR, ErrMsg_c )


#ifdef CONSOLE_FILE   
   if (ErrStat /= ErrID_None) call wrscr1(trim(ErrMsg))
#endif   
      
end subroutine FAST_CreateCheckpoint 
!==================================================================================================================================
subroutine FAST_Restart(CheckpointRootName_c, AbortErrLev_c, NumOuts_c, dt_c, ErrStat_c, ErrMsg_c) BIND (C, NAME='FAST_Restart')
!DEC$ ATTRIBUTES DLLEXPORT::FAST_Restart
   USE FAST_Data
   IMPLICIT NONE
!GCC$ ATTRIBUTES DLLEXPORT :: FAST_Restart
   CHARACTER(KIND=C_CHAR), INTENT(IN   ) :: CheckpointRootName_c(IntfStrLen)      
   INTEGER(C_INT),         INTENT(  OUT) :: AbortErrLev_c      
   INTEGER(C_INT),         INTENT(  OUT) :: NumOuts_c      
   REAL(C_DOUBLE),         INTENT(  OUT) :: dt_c      
   INTEGER(C_INT),         INTENT(  OUT) :: ErrStat_c      
   CHARACTER(KIND=C_CHAR), INTENT(  OUT) :: ErrMsg_c(IntfStrLen)      
   
   ! local
   CHARACTER(IntfStrLen)                 :: CheckpointRootName   
   INTEGER(IntKi)                        :: I
   INTEGER(IntKi)                        :: Unit
   REAL(DbKi)                            :: t_initial_out
   INTEGER(IntKi)                        :: NumTurbines_out
   CHARACTER(*),           PARAMETER     :: RoutineName = 'FAST_Restart' 
             
   
      ! transfer the character array from C to a Fortran string:   
   CheckpointRootName = TRANSFER( CheckpointRootName_c, CheckpointRootName )
   I = INDEX(CheckpointRootName,C_NULL_CHAR) - 1                 ! if this has a c null character at the end...
   IF ( I > 0 ) CheckpointRootName = CheckpointRootName(1:I)     ! remove it
   
   Unit = -1
   CALL FAST_RestoreFromCheckpoint_T(t_initial_out, n_t_global, NumTurbines_out, Turbine, CheckpointRootName, ErrStat, ErrMsg, Unit )
   
      ! check that these are valid:
      IF (t_initial_out /= t_initial) CALL SetErrStat(ErrID_Fatal, "invalid value of t_initial.", ErrStat, ErrMsg, RoutineName )
      IF (NumTurbines_out /= 1) CALL SetErrStat(ErrID_Fatal, "invalid value of NumTurbines.", ErrStat, ErrMsg, RoutineName )
   
   
      ! transfer Fortran variables to C:      
   AbortErrLev_c = AbortErrLev   
   NumOuts_c     = min(MAXOUTPUTS, 1 + SUM( Turbine%y_FAST%numOuts )) ! includes time
   dt_c          = Turbine%p_FAST%dt      
      
   ErrStat_c = ErrStat
   ErrMsg_c  = TRANSFER( TRIM(ErrMsg)//C_NULL_CHAR, ErrMsg_c )


#ifdef CONSOLE_FILE   
   if (ErrStat /= ErrID_None) call wrscr1(trim(ErrMsg))
#endif   
      
end subroutine FAST_Restart 
!==================================================================================================================================   


