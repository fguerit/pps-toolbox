classdef PlayerNIC4MatlabSP16 < PlayerNIC4
    % PlayerNIC4MatlabSP16 < PlayerNIC4
    %   
    %   Class that defines the PlayerNIC4MatlabSP16 object.
	%
	%	It uses the Matlab interface with nic4 (the streaming .bat file should therefore 
	%	be started before calling this script).
    %
    %   PlayerNIC4MatlabSP16 Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - 0 here: PlayerNIC4MatlabSP16 doesn't block the matlab prompt when playing      
    %       nic4javapath - nic4 settings
    %       platform - nic4 settings
    %       auto_pufs - nic4 settings
    %       implant - CIC3 or CIC4
    %       mode - nic4 settings
    %       flagged_electrodes - nic4 settings
    %       min_pulse_width_us - nic4 settings
    %       latency_ms - nic4 settings
    %       go_live - nic4 settings
    %
    %   PlayerNIC4MatlabSP16 Methods:
    %       play(obj, stimObj) - obj.play(stimObj) plays the stimulus
    %
    %   Example:
    %       p = PlayerNIC4MatlabSP16(); % Laura speech processor
    %       stim = PulseTrainNIC4Matlab();
    %       p.play(stim)    
    %
    %   See also PLAYER, FORMAT, BLEEP, PULSETRAINNIC4MATLAB       
    
    properties
        implant = 'CIC4';        
        go_live = 'on';        
    end
    
    % These properties can't be modified by the user, to avoid false manipulation
    properties (SetAccess = protected)
        stimulus_format = @FormatNIC4Matlab;
        is_blocking = 0; % PlayerNIC4MatlabSP16 doesn't block the matlab prompt when playing 
        nic4javapath = 'C:\nucleus\nic4\binaries\nic4.jar';
        platform = 'SP16';
        auto_pufs = 'on';
        mode = 'MP1+2';
        flagged_electrodes = '';
        min_pulse_width_us = '25.0';
        latency_ms = '100';
        c_levels = ['255 255 255 255 255 255 255 255 255 255 255 255 255 '...
            '255 255 255 255 255 255 255 255 255'];
        c_levels_pulse_width_us = '40.0';        
    end
    
    % Handle to the java client
    properties (Hidden, Access = protected)
        client = [];
    end
    
    methods
        function obj = PlayerNIC4MatlabSP16()
            % Constructor, inits the java client at startup
            
            obj.init();
            
        end
        
        function play(obj, stimObj)
            
            if ~isa(stimObj, func2str(obj.stimulus_format))
                error(['"p.play(stimObj)": stimObj should be of format "'...
                    func2str(obj.stimulus_format)...
                    '". Type "showSubClassesFormat" to get the current list.'])
            end
            
            % Generate stimulus and translate to a java map
            full_stim = struct('electrodes', stimObj.electrodes, ...
                'modes', stimObj.modes, ...
                'current_levels', stimObj.current_levels, ...
                'phase_widths', stimObj.phase_widths, ...
                'phase_gaps', stimObj.phase_gaps, ...
                'periods', stimObj.periods);
            STIM = cochlear.nic.nic4.struct2map(full_stim);
            
            % Stream stimulus and update stream status
            obj.client.sendData(STIM);
        end
        
        function delete(obj)
            obj.client.stop()
            obj.client.close();
            disp('Streaming ended.')
        end
		
		function set.go_live(~, ~)
            error('go_live forced to be "on" because "off" creates at the moment a text file increasing very rapidly in size.')
        end 
        
        function set.implant(obj, value)
            % Settings
            property_class = {'char'};
            property_attributes = {'nonempty'};
            string_attributes = {'CIC3', 'CIC4'};
            prop_name = 'implant';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes);            
            value = validatestring(value, string_attributes);
            tmp_value = obj.(prop_name);
            try
                obj.(prop_name) = value;
                obj.init;
            catch error_msg
                obj.(prop_name) = tmp_value;
                obj.init;
                warning('%s could not be changed, and was kept to its previous value.\n\nCf. error message below for more info.', prop_name)
                rethrow(error_msg)
            end             
        end        
    end
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            % Loads object from structure
            if isstruct(s)
                newObj = PlayerNIC4MatlabSP16();
                newObj.implant = s.implant;
                obj = newObj;
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
            
            s.implant = obj.implant;
        end
        
        function init(obj)
            
            % Add java path - needs to happen before global matlab variables are set
            if sum(cellfun(@(c) numel(strfind(c, 'nic4.jar')), javaclasspath)) == 0
                javaaddpath(obj.nic4javapath)
            end
            
            % Set properties
            properties = java.util.HashMap;
            properties.put('platform', obj.platform);
            properties.put('auto_pufs', obj.auto_pufs);
            properties.put('implant', obj.implant);
            properties.put('mode', obj.mode);
            properties.put('flagged_electrodes', obj.flagged_electrodes);
            properties.put('min_pulse_width_us', obj.min_pulse_width_us);
            properties.put('latency_ms', obj.latency_ms);
            properties.put('go_live', obj.go_live);
            properties.put('c_levels_pulse_width_us', obj.c_levels_pulse_width_us);
            properties.put('c_levels', obj.c_levels);
            properties.put('verbose', 'on');
            
            % Connect to port 5555
            obj.client = com.cochlear.nic.nic4.Streamer(properties, 5555);   % connect to port 5555 on the same machine
            
            % Start streaming (auto_pufs)
            obj.client.start();
            
        end       
    end      
        
end