classdef (Abstract) Format < handle
    % FORMAT Class that defines the "must-have" for a stimulus to be played
    %
    %   A bit like a CD can't be played by a VHS player, an AB-Format can't
    %   be played by a MEDEL player. Even if they have the same content.
    %
    %   FORMAT Properties:
    %       max_level - User-defined maximum level (device units)  
    %
    %   FORMAT Methods:
    %       struct(obj) - struct(obj) outputs a structure with the most
    %       relevant properties and their values
    %       plot - Plots the stimulus      
    %
    %   See also PLAYER, STIMULUS, FormatElectric

    properties (Abstract)
        max_level % User-defined maximum level (device units)
    end
    
    methods (Abstract)
        struct(obj) % struct(obj) outputs a structure with the most
        % relevant properties and their values   
        plot(obj) % Plots the stimulus        
    end
    
    methods (Abstract, Hidden)
        init(obj) % Initializes the stimulus (to be called at start or when 
        % updating a property
    end
    
    methods (Abstract, Access = protected)
        check_level(obj) % Method that returns an error if max level is exceeeded
    end     
end