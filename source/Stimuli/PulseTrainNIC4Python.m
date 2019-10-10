classdef PulseTrainNIC4Python < FormatNIC4Python & PulseTrain
    % PulseTrainNIC4Python < FormatNIC4Python & PulseTrain
    %
    %   Pulse train class for Cochlear devices using NIC4/Python interface:
    %
    %   PulseTrainNIC4Python Properties (PulseTrain class):
    %       phase_dur_us - Phase Duration (microseconds)
    %       electrode_IDs - Electrodes on which the pulse train is played
    %       rate_pps - Rate of the pulse train (pps)
    %       level - Level (Device Units)
    %       max_level - User-defined maximum level (Device Units)    
    %       duration_s - Pulse train duration (seconds)
    %
    %   PulseTrainNIC4Python Properties (FormatCochlear class):
    %       modulator - [t_s, amp] vector that modulates the pulse train    
    %       interphase_dur_us - Interphase gap duration (microseconds)
    %       polarity - first phase polarity
    %       pulse_type - Biphasic or Quadraphasic ("B", "Q")
    %
    %   PulseTrainNIC4Python Methods:
    %       struct(obj) - struct(obj) outputs a structure with the most
    %       relevant properties and their values
    %       get_level_dbua(obj) - level_dbua = obj.get_level_dbua()
    %       outputs the max level played in dB re 1 uA
    %       plot(obj) - Function to plot the electrodogram
    %
    %   Example:
    %       p = PlayerPythonRFGenXS(); 
    %       powerUp = PowerUpPyCochlear();
    %       stim = PulseTrainNIC4Python();
    %       p.play({powerUp, stim, powerUp})
    %
    %   Modulation and plotting:
    %       fs = 10000;
    %       t = 0:1/fs:stim.duration_s;
    %       noise = rand(size(t)); % uniform distribution between 0 and 1
    %       stim.modulator = [t', noise'];
    %       plot(stim)
    %
    %
    % See also FORMATNIC4PYTHON, PLAYERNIC4PYTHONRFGENXS, PULSETRAIN
    
    properties
        phase_dur_us = 43; % Phase Duration (microseconds)
        electrode_IDs = 11; % Electrodes on which the pulse train is played
        rate_pps = 442; % Rate of the pulse train (pps)
        level = 100; % Level (Device Units)
        duration_s = 0.4; % Pulse train duration (seconds)
        max_level = 255; % User-defined maximum level (Device Units)        
    end
    
    properties
        modulator = []; % [t_s, amp] vector that modulates the pulse train
        interphase_dur_us = 8; % Interphase gap duration (microseconds)
        polarity = '-'; % first phase polarity
        pulse_type = 'B'; % Biphasic or Quadraphasic ("B", "Q")
    end
    
    properties (Hidden)
        compliance_limit_unit = 255; % to be defined
        charge_limit_nc = []; % to be defined
    end
    
    properties (SetAccess = protected)
        stimulus_file = ''; % parameter file used by the player
        electrodogram = repmat(struct('t_s', [], 'amp_cu', [],...
            'pulses_start_times_s', []), 22, 1); % "electrodogram{el_ID}.t_s", ".amp_cu", ".pulse_start_times_s" 
    end
    
    properties (SetAccess = protected, GetAccess = public, Hidden)
        whole_duration_s = []; % Includes pre- and post-stimulus
    end
    
    methods
        % Constructor, called when creating the object
        function obj = PulseTrainNIC4Python()
            
            % Check for max level
            obj.check_level();
            
            % Init everything
            obj.init();
            
        end
        
        function structOut = struct(obj)
            % STRUCT outputs a structure with the most
            % relevant properties and their values
            %
            %   Example:
            %       stimObj = PulseTrainNIC4Python;
            %       s = struct(stimObj)
            %
            %   Or:
            %       s = stimObj.struct
            %
            
            structOut = struct('rate_pps', obj.rate_pps, ...
                'level', obj.level, ...
                'electrode_IDs', obj.electrode_IDs, ...
                'phase_dur_us', obj.phase_dur_us ,...
                'interphase_dur_us', obj.interphase_dur_us, ...
                'polarity', obj.polarity, ...
                'pulse_type', obj.pulse_type, ...
                'duration_s', obj.duration_s);
        end
        
        function level_dbua = get_level_dbua(obj)
            % GET_LEVEL_DBUA
            %
            %   level_dbua = obj.get_level_dbua()
            %   outputs the max level played in dB re 1 uA
            %
            
            level_dbua = 20*log10(17.5) + 40*obj.level/255;
        end
        
        function delete(obj)
            % Delete PulseTrainNIC4Python Object
            
            if ~isempty(obj.stimulus_file)
                delete([obj.stimulus_file '*'])
            end
        end        
    end
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            % To avoid glitches when saving to .mat file, only modifiable
            % properties are saved (saveobj) in a structure and the object is
            % reconstructed when loading it.
            if isstruct(s)
                newObj = PulseTrainNIC4Python();
                newObj.phase_dur_us = s.phase_dur_us;
                newObj.interphase_dur_us = s.interphase_dur_us;
                newObj.electrode_IDs = s.electrode_IDs;
                newObj.rate_pps = s.rate_pps;
                newObj.level = s.level;
                newObj.duration_s = s.duration_s;                
                newObj.polarity = s.polarity;
                newObj.max_level = s.max_level;
                
                % modulator and pulse shape should be done last, 
                % as it might require more
                % time to write to disk
                newObj.pulse_type = s.pulse_type;
                newObj.modulator = s.modulator;
                obj = newObj;
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
            s.phase_dur_us = obj.phase_dur_us;
            s.interphase_dur_us = obj.interphase_dur_us;
            s.electrode_IDs = obj.electrode_IDs;
            s.rate_pps = obj.rate_pps;
            s.level = obj.level;
            s.duration_s = obj.duration_s;
            s.modulator = obj.modulator;
            s.polarity = obj.polarity;
            s.pulse_type = obj.pulse_type;
            s.max_level = obj.max_level;
        end
        
        function init(obj)
            % obj.init() prepares the python file to be read by the player
            
            
            % file name is written with round(now*1e8) at the beginning to
            % make sure one can create two stimuli in a very short time
            % with different names
            [current_path, ~, ~] = fileparts(mfilename('fullpath'));
            if ~exist(obj.stimulus_file, 'file')
                obj.stimulus_file = [current_path filesep ...
                    sprintf('%d', round(now*1e12)) '_cochlear_stimulus_file.py'];
            end
            
            
            % For quadraphsic pulses, two pulse or collated, with opposite
            % starting polarity
            if strcmp(obj.pulse_type, 'Q')
                quadra_bool = 1;
            else
                quadra_bool = 0;
            end
            
            % Check that the stimulus pulse rate is achievable
            min_inter_stimulus_gap_us = 7.8;
            if obj.rate_pps > (1000000/((quadra_bool+1)*(2*obj.phase_dur_us...
                    + obj.interphase_dur_us + min_inter_stimulus_gap_us)))
                error('%d pps can not be achieved with a phase and interphase duration of %.1f and %.1f us\n',...
                    obj.rate_pps, obj.phase_dur_us, obj.interphase_dur_us)
            end
            
            fid_stimulus = fopen(obj.stimulus_file,'wt');
                        
            % Header
            fprintf(fid_stimulus, 'from cochlear.nic import nic4\n\n');
            fprintf(fid_stimulus, 'def get_stimulus_seq():\n');
            
            
            % Prepare stimulus sequence
            period_us = round(1000000/obj.rate_pps);
            num_pulses = round(obj.duration_s/(period_us/1000000));
            
            % Create electrodogram (for visualisation only)
            obj.electrodogram(obj.electrode_IDs).pulses_start_times_s = ...
                (0:period_us:(num_pulses-1)*period_us)/1000000;                        
            if quadra_bool
                t0 = 0;
                t1 = t0 + obj.phase_dur_us;
                t2 = t1 + obj.interphase_dur_us;
                t3 = t2 + obj.phase_dur_us;
                t4 = t3 + min_inter_stimulus_gap_us;
                t5 = t4 + obj.phase_dur_us;
                t6 = t5 + obj.interphase_dur_us;
                t7 = t6 + obj.phase_dur_us;
                t8 = t7 + min_inter_stimulus_gap_us;
                t_one_pulse = [t0 t0 t1 t1 t2 t2 t3 t3 ...
                    t4 t4 t5 t5 t6 t6 t7 t7 t8]/1000000;
                amp_one_pulse = [0 -1 -1 0 0 1 1 0 0 1 1 0 0 -1 -1 0 0]* obj.level;
            else
                t0 = 0;
                t1 = t0 + obj.phase_dur_us;
                t2 = t1 + obj.interphase_dur_us;
                t3 = t2 + obj.phase_dur_us;
                t4 = t3 + min_inter_stimulus_gap_us;
                t_one_pulse = [t0 t0 t1 t1 t2 t2 t3 t3 t4]/1000000;
                amp_one_pulse = [0 -1 -1 0 0 1 1 0 0] * obj.level;
            end
            if strcmp(obj.polarity, '+')
                amp_one_pulse = -1*amp_one_pulse;
            end
            obj.electrodogram(obj.electrode_IDs).t_s = ...
                zeros(1, length(t_one_pulse)*num_pulses);
            for idx = 1:num_pulses
                idx_pulse_low = (idx-1)*length(t_one_pulse) + 1;
                idx_pulse_high = idx_pulse_low + length(t_one_pulse) - 1;
                obj.electrodogram(obj.electrode_IDs).t_s(idx_pulse_low:idx_pulse_high) = ...
                    t_one_pulse + obj.electrodogram(obj.electrode_IDs).pulses_start_times_s(idx);
            end
            obj.electrodogram(obj.electrode_IDs).amp_cu = ...
                repmat(amp_one_pulse, 1, num_pulses);
            
            % If modulated, the level for each pulse has to be defined
            if ~isempty(obj.modulator)
                level_modulator = interp1(obj.modulator(:, 1), ...
                    obj.modulator(:, 2), ...
                    obj.electrodogram(obj.electrode_IDs).pulses_start_times_s, ...
                    'nearest');
                % If no level is defined, set to 0
                level_modulator(isnan(level_modulator)) = 0;
                n_levels = num_pulses;
                mod_bool = 1;
                for idx = 1:num_pulses
                    idx_pulse_low = (idx-1)*length(amp_one_pulse) + 1;
                    idx_pulse_high = idx_pulse_low + length(amp_one_pulse) - 1;
                    obj.electrodogram(obj.electrode_IDs).amp_cu(idx_pulse_low:idx_pulse_high) = ...
                        amp_one_pulse*level_modulator(idx);
                end
            else % Full scale, only one level
                mod_bool = 0;
                n_levels = 1;
                level_modulator = 1;
            end
            
            
            % Print pulses in the python file
            if quadra_bool % concatenates two pulses
                period_first_pulse_us = 2*obj.phase_dur_us + obj.interphase_dur_us...
                    + min_inter_stimulus_gap_us;
                period_second_pulse_us = period_us - period_first_pulse_us;

                
                for idx_levels = 1:n_levels
                    switch obj.polarity
                        case '-'
                            fprintf(fid_stimulus, ...
                                '    stim_type_first_pulse_%d = nic4.BiphasicStimulus(%d, %d, %d, %.1f, %.1f, %.1f)\n', ...
                                idx_levels, obj.electrode_IDs, -3, ...
                                round(obj.level*level_modulator(idx_levels)),...
                                obj.phase_dur_us, obj.interphase_dur_us, ...
                                period_first_pulse_us);
                            
                            fprintf(fid_stimulus, ...
                                '    stim_type_second_pulse_%d = nic4.BiphasicStimulus(%d, %d, %d, %.1f, %.1f, %.1f)\n', ...
                                idx_levels, -3, obj.electrode_IDs, ...
                                round(obj.level*level_modulator(idx_levels)),...
                                obj.phase_dur_us, obj.interphase_dur_us, period_second_pulse_us);
                            
                        case '+'
                            fprintf(fid_stimulus, ...
                                '    stim_type_first_pulse_%d = nic4.BiphasicStimulus(%d, %d, %d, %.1f, %.1f, %.1f)\n', ...
                                idx_levels, -3, obj.electrode_IDs, ...
                                round(obj.level*level_modulator(idx_levels)),...
                                obj.phase_dur_us, obj.interphase_dur_us, period_first_pulse_us);
                            
                            fprintf(fid_stimulus, ...
                                '    stim_type_second_pulse_%d = nic4.BiphasicStimulus(%d, %d, %d, %.1f, %.1f, %.1f)\n', ...
                                idx_levels, obj.electrode_IDs, -3, ...
                                round(obj.level*level_modulator(idx_levels)),...
                                obj.phase_dur_us, obj.interphase_dur_us, ...
                                period_second_pulse_us);
                    end
                    
                    
                    fprintf(fid_stimulus, ...
                        '    stim_command_first_pulse_%d = nic4.StimulusCommand(stim_type_first_pulse_%d)\n', ...
                        idx_levels, idx_levels);
                    fprintf(fid_stimulus, ...
                        '    stim_command_second_pulse_%d = nic4.StimulusCommand(stim_type_second_pulse_%d)\n', ...
                        idx_levels, idx_levels);
                    
                end
                fprintf(fid_stimulus, ...
                    '    seq = nic4.Sequence()\n');                
                
                for idx = 1:num_pulses
                    if mod_bool
                        fprintf(fid_stimulus, ...
                            '    seq.append(stim_command_first_pulse_%d)\n', ...
                            idx);
                        fprintf(fid_stimulus, ...
                            '    seq.append(stim_command_second_pulse_%d)\n', ...
                            idx);                        
                    else
                        fprintf(fid_stimulus, ...
                            '    seq.append(stim_command_first_pulse_1)\n');
                        fprintf(fid_stimulus, ...
                            '    seq.append(stim_command_second_pulse_1)\n');
                    end
                end
            else %% Just use one pulse
                
                for idx_levels = 1:n_levels
                    switch obj.polarity
                        case '-'
                            fprintf(fid_stimulus, ...
                                '    stim_type_%d = nic4.BiphasicStimulus(%d, %d, %d, %.1f, %.1f, %.1f)\n', ...
                                idx_levels, obj.electrode_IDs, -3, ...
                                round(obj.level*level_modulator(idx_levels)),...
                                obj.phase_dur_us, obj.interphase_dur_us, ...
                                period_us);
                            
                        case '+'
                            fprintf(fid_stimulus, ...
                                '    stim_type_%d = nic4.BiphasicStimulus(%d, %d, %d, %.1f, %.1f, %.1f)\n', ...
                                idx_levels, -3, obj.electrode_IDs, ...
                                round(obj.level*level_modulator(idx_levels)),...
                                obj.phase_dur_us, obj.interphase_dur_us, ...
                                period_us);
                    end
                    
                    fprintf(fid_stimulus, ...
                        '    stim_command_%d = nic4.StimulusCommand(stim_type_%d)\n', ...
                        idx_levels, idx_levels);
                end
                if mod_bool
                    fprintf(fid_stimulus, ...
                        '    seq = nic4.Sequence()\n');
                    for idx = 1:num_pulses
                        fprintf(fid_stimulus, ...
                            '    seq.append(stim_command_%d)\n', idx);
                    end
                else
                    fprintf(fid_stimulus, ...
                        '    seq = nic4.Sequence(%d)\n', num_pulses);
                    fprintf(fid_stimulus, ...
                        '    seq.append(stim_command_1)\n');
                end
            end
            
            % Output the sequence
            fprintf(fid_stimulus, '    return seq\n\n');
            fprintf(fid_stimulus, 'seq = get_stimulus_seq()\n');
            
            fclose(fid_stimulus);
            
            % Set whole duration
            obj.whole_duration_s = obj.duration_s;
        end
        
        function plot(obj)
            % Function to plot the electrodogram
            
            el_ID = obj.electrode_IDs;
            
            figure
            plot(obj.electrodogram(el_ID).t_s, obj.electrodogram(el_ID).amp_cu)
            
            xlim([-0.1 1.1]*obj.whole_duration_s)
            ylim([-270 270])
            
            set(gca, 'ytick', -250:50:250)
            set(gca, 'fontsize', 12)
            xlabel('Time (s)', 'fontsize', 14)
            ylabel('Amplitude (cu)', 'fontsize', 14)
            title(sprintf('Electrode %d', el_ID), 'fontsize', 16)
        end
    end
    
    methods (Access = protected)
        function check_level(obj)
            % CHECK_LEVEL(OBJ) returns an error if level is superior than
            % user-defined max level
            
            if obj.level > obj.max_level
                error('level (%d CU) > user-defined maximum level (%d CU)',...
                    obj.level, obj.max_level)
            end
        end
    end    
    
    % obj.set methods. Each time a property is updated, initialization
    % should be redone
    methods
        function set.phase_dur_us(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>=', 20, '<', 429.4};
            prop_name = 'phase_dur_us';
            
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
        
        function set.electrode_IDs(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', 'integer', '>=', 1, '<=', 22};
            prop_name = 'electrode_IDs';
            
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
        
        function set.rate_pps(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>', 0};
            prop_name = 'rate_pps';
            
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
        
        function set.level(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', 'integer', '>=', 0, '<=', 255};
            prop_name = 'level';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes)            
            tmp_value = obj.(prop_name);
            try
                obj.(prop_name) = value;
                obj.check_level;
                obj.init;
            catch error_msg
                obj.(prop_name) = tmp_value;
                obj.init;
                warning('%s could not be changed, and was kept to its previous value.\n\nCf. error message below for more info.', prop_name)
                rethrow(error_msg)
            end
        end
        
        function set.max_level(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', 'integer', '>=', 0, '<=', 255};
            prop_name = 'max_level';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes)            
            tmp_value = obj.(prop_name);
            try
                obj.(prop_name) = value;
                obj.check_level;
                obj.init;
            catch error_msg
                obj.(prop_name) = tmp_value;
                obj.init;
                warning('%s could not be changed, and was kept to its previous value.\n\nCf. error message below for more info.', prop_name)
                rethrow(error_msg)
            end
        end        
        
        function set.duration_s(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>', 0};
            prop_name = 'duration_s';
            
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
        
        function set.interphase_dur_us(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>=', 5.6, '<', 56.6};
            prop_name = 'interphase_dur_us';
            
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
        
        function set.polarity(obj,value)
            
            % Settings
            property_class = {'char'};
            property_attributes = {'nonempty'};
            string_attributes = {'-', '+'};
            prop_name = 'polarity';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes);            
            validatestring(value, string_attributes);
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
        
        function set.pulse_type(obj,value)
            
            % Settings
            property_class = {'char'};
            property_attributes = {'nonempty'};
            string_attributes = {'B', 'Q'};
            prop_name = 'pulse_type';
            
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
        
        function set.modulator(obj, value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'nonempty', '2d', 'ncols', 2, '>=', 0};
            property_attributes_col1 = {'>=', 0, 'increasing'};
            property_attributes_col2 = {'>=', 0, '<=', 1};
            prop_name = 'modulator';
            
            % Try initialization
            if ~isempty(value)
                validateattributes(value, property_class, property_attributes)            
                validateattributes(value(:, 1), property_class, property_attributes_col1)            
                validateattributes(value(:, 2), property_class, property_attributes_col2)    
                if isrow(value)
                    error('Input must have at least 2 rows')
                end
            else
                value = [];
            end
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