classdef PlayerDummyBilateralBlocking < Player
    % PlayerDummyBilateralBlocking < Player
    %
    %   Class that defines the dummy bilateral player object. This player can "play"
    %   any CI stimulus. It effectively blocks the prompt instead of
    %   playing the sound.
    %
    %   PlayerDummyBilateralBlocking Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - 1 here: PlayerDummyBilateralBlocking blocks the matlab prompt when playing     
    %
    %   PlayerDummyBilateralBlocking Methods:
    %       play(obj, stimObj_left, stimObj_right) - obj.play(stimObj_left, stimObj_right) blocks the prompt for
    %       the length of the stimulus
    %
    %   Example:
    %       p = PlayerDummyBilateralBlocking(); 
    %       stim = PulseTrainAB();
    %       p.play(stim, stim)
    %
    %   See also PLAYER, FORMAT, BLEEP
    
    properties (SetAccess = protected)
        stimulus_format = @Format; % Format that can be read by the player
        is_blocking = 1; % PlayerDummyBilateralBlocking blocks the matlab prompt when playing
    end
    
    methods
        function obj = PlayerDummyBilateralBlocking()
            % constructor. Inits the server at startup
            
        end
        
        
        function play(obj, stimObj_left, stimObj_right)
            % PLAY plays the stimulus. Since it's a dummy player, it just
            % blocks the prompt for the stimulus duration.
            %
            %   Example:
            %       p = PlayerDummyBilateralBlocking();
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
            
            sum_left = 0;
            sum_right = 0;
            for idx = 1:n_stimuli_left
                sum_left = sum_left + stimObj_left{idx}.whole_duration_s;
            end
            
            for idx = 1:n_stimuli_right
                sum_right = sum_right + stimObj_left{idx}.whole_duration_s;
            end
            
            % "Plays" the stimulus: blocks the prompt            
            pause(max(sum_left, sum_right))
            
        end
    end
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            % Loads object from structure
            if isstruct(s)
                obj = PlayerDummyBilateralBlocking();
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