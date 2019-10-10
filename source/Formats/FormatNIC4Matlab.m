classdef (Abstract) FormatNIC4Matlab < FormatElectric & handle
    % FormatNIC4Matlab < FormatElectric & handle
    %
    %   Class that defines the "must-have" for a stimulus to be played with
    %   NIC4 (Cochlear) using the Matlab interface.
    %
    %   FormatNIC4Matlab Properties (SetAccess = protected, Hidden):
    %       Values (or arrays) to be passed on to the speech processor
    %       The user can not access them, to avoid false manipulation    
    %           electrodes
    %           modes
    %           current_levels
    %           phase_widths
    %           phase_gaps
    %           periods
    %
    %
    %   See also PLAYER, BLEEP, FormatElectric, PULSETRAINNIC4MATLAB    
    
    
    % Values (or arrays) to be passed on to the speech processor
    % The user can not access them, to avoid false manipulation
    properties (Abstract, SetAccess = protected, Hidden)
        electrodes
        modes
        current_levels
        phase_widths
        phase_gaps
        periods
    end    
    
end