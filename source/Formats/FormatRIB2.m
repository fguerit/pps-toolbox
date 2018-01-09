classdef (Abstract) FormatRIB2 < FormatElectric & handle
    % FormatRIB2 < FormatElectric & handle
    %
    %   Abstract class that defines the "must-have" for a stimulus to be played on
    %   a MedEl player with the RIB2 direct-stimulation software.
    %
    %   FormatRIB2 Properties:
    %       stimulus_file - parameter file used by the player 
    %
    %   See also PLAYERRIB2, BLEEP, FormatElectric, PULSETRAINRIB2    
    
    
    properties (Abstract, SetAccess = protected)
        stimulus_file
    end
    
end