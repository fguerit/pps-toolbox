classdef PlayerDummyMonauralNonBlocking < Player
    % PlayerDummyMonauralNonBlocking < Player
    %
    %   Class that defines the dummy player object. This player can "play"
    %   any CI stimulus. It effectively just returns the prompt
    %
    %   PlayerDummyMonauralNonBlocking Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - 0 here     
    %
    %   PlayerDummyMonauralNonBlocking Methods:
    %       play(obj, stimObj) - obj.play(stimObj) returns the prompt
    %
    %   Example:
    %       p = PlayerDummyMonauralNonBlocking(); 
    %       stim = PulseTrainAB();
    %       p.play(stim)
    %
    %   See also PLAYER, FORMAT, BLEEP
    
    properties (SetAccess = protected)
        stimulus_format = @Format; % Format that can be read by the player
        is_blocking = 0; % PlayerDummyMonauralNonBlocking blocks the matlab prompt when playing
    end
    
    properties (Hidden, Access = protected)
        h = []; % Handle to the BEDCS sever
    end
    
    methods
        function obj = PlayerDummyMonauralNonBlocking()
            % constructor. Inits the server at startup
            
        end
        
        function init(obj)
            % Inits the server
            
            
        end
        
        function play(obj, stimObj)
            % PLAY plays the stimulus. Since it's a dummy player, it just
            % returns the prompt.
            %
            %   Example:
            %       p = PlayerDummyMonauralNonBlocking();
            %       stim = PulseTrainAB();
            %       p.play(stim)
            
            % Check stimulus
            if ~iscell(stimObj)
                stimObj = {stimObj};
            end
            
            n_stimuli = length(stimObj);
            
            for idx = 1:n_stimuli
                if ~isa(stimObj{idx}, func2str(obj.stimulus_format))
                    error(['"p.play(stimObj_1, stimObj_2, ... stimObj_n)": stimObj_' num2str(idx) 'should be of format "'...
                        func2str(obj.stimulus_format)...
                    '". Type "showSubClassesFormat" to get the current list.'])
                end
            end
            
        end
    end
    
end