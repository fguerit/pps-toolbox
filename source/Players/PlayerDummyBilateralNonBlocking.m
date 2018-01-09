classdef PlayerDummyBilateralNonBlocking < Player
    % PlayerDummyBilateralNonBlocking < Player
    %
    %   Class that defines the dummy bilateral player object. This player can "play"
    %   any CI stimulus. It effectively just returns the prompt.
    %
    %   PlayerDummyBilateralNonBlocking Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - 1 here: PlayerDummyBilateralNonBlocking returns the prompt     
    %
    %   PlayerDummyBilateralNonBlocking Methods:
    %       play(obj, stimObj_left, stimObj_right) - obj.play(stimObj_left,
    %       stimObj_right) returns the prompt
    %
    %   Example:
    %       p = PlayerDummyBilateralNonBlocking(); 
    %       stim = PulseTrainAB();
    %       p.play(stim, stim)
    %
    %   See also PLAYER, FORMAT, BLEEP
    
    properties (SetAccess = protected)
        stimulus_format = @Format; % Format that can be read by the player
        is_blocking = 0; % PlayerDummyBilateralNonBlocking returns the prompt
    end
    
    properties (Hidden, Access = protected)
        h = []; % Handle to the BEDCS sever
    end
    
    methods
        function obj = PlayerDummyBilateralNonBlocking()
            % constructor. Inits the server at startup
            
        end
        
        function init(obj)
            % Inits the server
            
            
        end
        
        function play(obj, stimObj_left, stimObj_right)
            % PLAY plays the stimulus. Since it's a dummy player, it just
            % returns the prompt.
            %
            %   Example:
            %       p = PlayerDummyBilateralNonBlocking();
            %       stim = PulseTrainAB();
            %       p.play(stim, stim)
            
            % Check input
            if ~iscell(stimObj_left)
                stimObj_left = {stimObj_left};
            end
            if ~iscell(stimObj_right)
                stimObj_right = {stimObj_right};
            end
            
            n_stimuli_left = length(stimObj_left);
            n_stimuli_right = length(stimObj_right);
            
            for idx = 1:n_stimuli_left
                if ~isa(stimObj_left{idx}, func2str(obj.stimulus_format))
                    error(['At least one of the stimulus objects on the left channel is not of format "'...
                        func2str(obj.stimulus_format)...
                    '". Type "showSubClassesFormat" to get the current list.'])
                end
            end
            for idx = 1:n_stimuli_right
                if ~isa(stimObj_right{idx}, func2str(obj.stimulus_format))
                    error(['At least one of the stimulus objects on the right channel is not of format "'...
                        func2str(obj.stimulus_format)...
                    '". Type "showSubClassesFormat" to get the current list.'])
                end
            end
            
        end
    end
    
end