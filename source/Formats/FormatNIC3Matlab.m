classdef (Abstract) FormatNIC3Matlab < FormatElectric & handle
    % FormatNIC3Matlab < FormatElectric & handle
    %
    %   Class that defines the "must-have" for a stimulus to be played with
    %   NIC3 (Cochlear) using the Matlab interface.
    %
    %   FormatNIC3Matlab Properties (SetAccess = protected, Hidden):
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
    %   See also PLAYER, BLEEP, FormatElectric, PULSETRAINNIC3MATLAB    
    
    
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