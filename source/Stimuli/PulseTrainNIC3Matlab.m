classdef PulseTrainNIC3Matlab < FormatNIC3Matlab & PulseTrain
    % PulseTrainNIC3Matlab < FormatNIC3Matlab & PulseTrain
    %
    %   Simple pulse train class for Cochlear devices using NIC3/Matlab interface:
    %   prestimulus -- stimulus -- prestimulus
    %
    %   PulseTrainNIC3Matlab Properties (PulseTrain class):
    %       phase_dur_us - Phase Duration (microseconds)
    %       electrode_IDs - Electrodes on which the pulse train is played
    %       rate_pps - Rate of the pulse train (pps)
    %       level - Level (Device Units)
    %       max_level - User-defined maximum level (Device Units)
    %       duration_s - Pulse train duration (seconds)
    %
    %   PulseTrainNIC3Matlab Properties (FormatCochlear class):
    %       interphase_dur_us - Interphase gap duration (microseconds)
    %       pre_stim_dur_s - Pre-stimulus duration, makes sure the
    %       signal is played properly
    %       pre_stim_rate_pps - Pre-stimulus rate (pps)
    %       pre_stim_level - Pre-stimulus Level (Device Units)
    %       pre_stim_phase_dur_us - Pre-stimulus Phase duration (microseconds)
    %
    %   PulseTrainNIC3Matlab Methods:
    %       struct(obj) - struct(obj) outputs a structure with the most
    %       relevant properties and their values
    %       get_level_dbua(obj) - level_dbua = obj.get_level_dbua()
    %       outputs the max level played in dB re 1 uA        
    %
    %   Example:
    %       p = PlayerNIC3MatlabL34(); % Laura speech processor
    %       stim = PulseTrainNIC3Matlab();
    %       p.play(stim)
    %
    % See also FORMATNIC3Matlab, PLAYERNIC3MATLABL34, PULSETRAIN
    
    properties
        phase_dur_us = 43; % Phase Duration (microseconds)
        electrode_IDs = 11; % Electrodes on which the pulse train is played
        rate_pps = 442; % Rate of the pulse train (pps)
        level = 100; % Level (Device Units)
        duration_s = 0.4; % Pulse train duration (seconds)
        max_level = 255; % User-defined maximum level (Device Units)
    end
    
    properties
        interphase_dur_us = 8; % Interphase gap duration (microseconds)
        pre_stim_dur_s = 0.075; % Pre-stimulus duration, makes sure the
        % signal is played properly
        pre_stim_rate_pps = 5000; % Pre-stimulus rate (pps)
        pre_stim_level = 20; % Pre-stimulus Level (Device Units)
        pre_stim_phase_dur_us = 25; % Pre-stimulus Phase duration (microseconds)
    end
    
    properties (Hidden)
        compliance_limit_unit = 255; % to be defined
        charge_limit_nc = []; % to be defined
    end
    
    properties (SetAccess = protected, GetAccess = public, Hidden)
        whole_duration_s = []; % Includes pre- and post-stimulus
    end
    
    properties (SetAccess = protected)
        electrodogram = repmat(struct('t_s', [], 'amp_cu', [],...
            'pulses_start_times_s', []), 22, 1); % "electrodogram{el_ID}.t_s", ".amp_cu", ".pulse_start_times_s"            
    end
    
    % Values (or arrays) to be passed on to the L34 speech processor
    % The user can not access them, to avoid false manipulation
    properties (SetAccess = protected, Hidden)
        electrodes = [];
        modes = 103;
        current_levels = [];
        phase_widths = [];
        phase_gaps = [];
        periods = [];
    end
    
    methods
        % Constructor, called when creating the object
        function obj = PulseTrainNIC3Matlab()
            
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
            %       stimObj = PulseTrainNIC3Matlab;
            %       s = struct(stimObj)
            %
            %   Or:
            %       s = stimObj.struct
            %
            
            structOut = struct('rate_pps', obj.rate_pps, ...
                'level', obj.level, ...
                'electrode_IDs', obj.electrode_IDs, ...
                'phase_dur_us', obj.phase_dur_us ,...
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
    end
    
    methods (Hidden)
        function init(obj)
            % obj.init() prepares the values to be sent to the L34
            
            % Check that the stimulus pulse rate is achievable
            if obj.rate_pps > (1000000/(2*obj.phase_dur_us + obj.interphase_dur_us + 6.4))
                error('%d pps can not be achieved with a phase and interphase duration of %.1f and %.1f us\n',...
                    obj.rate_pps, obj.phase_dur_us, obj.interphase_dur_us)
            end
            
            % Check that the pre-stimulus pulse rate is achievable
            if obj.pre_stim_rate_pps > (1000000/(2*obj.pre_stim_phase_dur_us...
                    + obj.interphase_dur_us + 6.4))
                error('%d pps can not be achieved in the prestimulus with a phase and interphase duration of %.1f and %.1f us\n',...
                    obj.pre_stim_rate_pps, obj.pre_stim_phase_dur_us, obj.interphase_dur_us)
            end
            
            % Set periods in µs for pre- and poststimulus intervals
            periods_single(1) = round(1000000/obj.pre_stim_rate_pps);
            periods_single(2) = round(1000000/obj.rate_pps);
            periods_single(3) = round(1000000/obj.pre_stim_rate_pps);
            
            % Set number of pulses for pre- and poststimulus intervals
            num_pulses(1) = round(obj.pre_stim_dur_s/(periods_single(1)/1000000));
            num_pulses(2) = round(obj.duration_s/(periods_single(2)/1000000));
            num_pulses(3) = round(obj.pre_stim_dur_s/(periods_single(3)/1000000));
            
            % Set amplitudes for pre- and interstimulus intervals
            amplitudes(1) = obj.pre_stim_level;
            amplitudes(2) = obj.level;
            amplitudes(3) = obj.pre_stim_level;
            
            % Set phase widths
            phase_durations(1) = obj.pre_stim_phase_dur_us;
            phase_durations(2) = obj.phase_dur_us;
            phase_durations(3) = obj.pre_stim_phase_dur_us;
            
            % Set periodes for the pulse train
            obj.electrodes = obj.electrode_IDs;
            obj.current_levels = [repmat(amplitudes(1),1,num_pulses(1))...
                repmat(amplitudes(2),1,num_pulses(2))...
                repmat(amplitudes(3),1,num_pulses(3))];
            obj.phase_widths = [repmat(phase_durations(1),1,num_pulses(1))...
                repmat(phase_durations(2),1,num_pulses(2))...
                repmat(phase_durations(3),1,num_pulses(3))];
            obj.phase_gaps = obj.interphase_dur_us;
            obj.periods = [repmat(periods_single(1),1,num_pulses(1)) ...
                repmat(periods_single(2),1,num_pulses(2)) ...
                repmat(periods_single(3),1,num_pulses(3))];
            
            % Set whole duration
            obj.whole_duration_s = obj.duration_s + 2*obj.pre_stim_dur_s;
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
        
        function set.pre_stim_dur_s(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>', 0};
            prop_name = 'pre_stim_dur_s';
            
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
        
        function set.pre_stim_rate_pps(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>', 0};
            prop_name = 'pre_stim_rate_pps';
            
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
        
        function set.pre_stim_level(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', 'integer', '>=', 0, '<=', 255};
            prop_name = 'pre_stim_level';
            
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
        
        function set.pre_stim_phase_dur_us(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>=', 20, '<', 429.4};
            prop_name = 'pre_stim_phase_dur_us';
            
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