classdef (Abstract) FormatNIC4Python < FormatElectric & handle
    % FormatNIC4Python < FormatElectric & handle
    %
    %   Class that defines the "must-have" for a stimulus to be played with
    %   NIC4 (Cochlear) using the Python interface.
    %
    %   FormatNIC4Python Properties (SetAccess = protected, Hidden):
    %       Values (or arrays) to be passed on to the speech processor
    %       The user can not access them, to avoid false manipulation    
    %       seq - Sequence of instructions to be passed to the streamer 
    %
    %   See also PLAYER, BLEEP, FormatElectric, PULSETRAINNIC4PYTHON    
    
    % A python file is written, to be used by the player
    % The user can not change its name, to avoid false manipulation
    properties (Abstract, SetAccess = protected)
        stimulus_file % parameter file used by the player
    end
    
end