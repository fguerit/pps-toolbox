classdef PlayerNIC3PythonRFGenXSBilateral < PlayerNIC3
    % PlayerNIC3PythonRFGenXSBilateral < PlayerNIC3
    %   
    %   Class that defines the PlayerNIC3PythonRFGenXSBilateral object.
    %
    %   It writes .py scripts and runs Python 2.7 in the background.
    %
    %   PlayerNIC3PythonRFGenXSBilateral Properties (can be modified):    
    %       go_live - 1 by default, virtual stimulation by using 0
    %       python_distribution - "python.exe" by default
    %       show_terminal - option to show terminal for debugging (0 by
    %       default)    
    %       implant_left - "CIC4" or "CIC3"
    %       implant_right - "CIC4" or "CIC3"    
    %
    %   PlayerNIC3PythonRFGenXSBilateral Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - 0 here: PlayerNIC3PythonRFGenXSBilateral doesn't block the matlab prompt when playing      
    %       nic3javapath - nic3 settings
    %       platform - nic3 settings
    %       auto_pufs - nic3 settings
    %       mode - nic3 settings
    %       flagged_electrodes - nic3 settings
    %       min_pulse_width_us - nic3 settings
    %       latency_ms - nic3 settings
    %
    %   PlayerNIC3PythonRFGenXSBilateral Methods:
    %       play(obj, stimObjLeft, stimObjRight) - obj.play(stimObjLeft, stimObjRight)
    %       plays the stimuli on both sides.
    %       play(obj, {stimObjLeft_1, .., stimObjRight_n}, {stimObjLeft_1, .., stimObjRight_k}) - plays a 
    %       list of stimuli on each side (doesn't have to be same length)
    %
    %   Example (for one stimulus):
    %       p = PlayerNIC3PythonRFGenXSBilateral(); 
    %       stimLeft = PulseTrainNIC3Python();
    %       stimRight = PulseTrainNIC3Python();
    %       p.play(stimLeft, stimRight)    
    %
    %   Example (for playing mutiple stimuli):
    %       p = PlayerNIC3PythonRFGenXSBilateral(); 
    %       stimLeft = PulseTrainNIC3Python();
    %       stimRight = PulseTrainNIC3Python();
    %       p.play({stimLeft, stimLeft}, {stimRight, stimRight})    
    %
    %   See also PLAYERNIC3PYTHONRFGENXS, PULSETRAINNIC3PYTHON       
    
    properties
        go_live = 1; % 1 by default, virtual stimulation by using 0
        python_path = 'python.exe'; % "python.exe" by default
        show_terminal = 0; % option to show terminal for debugging (0 by
        % default)
        implant_left = 'CIC4';
        implant_right = 'CIC4';
    end
    
    % These properties can't be modified by the user, to avoid false manipulation
    properties (SetAccess = protected)
        stimulus_format = @FormatNIC3Python;
        is_blocking = 0; % PlayerNIC3PythonRFGenXSBilateral doesn't block the matlab prompt when playing 
        nic3javapath = ''; % Not necessary for python
        platform = 'RFGenXS';
        auto_pufs = 'off';
        mode = 'MP1+2';
        flagged_electrodes = '';
        min_pulse_width_us = '20.0';
        latency_ms = '100';
    end
    
    % Handle to the java client
    properties (Hidden, Access = protected)
        python_process = [];
        python_file_main = [];
        python_file_properties = [];
        start_bool = 0;
    end
    
    methods
        function obj = PlayerNIC3PythonRFGenXSBilateral()
            % Constructor, inits the client at startup
            
            obj.init();
            
        end
        
        function play(obj, stimObj_left, stimObj_right)
            
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
            
            obj.clean_files();
            
            obj.init();
            
            fid_stimulus = fopen(obj.python_file_main,'wt');
            
            % Print Header
            fprintf(fid_stimulus, 'import imp\n');
            fprintf(fid_stimulus, 'import cochlear.nic3 as nic3\n\n');            
            
            % Print the sequences for the left stimulus
            fprintf(fid_stimulus, 'seq_main_left = nic3.Sequence()\n\n');
            for idx = 1:n_stimuli_left
                fprintf(fid_stimulus, 'seq_%d_left = imp.load_source("seq_%d_left", "%s")\n', ...
                    idx, idx, strrep(stimObj_left{idx}.stimulus_file, '\', '\\')); 
                fprintf(fid_stimulus, 'seq_main_left.append(seq_%d_left.seq)\n\n', idx);
            end            
            
            % Print the sequences for the right stimulus
            fprintf(fid_stimulus, 'seq_main_right = nic3.Sequence()\n\n');
            for idx = 1:n_stimuli_right
                fprintf(fid_stimulus, 'seq_%d_right = imp.load_source("seq_%d_right", "%s")\n', ...
                    idx, idx, strrep(stimObj_right{idx}.stimulus_file, '\', '\\')); 
                fprintf(fid_stimulus, 'seq_main_right.append(seq_%d_right.seq)\n\n', idx);
            end                        
            
            % Print properties
            fprintf(fid_stimulus, 'props = imp.load_source("props", "%s")\n', ...
                strrep(obj.python_file_properties, '\', '\\')); 
            fprintf(fid_stimulus, 'streamer_left = nic3.Streamer(props.p_left)\n');
            fprintf(fid_stimulus, 'streamer_right = nic3.Streamer(props.p_right)\n');
            fprintf(fid_stimulus, 'streamer_left.start()\n');
            fprintf(fid_stimulus, 'streamer_right.start()\n');
            fprintf(fid_stimulus, 'streamer_left.sendData(seq_main_left)\n');
            fprintf(fid_stimulus, 'streamer_right.sendData(seq_main_right)\n');
            fprintf(fid_stimulus, 'streamer_left.waitUntilFinished()\n');
            fprintf(fid_stimulus, 'streamer_right.waitUntilFinished()\n');
            fprintf(fid_stimulus, 'streamer_left.stop()\n');
            fprintf(fid_stimulus, 'streamer_right.stop()\n\n');
            
            if obj.show_terminal
                fprintf(fid_stimulus, 'raw_input("Press Enter to continue...")\n');
            end
            
            fclose(fid_stimulus);            
            
            startInfo = System.Diagnostics.ProcessStartInfo(obj.python_path, ...
                sprintf(' %s', obj.python_file_main));            
            
            if ~obj.show_terminal
                startInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;  %// if you want it invisible
            end
            
            % Start python process
            obj.python_process = System.Diagnostics.Process.Start(startInfo);
            
            obj.start_bool = 1;
            
        end
        
        function delete(obj)
            
           obj.clean_files();    
           
        end
        
        function init(obj)
            
            % file name is written with round(now*1e8) at the beginning to
            % make sure one can create two players in a very short time
            % with different names
            [current_path, ~, ~] = fileparts(mfilename('fullpath'));
            if ~exist(obj.python_file_properties, 'file')
                obj.python_file_properties = [current_path filesep ...
                    sprintf('%d', round(now*1e12)) '_cochlear_file_player_properties.py'];
            end
            
            if ~exist(obj.python_file_main, 'file')
                obj.python_file_main = [current_path filesep ...
                    sprintf('%d', round(now*1e12)) '_cochlear_file_player_main.py'];
            end
            
            fid_stimulus = fopen(obj.python_file_properties,'wt');
            
            % Header
            fprintf(fid_stimulus, 'import cochlear.nic3 as nic3\n\n');
            fprintf(fid_stimulus, 'def get_properties():\n');
            
            % Create python properties object
            fprintf(fid_stimulus, '    p = nic3.Properties()\n');
            fprintf(fid_stimulus, '    p.add("platform", "%s")\n', obj.platform);
            fprintf(fid_stimulus, '    p.add("mode", "%s")\n', obj.mode);
            fprintf(fid_stimulus, '    p.add("flagged_electrodes", "%s")\n', obj.flagged_electrodes);
            fprintf(fid_stimulus, '    p.add("min_pulse_width_us", "%s")\n', obj.min_pulse_width_us);
            fprintf(fid_stimulus, '    p.add("auto_pufs", "off")\n');
            fprintf(fid_stimulus, '    p.add("latency_ms", "%s")\n', obj.latency_ms);
            if obj.go_live
                fprintf(fid_stimulus, '    p.add("go_live", "on")\n');
            else
                fprintf(fid_stimulus, '    p.add("go_live", "off")\n');
            end
            fprintf(fid_stimulus, '    p_left = nic3.Properties(p)\n');
            fprintf(fid_stimulus, '    p_left.add("signal_path", "left")\n');
            fprintf(fid_stimulus, '    p_left.add("implant", "%s")\n', obj.implant_left);            
            fprintf(fid_stimulus, '    p_right = nic3.Properties(p)\n');
            fprintf(fid_stimulus, '    p_right.add("signal_path", "right")\n');
            fprintf(fid_stimulus, '    p_right.add("implant", "%s")\n', obj.implant_right);                        

            % Output the propertes
            fprintf(fid_stimulus, '    return p_left, p_right\n\n');
            fprintf(fid_stimulus, 'p_left, p_right = get_properties()\n');
            
            fclose(fid_stimulus);
        end
    end
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            % To avoid glitches when saving to .mat file, only modifiable
            % properties are saved (saveobj) in a structure and the object is
            % reconstructed when loading it.
            if isstruct(s)
                obj = PlayerNIC3PythonRFGenXSBilateral();
                obj.go_live = s.go_live;
                obj.show_terminal = s.show_terminal;
                obj.implant_left = s.implant_left;
                obj.implant_right = s.implant_right;
                obj.python_path = s.python_path;
            else
                obj = s;
            end
        end
    end    
    
    methods (Hidden)
        
        function s = saveobj(obj)
            % To avoid glitches when saving to .mat file, only modifiable
            % properties are saved (saveobj) in a structure and the object is
            % reconstructed when loading it.
            s.go_live = obj.go_live;
            s.show_terminal = obj.show_terminal;
            s.implant_left = obj.implant_left;
            s.implant_right = obj.implant_right;
            s.python_path = obj.python_path;
        end
    end    
    
    methods (Hidden)
        
        function clean_files(obj)
            
            if obj.start_bool
                
                if ~obj.python_process.HasExited()
                    warning(sprintf(['\nThe last python process was still running' ...
                        ' and has been killed.\n\nThis can be because:\n- the process ' ...
                        'crashed (set player.show_terminal to 1 to get more info)\n' ...
                        '- user data was still being streamed (consider waiting before using the player again)\n']))
                end
                
                try
                    obj.python_process.Kill;
                    obj.python_process.Close;
                catch
                    obj.python_process.Close;
                end
            end
            
            if ~isempty(obj.python_file_properties)
                delete([obj.python_file_properties '*'])
            end
            if ~isempty(obj.python_file_main)
                delete([obj.python_file_main '*'])
            end
            
        end
    end
    
    methods
        
        function set.go_live(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', 'integer', '>=', 0, '<=', 1};
            prop_name = 'go_live';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes)            
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
        function set.show_terminal(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', 'integer', '>=', 0, '<=', 1};
            prop_name = 'show_terminal';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes)            
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
        function set.python_path(obj,value)
            obj.python_path = value;
            obj.init;
        end
        function set.implant_left(obj, value)
            % Settings
            property_class = {'char'};
            property_attributes = {'nonempty'};
            string_attributes = {'CIC3', 'CIC4'};
            prop_name = 'implant_left';
            
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
        function set.implant_right(obj, value)
            % Settings
            property_class = {'char'};
            property_attributes = {'nonempty'};
            string_attributes = {'CIC3', 'CIC4'};
            prop_name = 'implant_right';
            
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