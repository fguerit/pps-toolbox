classdef PlayerNIC4PythonSP16 < PlayerNIC4
    % PlayerNIC4PythonSP16 < PlayerNIC4
    %   
    %   Class that defines the PlayerNIC4PythonSP16 object.
    %
    %   It writes .py scripts and runs Python 2.7 in the background.
    %
    %   PlayerNIC4PythonSP16 Properties (can be modified):    
    %       go_live - 1 by default, virtual stimulation by using 0
    %       python_distribution - "python.exe" by default
    %       show_terminal - option to show terminal for debugging (0 by
    %       default)
    %       implant - "CIC4" or "CIC3"
    %
    %   PlayerNIC4PythonSP16 Properties (can not be modified):
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - 0 here: PlayerNIC4PythonSP16 doesn't block the matlab prompt when playing      
    %       nic4javapath - nic4 settings
    %       platform - nic4 settings
    %       auto_pufs - nic4 settings
    %       mode - nic4 settings
    %       flagged_electrodes - nic4 settings
    %       min_pulse_width_us - nic4 settings
    %       latency_ms - nic4 settings
    %
    %   PlayerNIC4PythonSP16 Methods:
    %       play(obj, stimObj) - obj.play(stimObj) plays the stimulus
    %       play(obj, {stimObj_1, .., stimObj_n}) - plays a list of stimuli
    %       one after each other
    %
    %   Example for one stimulus:
    %       p = PlayerNIC4PythonSP16(); 
    %       stim = PulseTrainNIC4Python();
    %       p.play(stim)    
    %
    %   Example for multiple stimului:
    %       p = PlayerNIC4PythonSP16(); 
    %       stim1 = PulseTrainNIC4Python();
    %       stim2 = PulseTrainNIC4Python();
    %       p.play({stim1, stim2})        
    %
    %   See also PLAYERNIC4, FORMAT, BLEEP, PULSETRAINNIC4PYTHON
       
    properties
        go_live = 1; % 1 by default, virtual stimulation by using 0
        python_path = 'python.exe'; % "python.exe" by default
        show_terminal = 0; % option to show terminal for debugging (0 by
        % default)
        implant = 'CIC4'; % CIC4 or CIC3        
    end
    
    % These properties can't be modified by the user, to avoid false manipulation
    properties (SetAccess = protected)
        stimulus_format = @FormatNIC4Python;
        is_blocking = 0; % PlayerNIC4PythonSP16 doesn't block the matlab prompt when playing 
        nic4javapath = ''; % Not necessary for python
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
    
    % Different handles and hidden properties
    properties (Hidden, Access = protected)
        python_process = [];
        python_file_main = [];
        python_file_properties = [];
        start_bool = 0;
    end
    
    methods
        function obj = PlayerNIC4PythonSP16()
            % Constructor, inits the client at startup
            
            obj.init();

        end
        
        function play(obj, stimObj)
            
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
            
            obj.clean_files();
            
            obj.init();
            
            
            fid_stimulus = fopen(obj.python_file_main,'wt');
            
            % Print header
            fprintf(fid_stimulus, 'import imp\n');
            fprintf(fid_stimulus, 'from cochlear.nic import nic4\n\n');

            % Print sequences
            fprintf(fid_stimulus, 'seq_main = nic4.Sequence()\n\n');
            for idx = 1:n_stimuli
                fprintf(fid_stimulus, 'seq_%d = imp.load_source("seq_%d", "%s")\n', ...
                    idx, idx, strrep(stimObj{idx}.stimulus_file, '\', '\\')); 
                fprintf(fid_stimulus, 'seq_main.append(seq_%d.seq)\n\n', idx);
            end
            
            % Load properties and start streamer
            fprintf(fid_stimulus, 'props = imp.load_source("props", "%s")\n', ...
                strrep(obj.python_file_properties, '\', '\\')); 
            fprintf(fid_stimulus, 'streamer = nic4.Streamer(props.p)\n');
            fprintf(fid_stimulus, 'streamer.start()\n');
            fprintf(fid_stimulus, 'streamer.sendData(seq_main)\n');
            fprintf(fid_stimulus, 'streamer.waitUntilFinished()\n');
            fprintf(fid_stimulus, 'streamer.stop()\n');
            
            if obj.show_terminal
                fprintf(fid_stimulus, 'raw_input("Press Enter to continue...")\n');
            end
            
            fclose(fid_stimulus);            
            
            startInfo = System.Diagnostics.ProcessStartInfo(obj.python_path, ...
                sprintf(' %s', obj.python_file_main));            
            
            if ~obj.show_terminal
                startInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;  %// if you want it invisible
            end
            
            obj.python_process = System.Diagnostics.Process.Start(startInfo);
            
            obj.start_bool = 1;
            
        end
        
        function delete(obj)
            % Delete Player Object
            

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
            fprintf(fid_stimulus, 'from cochlear.nic import nic4\n\n');
            fprintf(fid_stimulus, 'def get_properties():\n');   
            
            % Create python properties object
            fprintf(fid_stimulus, '    p = nic4.Properties()\n'); 
            fprintf(fid_stimulus, '    p.add("platform", "%s")\n', obj.platform); 
            fprintf(fid_stimulus, '    p.add("implant", "%s")\n', obj.implant); 
            fprintf(fid_stimulus, '    p.add("mode", "%s")\n', obj.mode); 
            fprintf(fid_stimulus, '    p.add("flagged_electrodes", "%s")\n', obj.flagged_electrodes); 
            fprintf(fid_stimulus, '    p.add("min_pulse_width_us", "%s")\n', obj.min_pulse_width_us); 
            fprintf(fid_stimulus, '    p.add("auto_pufs", "off")\n'); 
            fprintf(fid_stimulus, '    p.add("latency_ms", "%s")\n', obj.latency_ms); 
            fprintf(fid_stimulus, '    p.add("c_levels_pulse_width_us", "%s")\n', obj.c_levels_pulse_width_us); 
            fprintf(fid_stimulus, '    p.add("c_levels", "%s")\n', obj.c_levels);             
            if obj.go_live
                fprintf(fid_stimulus, '    p.add("go_live", "on")\n'); 
            else
                fprintf(fid_stimulus, '    p.add("go_live", "off")\n'); 
            end 
            
            % Output the propertes
            fprintf(fid_stimulus, '    return p\n\n');
            fprintf(fid_stimulus, 'p = get_properties()\n');
            
            fclose(fid_stimulus);
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
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            % To avoid glitches when saving to .mat file, only modifiable
            % properties are saved (saveobj) in a structure and the object is
            % reconstructed when loading it.
            if isstruct(s)
                obj = PlayerNIC4PythonSP16();
                obj.go_live = s.go_live;
                obj.show_terminal = s.show_terminal;
                obj.implant = s.implant;
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
            s.implant = obj.implant;
            s.python_path = obj.python_path;
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