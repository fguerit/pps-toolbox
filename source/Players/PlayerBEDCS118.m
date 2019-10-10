classdef PlayerBEDCS118 < Player
    % PlayerBEDCS118 < Player
    %
    %   Class that defines the PlayerBEDCS118 object, to play stimuli with
    %   BEDCS 1.18 (Advanced Bionics).
    %
    %   PlayerBEDCS118 Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - 1 here: PlayerBEDCS118 blocks the matlab prompt when playing     
    %       server_name - BEDCS activex server
    %       online - Try to connect with the CPI or not
    %       visible - See BEDCS interface (to avoid!)
    %
    %   PlayerBEDCS118 Methods:
    %       play(obj, stimObj) - obj.play(stimObj) plays the stimulus
    %
    %   Example:
    %       p = PlayerBEDCS118(); % Laura speech processor
    %       stim = PulseTrainBEDCS118();
    %       p.play(stim)
    %
    %   See also PLAYER, FORMAT, BLEEP, PULSETRAINAB
    
    properties (SetAccess = protected)
        stimulus_format = @FormatBEDCS118; % Format that can be read by the player
        is_blocking = 1; % PlayerBEDCS118 blocks the matlab prompt when playing
        server_name = 'BEDCS2.CBEDCSApp'; % BEDCS activex server
        online = 1; % Try to connect with the CPI or not
        visible = 0; % Show BEDCS interface (to avoid!)
    end
    
    properties (Hidden, Access = protected)
        h = []; % Handle to the BEDCS sever
    end
    
    methods
        function obj = PlayerBEDCS118()
            % constructor. Inits the server at startup
            
            obj.init();
        end
        
        function play(obj, stimObj)
            % PLAY plays the stimulus
            %
            %   Example:
            %       p = PlayerBEDCS118(); % Laura speech processor
            %       stim = PulseTrainBEDCS118();
            %       p.play(stim)
            
            % Check that the format is correct
            if ~isa(stimObj, func2str(obj.stimulus_format))
                error(['"p.play(stimObj)": stimObj should be of class "'...
                    func2str(obj.stimulus_format)...
                    '". Type "showSubClassesFormat" to get the current list.'])
            end
            
            % Load the file if not already done
            if ~strcmp(obj.h.ExpFileName, stimObj.exp_file)
                obj.h.LoadExpFile(stimObj.exp_file)
            end
            
            obj.h.ULevelMode = stimObj.level_mode;
            
            % Update the stimulus properties
            fields = fieldnames(stimObj.variables_struct);
            for i = 1:length(fields)
                obj.h.Let_ControlVarVal(fields{i},...
                    getfield(stimObj.variables_struct,fields{i}))
            end
            
            % Plays the stimulus
            too_soon = true;
            while too_soon
                try obj.h.MeasureNoSave; too_soon=false;%present pulse train
                catch, pause(.1);
                end
            end
            
        end
    end
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            % Loads object from structure
            if isstruct(s)
                obj = PlayerBEDCS118();
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
            % Inits the server
            
            obj.h = actxserver(obj.server_name);
            obj.h.Online = obj.online;
            obj.h.Visible = obj.visible;
            
        end        
    end
    
end