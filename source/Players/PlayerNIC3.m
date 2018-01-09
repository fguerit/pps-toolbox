classdef (Abstract) PlayerNIC3 < Player
    % PlayerNIC3 < Player (Abstract)
    %   
    %   Class that defines the "must-have" for a PlayerNIC3 object
    %   (Cochlear direct stimulation).
    %
    %   PlayerNIC3 Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - If the player is/isn't blocking the matlab prompt when playing     
    %       nic3javapath - nic3 settings
    %       platform - nic3 settings
    %       auto_pufs - nic3 settings
    %       mode - nic3 settings
    %       flagged_electrodes - nic3 settings
    %       min_pulse_width_us - nic3 settings
    %       latency_ms - nic3 settings
    %       go_live - nic3 settings
    %
    %   PlayerNIC3 Methods:
    %       play(obj, stimObj) - obj.play(stimObj) plays the stimulus
    %
    %   See also PLAYER, PLAYERNIC3MATLABL34, FORMAT, BLEEP    
    
    properties (Abstract, SetAccess = protected)
        stimulus_format % Format that can be read by the player
        is_blocking % If the player is/isn't blocking the matlab prompt when playing        
        nic3javapath % nic3 settings
        platform % nic3 settings
        auto_pufs % nic3 settings
        mode % nic3 settings
        flagged_electrodes % nic3 settings
        min_pulse_width_us % nic3 settings
        latency_ms % nic3 settings
    end
    
    properties (Abstract)
        go_live % nic3 settings
    end
    
    methods (Abstract)
        play(obj, stimObj) % obj.play(stimObj) plays the stimulus
    end
    
end