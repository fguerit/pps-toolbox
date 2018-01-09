classdef (Abstract) Stimulus < handle
    % Stimulus Top class for all stimuli.
    %
    %   Stimulus Properties:
    %       whole_duration_s - Whole stimulus's duration, including pre- and
    %       post-stimulus if existing. This is useful for flashing GUI.
    %
    %   This is the top class of several implementations. To be played by a
    %   PLAYER object, a Stimulus also needs to be a subclass of a FORMAT.
    %
    % See also FORMAT, PLAYER, PULSETRAIN
    
    properties (Abstract, SetAccess = protected, Hidden)
        whole_duration_s % Includes pre- and post-stimulus
    end
                 
end