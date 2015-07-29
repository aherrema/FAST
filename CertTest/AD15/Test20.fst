------- FAST v8.12.* INPUT FILE ------------------------------------------------
FAST Certification Test #20: NREL 5.0 MW Baseline Wind Turbine with OC3 Tripod Configuration, for use in offshore analysis
---------------------- SIMULATION CONTROL --------------------------------------
False         Echo            - Echo input data to <RootName>.ech (flag)
"FATAL"       AbortLevel      - Error level when simulation should abort (string) {"WARNING", "SEVERE", "FATAL"}
         60   TMax            - Total run time (s)
      0.008   DT              - Recommended module time step (s)
          2   InterpOrder     - Interpolation order for input/output time history (-) {1=linear, 2=quadratic}
          1   NumCrctn        - Number of correction iterations (-) {0=explicit calculation, i.e., no corrections}
    99999.9   DT_UJac         - Time between calls to get Jacobians (s)
      1E+06   UJacSclFact     - Scaling factor used in Jacobians (-)
---------------------- FEATURE SWITCHES AND FLAGS ------------------------------
          1   CompElast       - Compute structural dynamics (switch) {1=ElastoDyn; 2=ElastoDyn + BeamDyn for blades}
          1   CompInflow      - Compute inflow wind velocities (switch) {0=still air; 1=InflowWind}
2          1   CompAero        - Compute aerodynamic loads (switch) {0=None; 1=AeroDyn v14; 2=AeroDyn v15}
          1   CompServo       - Compute control and electrical-drive dynamics (switch) {0=None; 1=ServoDyn}
          1   CompHydro       - Compute hydrodynamic loads (switch) {0=None; 1=HydroDyn}
          1   CompSub         - Compute sub-structural dynamics (switch) {0=None; 1=SubDyn}
          0   CompMooring     - Compute mooring system (switch) {0=None; 1=MAP++; 2=FEAMooring; 3=MoorDyn}
          0   CompIce         - Compute ice loads (switch) {0=None; 1=IceFloe; 2=IceDyn}
False         CompUserPtfmLd  - Compute additional platform loading (flag) {false: none; true: user-defined from routine UserPtfmLd}
False         CompUserTwrLd   - Compute additional tower loading (flag) {false: none; true: user-defined from routine UserTwrLd}
---------------------- INPUT FILES ---------------------------------------------
"../5MW_Baseline/NRELOffshrBsline5MW_OC3Tripod_ElastoDyn.dat"    EDFile          - Name of file containing ElastoDyn input parameters (quoted string)
"../unused"      BDBldFile(1)    - Name of file containing BeamDyn input parameters for blade 1 (quoted string)
"../unused"      BDBldFile(2)    - Name of file containing BeamDyn input parameters for blade 2 (quoted string)
"../unused"      BDBldFile(3)    - Name of file containing BeamDyn input parameters for blade 3 (quoted string)
"../5MW_Baseline/NRELOffshrBsline5MW_InflowWind_Steady8mps.dat"    InflowFile      - Name of file containing inflow wind input parameters (quoted string)
"../5MW_Baseline/NRELOffshrBsline5MW_OC3Tripod_AeroDyn15.dat"    AeroFile        - Name of file containing aerodynamic input parameters (quoted string)
"../5MW_Baseline/NRELOffshrBsline5MW_OC3Tripod_ServoDyn.dat"    ServoFile       - Name of file containing control and electrical-drive input parameters (quoted string)
"../5MW_Baseline/NRELOffshrBsline5MW_OC3Tripod_HydroDyn.dat"    HydroFile       - Name of file containing hydrodynamic input parameters (quoted string)
"../5MW_Baseline/NRELOffshrBsline5MW_OC3Tripod_SubDyn.dat"    SubFile         - Name of file containing sub-structural input parameters (quoted string)
"../unused"      MooringFile     - Name of file containing mooring system input parameters (quoted string)
"../unused"      IceFile         - Name of file containing ice input parameters (quoted string)
---------------------- OUTPUT --------------------------------------------------
True          SumPrint        - Print summary data to "<RootName>.sum" (flag)
          1   SttsTime        - Amount of time between screen status messages (s)
       1000   ChkptTime       - Amount of time between creating checkpoint files for potential restart (s)
default       DT_Out          - Time step for tabular output (s)
          0   TStart          - Time to begin tabular output (s)
          2   OutFileFmt      - Format for tabular (time-marching) output file (switch) {1: text file [<RootName>.out], 2: binary file [<RootName>.outb], 3: both}
True          TabDelim        - Use tab delimiters in text tabular output file? (flag) {uses spaces if false}
"ES10.3E2"    OutFmt          - Format used for text tabular output, excluding the time channel.  Resulting field should be 10 characters. (quoted string)