% This script compiles the FAST S-Function assuming that each of the listed 
%   files is in the specified directory.
%
% National Renewable Energy Laboratory's 
% National Wind Technology Center                             31 March 2010
%
% NOTE: We assume that the user of this script has some knowlege about 
% compiling Fortran and can access the Matlab documentation files for 
% assistance in using the mex function. Due to the large number of 
% possibilities of compilers, linkers, and Matlab versions, this list of 
% instructions is only a guide.
%
% Note that to make FortranOptionsFile, please do the following:
% (1) Copy intelf10msvs2005opts.bat or equivalent for your compiler/linker  
%     from folder "%MATLABROOT%\bin\win32\mexopts" (or equivalent 
%     directory; see mex documentation for details) into the folder where 
%     "make_FAST_SFunc.m" is stored. (Then, change the variable
%     "FortranOptionsFile" in the script below to be the name of this  file.)
% (2) Verify that the general parameters in the new batch file point to  
%     the correct paths for your compiler and linker. Modify if necessary.
%     (If you are using IVF, you should make sure that the paths in the
%     compiler's IFORTVARS.bat file are listed in your new .bat file.)
% (3) Change COMPFLAGS in this new .bat file: 
%     add these flags if they aren't there already:
%             /assume:byterecl /traceback /real_size:64 /Qzero /Qsave 
%     remove these flags if they exist:
%            /fpp /fixed
% (4) Check variables OPTIMFLAGS and DEBUGFLAGS in the .bat file:
%     remove /MD if it is there
%
%% ------------------------------------------------------------------------
% Set the name of the batch file containing the locations of the compiler 
% and linker, along with the correct compiler and linker flags for FAST.
%--------------------------------------------------------------------------
FortranOptionsFile = 'intelf10msvs2003opts.bat';
%
%'COMPFLAGS#"$COMPFLAGS /assume:byterecl /traceback /Qsave /Qzero /real_size:64"',

%--------------------------------------------------------------------------
% Set the name of the output function
%--------------------------------------------------------------------------
OutputRootName     = 'FAST_SFunc';                  % name of the mex file

%--------------------------------------------------------------------------
% Set the paths pointing to the Fortran source code for
% NWTC_Library (NWTC_LIB), AeroDyn (AD_LOC), AeroDyn's wind inflow 
% routines (WIND_LOC), and FAST (FAST_LOC):
%--------------------------------------------------------------------------
NWTC_LIB    = 'D:\JasonJonkman\DesignCodes\NWTC_Subs\Source';
WIND_LOC    = 'D:\JasonJonkman\DesignCodes\AeroDyn\Source\InflowWind\Source';
AD_LOC      = 'D:\JasonJonkman\DesignCodes\AeroDyn\Source';
FAST_LOC    = 'D:\JasonJonkman\DesignCodes\FAST\Source';
Sim_LOC     = 'D:\JasonJonkman\DesignCodes\FAST\Simulink\Source';

% NWTC_LIB    = 'Y:\Wind\Public\Projects\DesignCodes\miscellaneous\nwtc_subs\Source';
% WIND_LOC    = 'Y:\Wind\Public\Projects\DesignCodes\AeroDyn\Source\v13.00.00a-bjj\Source\InflowWind\Source';
% AD_LOC      = 'Y:\Wind\Public\Projects\DesignCodes\AeroDyn\Source\v13.00.00a-bjj\Source';
% FAST_LOC    = 'Y:\Wind\Public\Projects\DesignCodes\FAST\InProgress\v7.00.01a-bjj\Source';
% Sim_LOC     = 'Y:\Wind\Public\Projects\DesignCodes\FAST\InProgress\v7.00.01a-bjj\Simulink\Source';


%% ------------------------------------------------------------------------
% Compile the mex function
%--------------------------------------------------------------------------
mex('-v'                                             , ... %verbose
    '-f',      FortranOptionsFile                    , ... %file containing fortran options
    '-output', OutputRootName                        , ... %name of the resulting mex function
    fullfile(NWTC_LIB, 'DoubPrec.f90'               ), ...
    fullfile(NWTC_LIB, 'SysMatlab.f90'              ), ...
    fullfile(NWTC_LIB, 'NWTC_IO.f90'                ), ...
    fullfile(NWTC_LIB, 'NWTC_Num.f90'               ), ...
    fullfile(NWTC_LIB, 'NWTC_Aero.f90'              ), ...
    fullfile(NWTC_LIB, 'NWTC_Library.f90'           ), ...
    fullfile(WIND_LOC, 'SharedInflowDefs.f90'       ), ...
    fullfile(WIND_LOC, 'HHWind.f90'                 ), ...
    fullfile(WIND_LOC, 'FFWind.f90'                 ), ...
    fullfile(WIND_LOC, 'FDWind.f90'                 ), ...
    fullfile(WIND_LOC, 'CTWind.f90'                 ), ...
    fullfile(WIND_LOC, 'UserWind.f90'               ), ...
    fullfile(WIND_LOC, 'InflowWindMod.f90'          ), ...
    fullfile(AD_LOC,   'SharedTypes.f90'            ), ...
    fullfile(AD_LOC,   'AeroMods.f90'               ), ...
    fullfile(AD_LOC,   'GenSubs.f90'                ), ... 
    fullfile(AD_LOC,   'AeroSubs.f90'               ), ...
    fullfile(AD_LOC,   'AeroDyn.f90'                ), ...
    fullfile(FAST_LOC, 'FAST_Mods.f90'              ), ...
    fullfile(FAST_LOC, 'Noise.f90'                  ), ...
    fullfile(FAST_LOC, 'fftpack.f'                  ), ...
    fullfile(FAST_LOC, 'FFTMod.f90'                 ), ...
    fullfile(FAST_LOC, 'HydroCalc.f90'              ), ...
    fullfile(FAST_LOC, 'AeroCalc.f90'               ), ...
    fullfile(FAST_LOC, 'FAST_IO.f90'                ), ...
    fullfile(FAST_LOC, 'FAST.f90'                   ), ...
    fullfile(FAST_LOC, 'PitchCntrl_ACH.f90'         ), ...
    fullfile(FAST_LOC, 'SetVersion.f90'             ), ...
    fullfile(FAST_LOC, 'UserSubs.f90'               ), ...
    fullfile(FAST_LOC, 'UserVSCont_KP.f90'          ), ...
    fullfile(Sim_LOC , 'FASTSimulink.f90'           ), ...
    fullfile(Sim_LOC,  'FASTGateway.f90'            )  );

%--------------------------------------------------------------------------
% Clean up and display a message.
%--------------------------------------------------------------------------
delete ('*.mod')
disp(['mex completed: ' OutputRootName '.' mexext ' has been created.'])

