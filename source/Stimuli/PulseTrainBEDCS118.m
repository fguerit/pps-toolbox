classdef PulseTrainBEDCS118 < FormatBEDCS118 & PulseTrain
    % PulseTrainBEDCS118 < FormatBEDCS118 & PulseTrain
    %
    %   Single electrode pulse train class for AB devices and BEDCS 1.18.
    %
    %   PulseTrainBEDCS118 Properties:
    %       phase_dur_us - Phase Duration (microseconds)
    %       interphase_dur_us - Interphase Gap (microseconds)
    %       electrode_IDs - Electrodes on which the pulse train is played
    %       rate_pps - Rate of the pulse train (pps)
    %       level - Level (uA)
    %       max_level - User-defined maximum level (uA)
    %       duration_s - Pulse train duration (seconds)
    %       exp_file - BEDCS experiment file used for stimulation
    %       level_mode - Upper Limit Level mode for BEDCS (Default = 1)
    %       ratio_asymmetry - Ratio between first and second phase amplitude
    %       polarity - Polarity of first phase  
    %
    %   PulseTrainBEDCS118 Properties (automatically calculated):
    %       actual_level - Actual level (best fit dependent on the level
    %       range used, and asymmetry ratio)
    %       actual_phase_dur_us - Actual Phase Duration (best fit)     
    %       actual_interphase_dur_us - Actual IPG (best fit)
    %       actual_rate_pps - Actual rate (best fit)
    %
    %   PulseTrainBEDCS118 Methods:
    %       struct(obj) - struct(obj) outputs a structure with the most
    %       relevant properties and their values        
    %       get_level_dbua(obj) - level_dbua = obj.get_level_dbua()
    %       outputs the max actual level played in dB re 1 uA       
    %
    %   Example:
    %       p = PlayerBEDCS118();
    %       stim = PulseTrainBEDCS118();
    %       p.play(stim)
    %
    % See also FORMATBEDCS118, PLAYERBEDCS118, PULSETRAIN
    
    properties
        phase_dur_us = 43; % Phase Duration (microseconds)
        interphase_dur_us = 0; % Interphase Gap (microseconds)
        electrode_IDs = 11; % Electrodes on which the pulse train is played
        rate_pps = 442; % Rate of the pulse train (pps)
        level = 100; % Level (Device Units)
        duration_s = 0.4; % Pulse train duration (seconds)
        ratio_asymmetry = 1; % Ratio between first and second phase amplitude
        polarity = '-'; % Polarity of first phase
        max_level = 2040;
    end
    
    properties (SetAccess = protected)
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
        function obj = PulseTrainBEDCS118()
            
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
            %       stimObj = PulseTrainBEDCS118;
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
                'polarity', obj.polarity, ...
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
                newObj = PulseTrainBEDCS118();
                newObj.phase_dur_us = s.phase_dur_us;
                newObj.interphase_dur_us = s.interphase_dur_us;
                newObj.electrode_IDs = s.electrode_IDs;
                newObj.rate_pps = s.rate_pps;
                newObj.level = s.level;
                newObj.duration_s = s.duration_s;
                newObj.ratio_asymmetry = s.ratio_asymmetry;
                newObj.polarity = s.polarity;
                newObj.max_level = s.max_level;
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
        end
        
        function init(obj)
            % obj.init() prepares the "variables_struct" to be sent to
            % BEDCS
            
            [current_path, ~, ~] = fileparts(mfilename('fullpath'));
            obj.exp_file = [current_path filesep 'BEDCS_singlePT.bExp'];            
            
            % Check that the pulse rate is achievable
            if obj.rate_pps > (1000000/((obj.ratio_asymmetry + 1)*obj.phase_dur_us + obj.interphase_dur_us))
                error(['%d pps can not be achieved with a phase duration of %.1f us, '...
                    'an IPG of %.1f us and an asymmetry ratio of %d\n'],...
                    obj.rate_pps, obj.phase_dur_us, obj.interphase_dur_us, obj.ratio_asymmetry)
            end
                
            % Set duration
            obj.whole_duration_s = obj.duration_s;
            
            % Set upper limit of required range
            if obj.level < 256
                upper_limit = 255;
            elseif obj.level < 511
                upper_limit = 510;
            elseif obj.level < 1021
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
            
            % Round phase duration and IPG to nearest multiple of 10.776
            obj.actual_phase_dur_us = 10.776*round(obj.phase_dur_us/10.776);
            obj.actual_interphase_dur_us = 10.776*round(obj.interphase_dur_us/10.776);
            
            % Derive number of steps per phase
            number_phase_steps = obj.actual_phase_dur_us/10.776;
            number_IPG_steps = obj.actual_interphase_dur_us/10.776;
            
            % Step is DSPPeriodic(num_pulses, level*concat(1,zeros(num_train_zeros)))
            possible_padded_pulse_dur_us = 10.776*(number_phase_steps*(obj.ratio_asymmetry+1)...
                + number_IPG_steps...
                +(0:(256-number_phase_steps*(obj.ratio_asymmetry + 1)-number_IPG_steps)));
            
            required_period_us = 1000000./obj.rate_pps;
            ratios = required_period_us./possible_padded_pulse_dur_us;
            integers = round(ratios);
            residuals = abs(ratios-integers);
            [~,best_padded_pulse_index] = min(residuals);
            
            % Set polarity of second phase
            switch obj.polarity
                case '+'
                    polarity2 = '-';
                case '-'
                    polarity2 = '+';
            end            
            
            % Calculate the corresponding new values
            num_pulse_zeros = best_padded_pulse_index-1;
            num_train_zeros = integers(best_padded_pulse_index)-1;
            obj.actual_rate_pps = 1000000/(integers(best_padded_pulse_index)*possible_padded_pulse_dur_us(best_padded_pulse_index));
            num_pulses = round(obj.duration_s*obj.actual_rate_pps);
            
            pulse = sprintf('concat(%s1*ones(%d),0*ones(%d),%s(1/%d)*ones(%d*%d),0*ones(%d))', ...
                obj.polarity, number_phase_steps, ...
                number_IPG_steps, ...
                polarity2, obj.ratio_asymmetry, obj.ratio_asymmetry, number_phase_steps, ...
                num_pulse_zeros(1));
            
            obj.variables_struct = struct('upper_limit', upper_limit,...
                'num_pulses', num_pulses,...
                'level', obj.actual_level,...
                'num_train_zeros', num_train_zeros,...
                'pulse', pulse,...
                'electrode', obj.electrode_IDs);
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
            
            if obj.level > obj.max_level
                error('level (%d uA) > user-defined maximum level (%d uA)', ...
                    obj.level, obj.max_level)
            end
        end
    end
    
    % obj.set methods. Each time a property is updated, initialization
    % should be redone
    methods
        
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
            property_attributes = {'scalar', 'integer', '>=', 1, '<=', 16};
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
            property_attributes = {'scalar', 'integer', '>=', 0, '<=', 2040};
            prop_name = 'level';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes)            
            tmp_value = obj.(prop_name);
            try
                obj.(prop_name) = value;
                obj.check_level();
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
            property_attributes = {'scalar', 'integer', '>=', 0, ...
                '<=', 2040};
            prop_name = 'max_level';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes)            
            tmp_value = obj.(prop_name);
            try
                obj.(prop_name) = value;
                obj.check_level();
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