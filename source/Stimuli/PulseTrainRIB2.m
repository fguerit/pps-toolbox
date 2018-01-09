classdef PulseTrainRIB2 < FormatRIB2 & PulseTrain
    % PulseTrainRIB2 < FormatRIB2 & PulseTrain
    %
    %   Single-electrode pulse train class for MedEl devices, using RIB2 software.
	%
	%	Triggering: There is the option to send a TTL trigger before each pulse,
	%		before first pulse, or to never send a trigger.
    %
    %   PulseTrainRIB2 Properties:
    %       phase_dur_us - Phase Duration (microseconds)
    %       electrode_IDs - Electrodes on which the pulse train is played
    %       rate_pps - Rate of the pulse train (pps)
    %       level - Level (Device Units)
    %       max_level - 1*4 matrix with user-defined maximum level for each range (Device Units)
    %       range - range of levels
    %       duration_s - Pulse train duration (seconds)
    %       stimulus_file - parameter file used by the MedEl player
    %       interphase_dur_us - Interphase gap duration (microseconds)
    %       pulse_type - Biphasic, Triphasic or Precisions triphasic ("B", "T", "P")
    %       polarity - negative or postive first
	%		trig_occurence - Before which pulses to put a trigger: 'all' (default), 'first', 'none' 
	%		trig_dur_us - Trigger duration in microseconds
    %
    %   PulseTrainRIB2 Methods:
    %       struct(obj) - struct(obj) outputs a structure with the most
    %       relevant properties and their values
    %       get_level_dbua(obj) - level_dbua = obj.get_level_dbua()
    %       outputs the max level played in dB re 1 uA        
    %
    %   Example:
    %       p = PlayerRIB2();
    %       stim = PulseTrainRIB2();
    %       p.play(stim)
    %
    % See also FORMATRIB2, PLAYERRIB2, PULSETRAIN
    
    properties
        phase_dur_us = 43; % Phase Duration (microseconds)
        interphase_dur_us = 0; % Interphase gap duration (microseconds)          
        electrode_IDs = 11; % Electrodes on which the pulse train is played
        rate_pps = 442; % Rate of the pulse train (pps)
        level = 100; % Level (Device Units)
        range = 0; % Range of levels
        duration_s = 0.4; % Pulse train duration (seconds)
        pulse_type = 'B';
        polarity = '-'; % negative or postive first   
		trig_occurence = 'all'; % Before which pulses to put a trigger: 'all' (default), 'first', 'none' 
        trig_dur_us = 10; % Trigger duration in microseconds
        max_level = [127 127 127 127]; % Max level for each range (Device Units)
    end
    
    properties (SetAccess = protected)     
        stimulus_file = ''; % parameter file used by the player
        electrodogram = repmat(struct('t_s', [], 'amp_cu', [],...
            'pulses_start_times_s', []), 12, 1); % "electrodogram{el_ID}.t_s", ".amp_cu", ".pulse_start_times_s"            
    end
    
    properties (SetAccess = protected, Hidden, GetAccess = public)
        whole_duration_s = []; % Includes pre- and post-stimulus
    end
    
    properties (Hidden)
        compliance_limit_unit = 255; % to be defined
        charge_limit_nc = []; % to be defined
    end
    
    methods
        % Constructor, called when creating the object
        function obj = PulseTrainRIB2()
            
            % Check levels
            obj.check_level();
            
            % Init everything
            obj.init();
            
        end
        
        function structOut = struct(obj)
            % STRUCT outputs a structure with the most
            % relevant properties and their values
            %
            %   Example:
            %       stimObj = PulseTrainRIB2;
            %       s = struct(stimObj)
            %
            %   Or:
            %       s = stimObj.struct
            %
            
            structOut = struct('rate_pps', obj.rate_pps, ...
                'level', obj.level, ...
                'range', obj.range, ...
                'electrode_IDs', obj.electrode_IDs, ...
                'phase_dur_us', obj.phase_dur_us ,...
                'interphase_dur_us', obj.interphase_dur_us ,...
                'duration_s', obj.duration_s);
        end
        
        function level_dbua = get_level_dbua(obj)
            % GET_LEVEL_DBUA
            %
            %   level_dbua = obj.get_level_dbua()
            %   outputs the max level played in dB re 1 uA
            %
            
            level_dbua = 20*log10(obj.level*(150/127)*2^obj.range);
        end           
        
        function delete(obj)
            % Delete PulseTrainRIB2 Object
            
            if ~isempty(obj.stimulus_file)
                delete(obj.stimulus_file)
            end
        end
    end
    
    methods (Hidden)
        function init(obj)
            % obj.init() prepares the file to be written for MedEl
            
            % file name is written with round(now*1e8) at the beginning to
            % make sure one can create two stimuli in a very short time
            % with different names
            [current_path, ~, ~] = fileparts(mfilename('fullpath'));
            if ~exist(obj.stimulus_file, 'file')
                obj.stimulus_file = [current_path filesep ...
                    sprintf('%d', round(now*1e12)) '_medel_stimulus_file.stm'];
            end
            
            % Check that the pulse rate is achievable
            if obj.rate_pps > (1000000/(2*obj.phase_dur_us + obj.interphase_dur_us))
                error('%d pps can not be achieved with a phase duration of %.1f us\n',...
                    obj.rate_pps, obj.phase_dur_us)
            end
            
            % Set duration
            obj.whole_duration_s = obj.duration_s;
            
            % Set pulses
            periods(1) = round(1000000/obj.rate_pps);
            num_pulses(1) = round(obj.duration_s/(periods(1)/1000000));
            amplitudes(1) = obj.level;
            electrode = obj.electrode_IDs(1);
            
            % Alternated polarity is not implemented for this class
            if strcmp(obj.polarity, 'alt')
                error('Alternated polarity is not implemented for this class')
            end
            
            fid_stimulus = fopen(obj.stimulus_file,'wt');
            
            % Header
            fprintf(fid_stimulus, 'I PULSAR\n');
            fprintf(fid_stimulus, 'DEF Pulsar Phase %d Gap %d Seq Range ', obj.phase_dur_us, obj.interphase_dur_us);
            for e=1:12
                fprintf(fid_stimulus, '%d ', obj.range);
            end
            fprintf(fid_stimulus, '\n\n');
            
            switch obj.trig_occurence
                case 'first'
                    
                    % Trigger with the first pulse
                    fprintf(fid_stimulus, '%s ', obj.pulse_type);
                    fprintf(fid_stimulus, 'Trig TLength %.2f ', obj.trig_dur_us);
                    fprintf(fid_stimulus, 'Distance %d  ',  periods(1));
                    fprintf(fid_stimulus, '%s  ', obj.polarity);
                    fprintf(fid_stimulus, 'Number 1  ');
                    fprintf(fid_stimulus, 'Channel %d  ', electrode);
                    fprintf(fid_stimulus, 'Amplitude %d  \n\n', amplitudes(1));
                    
                    % Pulse train
                    fprintf(fid_stimulus, 'REP %d\n\n  ', num_pulses(1) - 1); % one, less, because of the first trigger
                    fprintf(fid_stimulus, '%s ', obj.pulse_type);
                    fprintf(fid_stimulus, 'Distance %d  ',  periods(1));
                    fprintf(fid_stimulus, '%s  ', obj.polarity);
                    fprintf(fid_stimulus, 'Number 1  ');
                    fprintf(fid_stimulus, 'Channel %d  ', electrode);
                    fprintf(fid_stimulus, 'Amplitude %d  \n\n', amplitudes(1));
                    fprintf(fid_stimulus, 'END\n');
                    
                case 'none'
                    
                    % Pulse train
                    fprintf(fid_stimulus, 'REP %d\n\n  ', num_pulses(1));
                    fprintf(fid_stimulus, '%s ', obj.pulse_type);
                    fprintf(fid_stimulus, 'Distance %d  ',  periods(1));
                    fprintf(fid_stimulus, '%s  ', obj.polarity);
                    fprintf(fid_stimulus, 'Number 1  ');
                    fprintf(fid_stimulus, 'Channel %d  ', electrode);
                    fprintf(fid_stimulus, 'Amplitude %d  \n\n', amplitudes(1));
                    fprintf(fid_stimulus, 'END\n');
                    
                case 'all'
                    
                    % Pulse train
                    fprintf(fid_stimulus, 'REP %d\n\n  ', num_pulses(1));
                    fprintf(fid_stimulus, '%s ', obj.pulse_type);
                    fprintf(fid_stimulus, 'Trig TLength %.2f ', obj.trig_dur_us);
                    fprintf(fid_stimulus, 'Distance %d  ',  periods(1));
                    fprintf(fid_stimulus, '%s  ', obj.polarity);
                    fprintf(fid_stimulus, 'Number 1  ');
                    fprintf(fid_stimulus, 'Channel %d  ', electrode);
                    fprintf(fid_stimulus, 'Amplitude %d  \n\n', amplitudes(1));
                    fprintf(fid_stimulus, 'END\n');                    
            end
            
            fclose(fid_stimulus);
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
            
            if obj.level > obj.max_level(obj.range+1)
                error('level (%d CU) > user-defined maximum level (%d CU for range %d)', ...
                    obj.level, obj.max_level(obj.range+1), obj.range)
            end
        end
    end    
    
    % obj.set methods. Each time a property is updated, initialization
    % should be redone
    methods
        
        function set.phase_dur_us(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>=', 0, '<', 9999};
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
            property_attributes = {'scalar', 'integer', '>=', 1, '<=', 12};
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
            property_attributes = {'scalar', 'integer', '>=', 0, '<=', 127};
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
            property_attributes = {'row', 'nonempty', 'numel', 4, 'integer', '>=', 0, '<=', 127};
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
        
        function set.trig_dur_us(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>=', 0, '<', 55e6};
            prop_name = 'trig_dur_us';
            
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
            string_attributes = {'-', '+', 'alt'};
            prop_name = 'polarity';
            
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
        
        function set.pulse_type(obj,value)
            
            % Settings
            property_class = {'char'};
            property_attributes = {'nonempty'};
            string_attributes = {'B', 'T', 'P'};
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
        
        function set.range(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', 'integer', '>=', 0, '<=', 3};
            prop_name = 'range';
            
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

		function set.trig_occurence(obj,value)
            
            % Settings
            property_class = {'char'};
            property_attributes = {'nonempty'};
            string_attributes = {'all', 'first', 'none'};
            prop_name = 'trig_occurence';
            
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