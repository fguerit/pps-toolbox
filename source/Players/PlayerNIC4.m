classdef (Abstract) PlayerNIC4 < Player
    % PlayerNIC4 < Player (Abstract)
    %   
    %   Class that defines the "must-have" for a PlayerNIC4 object
    %   (Cochlear direct stimulation).
    %
    %   PlayerNIC4 Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - If the player is/isn't blocking the matlab prompt when playing     
    %       nic4javapath - nic4 settings
    %       platform - nic4 settings
    %       auto_pufs - nic4 settings
    %       mode - nic4 settings
    %       flagged_electrodes - nic4 settings
    %       min_pulse_width_us - nic4 settings
    %       latency_ms - nic4 settings
    %       go_live - nic4 settings
    %
    %   PlayerNIC4 Methods:
    %       play(obj, stimObj) - obj.play(stimObj) plays the stimulus
    %
    %   See also PLAYER, PLAYERNIC4MATLABL34, FORMAT, BLEEP    
    
    properties (Abstract, SetAccess = protected)
        stimulus_format % Format that can be read by the player
        is_blocking % If the player is/isn't blocking the matlab prompt when playing        
        nic4javapath % nic4 settings
        platform % nic4 settings
        auto_pufs % nic4 settings
        mode % nic4 settings
        flagged_electrodes % nic4 settings
        min_pulse_width_us % nic4 settings
        latency_ms % nic4 settings
    end
    
    properties (Abstract)
        go_live % nic4 settings
    end
    
    methods (Abstract)
        play(obj, stimObj) % obj.play(stimObj) plays the stimulus
    end
    
end