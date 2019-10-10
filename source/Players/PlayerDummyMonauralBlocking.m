classdef PlayerDummyMonauralBlocking < Player
    % PlayerDummyMonauralBlocking < Player
    %
    %   Class that defines the dummy player object. This player can "play"
    %   any CI stimulus. It effectively blocks the prompt instead of
    %   playing the sound.
    %
    %   PlayerDummyMonauralBlocking Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - 1 here: PlayerDummyMonauralBlocking blocks the matlab prompt when playing     
    %
    %   PlayerDummyMonauralBlocking Methods:
    %       play(obj, stimObj) - obj.play(stimObj) blocks the prompt for
    %       the length of the stimulus
    %
    %   Example:
    %       p = PlayerDummyMonauralBlocking(); 
    %       stim = PulseTrainAB();
    %       p.play(stim)
    %
    %   See also PLAYER, FORMAT, BLEEP
    
    properties (SetAccess = protected)
        stimulus_format = @Format; % Format that can be read by the player
        is_blocking = 1; % PlayerDummyMonauralBlocking blocks the matlab prompt when playing
    end
    
    methods
        function obj = PlayerDummyMonauralBlocking()
            % constructor. Inits the server at startup
            
        end
        
        function play(obj, stimObj)
            % PLAY plays the stimulus. Since it's a dummy player, it just
            % blocks the prompt for the stimulus duration.
            %
            %   Example:
            %       p = PlayerDummyMonauralBlocking();
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
            
            % "Plays" the stimulus: blocks the prompt
            for idx = 1:n_stimuli
                pause(stimObj{idx}.whole_duration_s)
            end
            
        end
    end
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            % Loads object from structure
            if isstruct(s)
                obj = PlayerDummyMonauralBlocking();
            else
                obj = s;
            end
        end
    end
    
    methods (Hidden)
        
        function s = saveobj(obj)
            % Saves object to structure
            % 
            % This avoids saving the link to the activeX server, as this
            % would likely crash when reloading the object from a mat-file.
            
            % Here there's no user-modifiable properties, so empty
            % structure
            s = struct;
        end
        
        function init(obj)

            
        end        
    end        
    
end