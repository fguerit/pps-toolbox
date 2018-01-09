classdef (Abstract) Player < handle
    % PLAYER Class that defines the "must-have" for a player object
    %
    %   A bit like a CD can't be played by a VHS player, an AB-Format can't
    %   be played by a MEDEL player. Even if they have the same content.
    %
    %   PLAYER Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - If the player is/isn't blocking the matlab prompt when playing    
    %
    %   PLAYER Methods:
    %       play(obj, stimObj) - obj.play(stimObj) plays the stimulus
    %
    %   See also PLAYERAB, PLAYERCOCHLEAR, FORMAT, BLEEP
    
    properties (Abstract, SetAccess = protected)
        stimulus_format % Format that can be read by the player
        is_blocking % If the player is/isn't blocking the matlab prompt when playing
    end
    
    methods (Abstract)
        play(obj, stimObj) % obj.play(stimObj) plays the stimulus
    end
    
    methods (Abstract, Hidden)
        init(obj) % Initializes the player (to be called at start or when 
        % updating a property
    end        
    
end