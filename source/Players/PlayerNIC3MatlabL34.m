classdef PlayerNIC3MatlabL34 < PlayerNIC3
    % PlayerNIC3MatlabL34 < PlayerNIC3
    %   
    %   Class that defines the PlayerNIC3MatlabL34 object.
	%
	%	It uses the Matlab interface with nic3 (the streaming .bat file should therefore 
	%	be started before calling this script).
    %
    %   PlayerNIC3MatlabL34 Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - 0 here: PlayerNIC3MatlabL34 doesn't block the matlab prompt when playing      
    %       nic3javapath - nic3 settings
    %       platform - nic3 settings
    %       auto_pufs - nic3 settings
    %       implant - CIC3 or CIC4
    %       mode - nic3 settings
    %       flagged_electrodes - nic3 settings
    %       min_pulse_width_us - nic3 settings
    %       latency_ms - nic3 settings
    %       go_live - nic3 settings
    %
    %   PlayerNIC3MatlabL34 Methods:
    %       play(obj, stimObj) - obj.play(stimObj) plays the stimulus
    %
    %   Example:
    %       p = PlayerNIC3MatlabL34(); % Laura speech processor
    %       stim = PulseTrainNIC3Matlab();
    %       p.play(stim)    
    %
    %   See also PLAYER, FORMAT, BLEEP, PULSETRAINNIC3MATLAB       
    
    properties
        implant = 'CIC4';        
    end
    
    % These properties can't be modified by the user, to avoid false manipulation
    properties (SetAccess = protected)
        stimulus_format = @FormatNIC3Matlab;
        is_blocking = 0; % PlayerNIC3MatlabL34 doesn't block the matlab prompt when playing 
        nic3javapath = 'C:\nucleus\nic3\binaries\LLCstreamClient.jar';
        platform = 'L34';
        auto_pufs = 'on';
        mode = 'MP1+2';
        flagged_electrodes = '22';
        min_pulse_width_us = '20.0';
        latency_ms = '100';
	end
	
	% This cannot be changed in the current release (use python interface if needed)
	properties
        go_live = 'on';
    end
    
    % Handle to the java client
    properties (Hidden, Access = protected)
        client = [];
    end
    
    methods
        function obj = PlayerNIC3MatlabL34()
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
            STIM = struct2map(full_stim);
            
            % Stream stimulus and update stream status
            stream_status = obj.client.sendData(STIM, true);
            old_stream_status = obj.client.STREAMER_STATUS_NIL;
        end
        
        function delete(obj)
            obj.client.stopStream()
            obj.client.close();
            disp('LLCstreamer has finished.')
        end
        
        function init(obj)
            
            % Add java path - needs to happen before global matlab variables are set
            javaaddpath(obj.nic3javapath);
            
            % Set properties
            properties = java.util.Hashtable;
            properties.put('platform', obj.platform);
            properties.put('auto_pufs', obj.auto_pufs);
            properties.put('implant', obj.implant);
            properties.put('mode', obj.mode);
            properties.put('flagged_electrodes', obj.flagged_electrodes);
            properties.put('min_pulse_width_us', obj.min_pulse_width_us);
            properties.put('latency_ms', obj.latency_ms);
            properties.put('go_live', obj.go_live);
            
            % Connect to port 5555
            obj.client = com.cochlear.nic3.StreamerClient(5555);   % connect to port 5555 on the same machine
            
            % Start streaming (auto_pufs)
            obj.client.open();
            obj.client.init(properties);
            obj.client.startStream();
            
        end
		
		function set.go_live(~,~)
            error('This can not be changed in the current release of the pps Toolbox')
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
end