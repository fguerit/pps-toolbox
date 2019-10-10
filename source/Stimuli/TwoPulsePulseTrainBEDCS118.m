classdef TwoPulsePulseTrainBEDCS118 < FormatBEDCS118 & PulseTrain
    % TwoPulsePulseTrainBEDCS118 < FormatBEDCS118 & PulseTrain
    %
    %   Pulse train with two pulses following each other for BEDCS 1.18 (AB):
    %
    %       anodic-cathodic--gap--cathodic-anodic (or opposite polarity)
    %
    %   or
    %
    %       anodic-cathodic--gap--anodic-cathodic (or opposite polarity)
    %
    %   Note that for asymmetric pulses, the first pulse is low-high and
    %   the second pulse is high-low.
    %
    %   Because of pulse table limitations in BEDCS, not all combinations
    %   of rates and gaps are possible. The rate is fitted first, then the
    %   gap, which means the the actual gap value might differ largely.
    %
    %   To check the actual values, type: 
    %       stim.actual_rate_pps
    %       stim.actual_gap_us
    %
    %
    %   TwoPulsePulseTrainBEDCS118 Properties:
    %       phase_dur_us - Phase Duration (microseconds)
    %       interphase_dur_us - Interphase Gap (microseconds)    
    %       electrode_IDs - Electrodes on which the pulse train is played
    %       rate_pps - Rate of the pulse train (pps)
    %       level - 1*2 matrix with the levels of each pulse (in CU) 
    %       max_level - 1*2 matrix with user-defined maximum level (uA)    
    %       duration_s - Pulse train duration (seconds)
    %       exp_file - BEDCS experiment file used for stimulation
    %       level_mode - Upper Limit Level mode for BEDCS (Default = 1)
    %       ratio_asymmetry - Ratio between first and second phase amplitude
    %       polarity - 1*2 cell with polarity of first phase of each pulse
    %       gap_us - gap between the first and second pulse
    %
    %   TwoPulsePulseTrainBEDCS118 Properties (automatically calculated):
    %       actual_gap_us - Actual gap (rate_pps is fitted first, then gap_us)        
    %       actual_level - Actual levels (best fit dependent on the level
    %       range used, and asymmetry ratio)
    %       actual_phase_dur_us - Actual Phase Duration (best fit)     
    %       actual_rate_pps - Actual rate (best fit)    
    %
    %   TwoPulsePulseTrainBEDCS118 Methods:
    %       struct(obj) - struct(obj) outputs a structure with the most
    %       relevant properties and their values        
    %       get_level_dbua(obj) - level_dbua = obj.get_level_dbua()
    %       outputs the max actual level played in dB re 1 uA       
    %
    %   Example:
    %       p = PlayerBEDCS118();
    %       stim = TwoPulsePulseTrainBEDCS118();
    %       p.play(stim)
    %
    % See also FORMATBEDCS118, PLAYERBEDCS118, PULSETRAIN
    
    properties
        phase_dur_us = 43; % Phase Duration (microseconds)
        interphase_dur_us = 0; % Interphase Gap (microseconds)        
        electrode_IDs = [11 11]; % Electrodes on which the pulse train is played
        rate_pps = 100; % Rate of the pulse train (pps)
        level = [100 100]; % 1*2 matrix with the levels of each pulse (in uA) 
        duration_s = 0.4; % Pulse train duration (seconds)
        ratio_asymmetry = 1; % Ratio between first and second phase amplitude
        polarity = {'-', '-'}; % Polarity of first phase       
        gap_us = 200; % Gap between the two pulses
        max_level = [2040 2040]; % Maximum level for each pulse (in uA)
    end
    
    properties (SetAccess = protected)
        actual_gap_us = []; % Actual gap (rate_pps is fitted first, then gap)        
        actual_level = []; % Actual level (best fit dependent on the level
            % range used, and on the asymmetry ratio
        actual_phase_dur_us = []; % Actual Phase Duration (best fit)          
        actual_interphase_dur_us = []; % Actual IPG (best fit)        
        actual_rate_pps = []; % Actual rate (best fit)
        electrodogram = repmat(struct('t_s', [], 'amp_cu', [],...
            'pulses_start_times_s', []), 16, 1); % "electrodogram{el_ID}.t_s", ".amp_cu", ".pulse_start_times_s"            
    end    
    
    properties
        exp_file = ''; % BEDCS experiment file used for stimulation
        level_mode = 1; % Upper Limit Level mode for BEDCS (Default = 1)
    end
    
    properties (Hidden)
        compliance_limit_unit = 255; % to be defined
        charge_limit_nc = []; % to be defined
    end
    
    properties (SetAccess = protected, Hidden)
        variables_struct = {}; % Variables to be passed to BEDCS
    end
    
    properties (SetAccess = protected, GetAccess = public, Hidden)
        whole_duration_s = []; % Includes pre- and post-stimulus        
    end
    
    methods
        % Constructor, called when creating the object
        function obj = TwoPulsePulseTrainBEDCS118()
            
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
            %       stimObj = TwoPulsePulseTrainBEDCS118;
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
                'duration_s', obj.duration_s,...
                'ratio_asymmetry', obj.ratio_asymmetry, ...
                'polarity', [obj.polarity{1}, '', obj.polarity{2}], ...
                'gap_us', obj.gap_us, ...
                'actual_gap_us', obj.actual_gap_us, ...
                'actual_level', obj.actual_level, ...
                'actual_phase_dur_us', obj.actual_phase_dur_us, ...
                'actual_interphase_dur_us', obj.actual_interphase_dur_us, ...                
                'actual_rate_pps', obj.actual_rate_pps);
        end       
        
        function level_dbua = get_level_dbua(obj)
            % GET_LEVEL_DBUA
            %
            %   level_dbua = obj.get_level_dbua()
            %   outputs the max actual level played in dB re 1 uA
            %
            
            level_dbua = 20*log10(obj.actual_level);
        end           
    end
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            if isstruct(s)
                newObj = TwoPulsePulseTrainBEDCS118();
                newObj.phase_dur_us = s.phase_dur_us;
                newObj.interphase_dur_us = s.interphase_dur_us;
                newObj.electrode_IDs = s.electrode_IDs;
                newObj.rate_pps = s.rate_pps;
                newObj.level = s.level;
                newObj.duration_s = s.duration_s;
                newObj.ratio_asymmetry = s.ratio_asymmetry;
                newObj.polarity = s.polarity;
                newObj.max_level = s.max_level;
                newObj.gap_us = s.gap_us;
                obj = newObj;
            else
                obj = s;
            end
        end
    end
    
    methods (Hidden)
        
        function s = saveobj(obj)
            s.phase_dur_us = obj.phase_dur_us;
            s.interphase_dur_us = obj.interphase_dur_us;
            s.electrode_IDs = obj.electrode_IDs;
            s.rate_pps = obj.rate_pps;
            s.level = obj.level;
            s.duration_s = obj.duration_s;
            s.ratio_asymmetry = obj.ratio_asymmetry;
            s.polarity = obj.polarity;
            s.max_level = obj.max_level;
            s.gap_us = obj.gap_us;
        end
        
        function init(obj)
            % obj.init() prepares the "variables_struct" to be sent to
            % BEDCS
            
            [current_path, ~, ~] = fileparts(mfilename('fullpath'));
            obj.exp_file = [current_path filesep 'BEDCS_doublePT.bExp'];            
            
            % Check that the pulse rate is achievable
            if obj.rate_pps > (1000000/((obj.ratio_asymmetry + 1)*obj.phase_dur_us*2 ...
                    + obj.gap_us + 2*obj.interphase_dur_us))
                error(['%d pps can not be achieved with a phase duration of %.1f us,'...
                    ' an IPG of %.1f us, an asymmetry ratio of %d\n and a gap between the two pulses of %.1f us\n'],...
                    obj.rate_pps, obj.phase_dur_us, obj.interphase_dur_us, obj.ratio_asymmetry, obj.gap_us)
            end
                
            % Set duration
            obj.whole_duration_s = obj.duration_s;
            
            maximum_level = max(obj.level);
            
            % Set upper limit of required range
            if maximum_level < 256
                upper_limit = 255;
            elseif maximum_level < 511
                upper_limit = 510;
            elseif maximum_level < 1021
                upper_limit = 1020;
            else
                upper_limit = 2040;
            end
            
            % Round level to nearest multiple of 1, 2, 4 or 8 (depending on upper limit)
            % If asymmetry ratio is 8 or above, the smallest step has to be
            % adjusted (smallest resolution for low/long phase is 0.25 in range 1)
            correction_asymmetry = max(1, obj.ratio_asymmetry/4);
            obj.actual_level = round(obj.level/(correction_asymmetry*upper_limit/255))...
                * (correction_asymmetry*upper_limit/255);             
            
            % Round phase and gap duration to nearest multiple of 10.776
            obj.actual_phase_dur_us = 10.776*round(obj.phase_dur_us/10.776);
            obj.actual_interphase_dur_us = 10.776*round(obj.interphase_dur_us/10.776);
            gap_us = 10.776*round(obj.gap_us/10.776);
            
            % Derive number of steps per phase
            number_phase_steps = obj.actual_phase_dur_us/10.776;
            number_IPG_steps = obj.actual_interphase_dur_us/10.776;            
            number_gap_steps = gap_us/10.776;
            
            % Check that the IPG and phase duration is achievable in one
            % pulse step
            if (2*number_phase_steps*(obj.ratio_asymmetry + 1) + 2*number_IPG_steps) >= 256
                error('IPG and phase duration combined are too long to fit in one buffer.\n')
            end
            
            % Step is DSPPeriodic(num_pulses, level*concat(1,zeros(num_train_zeros)))
            possible_padded_pulse_dur_us = 10.776*(2*number_phase_steps*(obj.ratio_asymmetry+1)...
                + 2*number_IPG_steps...
                +(0:(256-2*number_phase_steps*(obj.ratio_asymmetry + 1) - 2*number_IPG_steps)));
            
            required_period_us = 1000000./obj.rate_pps;
            ratios = required_period_us./possible_padded_pulse_dur_us;
            integers = round(ratios);
            residuals = abs(ratios-integers);
            [~,best_padded_pulse_index] = min(residuals);
            
          
            % Calculate the corresponding new values
            num_pulse_zeros = best_padded_pulse_index-1;
            num_train_zeros = integers(best_padded_pulse_index)-1;
            obj.actual_rate_pps = 1000000/(integers(best_padded_pulse_index)*...
                possible_padded_pulse_dur_us(best_padded_pulse_index));
            num_pulses = round(obj.duration_s*obj.actual_rate_pps);
            
            % Try to fit the second pulse location
            length_pulse1 = number_phase_steps*(obj.ratio_asymmetry+1) + number_IPG_steps;
            length_pulse_bedcs = num_pulse_zeros(1) + 2*length_pulse1;
            possible_start_steps_pulse2 = (length_pulse1+1):(length_pulse_bedcs-length_pulse1);
            possible_gaps_us = zeros(num_train_zeros+1, length(possible_start_steps_pulse2));
            for idx = 1:num_train_zeros+1
                possible_gaps_us(idx,:) = 10.776*((idx-1)*length_pulse_bedcs + possible_start_steps_pulse2 - (length_pulse1+1));
            end
            diff_matrix = abs(possible_gaps_us - obj.gap_us);
            [r, c]=find(diff_matrix==min(min(diff_matrix)));
            obj.actual_gap_us = possible_gaps_us(r,c);
            num_train_gap = r - 1;
            num_pulse_gap = possible_start_steps_pulse2(c)-(length_pulse1+1);

            % Set polarity of second phase
            switch obj.polarity{1}
                case '+'
                    polarity_second_phase = '-';
                case '-'
                    polarity_second_phase = '+';
            end      
            switch obj.polarity{2}
                case '+'
                    polarity_fourth_phase = '-';
                case '-'
                    polarity_fourth_phase = '+';
            end             
            
            pulse1 = sprintf('concat(%s(1/%d)*ones(%d*%d),0*ones(%d),%s1*ones(%d),0*ones(%d))', ...
                obj.polarity{1}, obj.ratio_asymmetry, number_phase_steps, ...
                obj.ratio_asymmetry, number_IPG_steps,...
                polarity_second_phase, number_phase_steps, ...
                num_pulse_zeros(1)+length_pulse1);
            
            pulse2 = sprintf('concat(0*ones(%d),%s1*ones(%d),0*ones(%d),%s(1/%d)*ones(%d*%d),0*ones(%d))', ...
                length_pulse1+num_pulse_gap, obj.polarity{2}, number_phase_steps, ...
                number_IPG_steps,...
                polarity_fourth_phase, obj.ratio_asymmetry, number_phase_steps, ...
                obj.ratio_asymmetry, num_pulse_zeros(1)-(num_pulse_gap));
            
            obj.variables_struct = struct('upper_limit', upper_limit,...
                'num_pulses', num_pulses,...
                'level1', obj.level(1),...
                'level2', obj.level(2),...
                'num_train_zeros', num_train_zeros,...
                'num_train_gap', num_train_gap, ...
                'pulse1', pulse1,...
                'pulse2', pulse2,...
                'electrode1', obj.electrode_IDs(1), ...
                'electrode2', obj.electrode_IDs(2));
        end
        
        function plot(obj)
        % Plots the electrodogram of the stimulus
        
        error('Plotting not implemented yet for this stimulus')
        
        end        
    end
    
    methods (Access = protected)
        function check_level(obj)
            % CHECK_LEVEL(OBJ) returns an error if level is superior than
            % user-defined max level
            
            if any(obj.level > obj.max_level)
                error('levels (%d and %d uA) > user-defined maximum levels (%d and %d uA)',...
                    obj.level, obj.max_level)
            end
        end
    end    
    
    % obj.set methods. Each time a property is updated, initialization
    % should be redone
    methods
        
        function set.polarity(obj,value)

            % Settings
            property_class = {'cell'};
            property_attributes = {'nonempty', '2d', 'numel', 2};
            string_attributes = {'-', '+'};
            prop_name = 'polarity';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes); 
            for idx = 1:2
                validatestring(value{idx}, string_attributes);
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
        
        function set.ratio_asymmetry(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', 'integer'};
            string_attributes = {'1', '2', '4', '8', '16', '32'};
            prop_name = 'ratio_asymmetry';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes);            
            validatestring(num2str(value), string_attributes);
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
        
        function set.phase_dur_us(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>=', 10.776, '<', 9999};
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
        
        function set.interphase_dur_us(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>=', 0, '<', 9999};
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
        
        function set.electrode_IDs(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'row', 'nonempty', 'numel', 2, 'integer', '>=', 1, '<=', 16};
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
            property_attributes = {'row', 'nonempty', 'numel', 2, 'integer', '>=', 0, '<=', 2040};
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
            property_attributes = {'row', 'nonempty', 'numel', 2, 'integer', '>=', 0, '<=', 2040};
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
        
        function set.gap_us(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>', 0};
            prop_name = 'gap_us';
            
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
    end
    
end