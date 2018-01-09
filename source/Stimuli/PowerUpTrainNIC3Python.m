classdef PowerUpTrainNIC3Python < FormatNIC3Python & PulseTrain
    % PowerUpTrainNIC3Python < FormatNIC3Python & PulseTrain
    %
    %   Power-Up train class for Cochlear devices using NIC3/python interface.
    %   Only duration can be changed.
    %
    %   Duration of each power pulse is adjusted so as to match the whole
    %   duration as closely as possible, but is kept as a max of 1ms
    %   
    %   PowerUpTrainNIC3Python Properties (PulseTrain class):
    %       phase_dur_us - can not be changed here
    %       electrode_IDs - can not be changed here
    %       rate_pps - can not be changed here
    %       level - can not be changed here
    %       max_level - can not be changed here
    %       duration_s - Power-Up duration (seconds)
    %
    %   PowerUpTrainNIC3Python Properties (FormatCochlear class):
    %       interphase_dur_us - can not be changed here
    %       polarity - can not be changed here
    %       pulse_type - can not be changed here
    %
    %   PowerUpTrainNIC3Python Methods:
    %       struct(obj) - struct(obj) outputs a structure with the most
    %       relevant properties and their values
    %       get_level_dbua(obj) - level_dbua = obj.get_level_dbua()
    %       outputs the max level played in dB re 1 uA        
    %
    %   Example:
    %       p = PlayerNIC3PythonRFGenXS(); % Laura speech processor
    %       stim = PulseTrainNIC3Python();
    %       powerUpSeq = PowerUpTrainNIC3Python();
    %       p.play({powerUpSeq, stim, powerUpSeq})
    %
    % See also FORMATNIC3PYTHON, PLAYERNIC3PYTHONRFGENXS, PULSETRAIN
    
    properties
        phase_dur_us = []; % can not be changed here
        electrode_IDs = []; % can not be changed here
        rate_pps = []; % can not be changed here
        level = []; % can not be changed here
        duration_s = 1; % Pulse train duration (seconds)
        max_level = []; % can not be changed here
    end
    
    properties
        interphase_dur_us = []; % can not be changed here
        polarity = []; % can not be changed here
        pulse_type = []; % can not be changed here       
    end
    
    properties (Hidden)
        compliance_limit_unit = 255; % to be defined
        charge_limit_nc = []; % to be defined
    end
    
    properties (SetAccess = protected)
        stimulus_file = ''; % parameter file used by the player
    end 
    
    properties (SetAccess = protected)
        electrodogram = repmat(struct('t_s', [], 'amp_cu', [],...
            'pulses_start_times_s', []), 22, 1); % "electrodogram{el_ID}.t_s", ".amp_cu", ".pulse_start_times_s"            
    end
    
    properties (SetAccess = protected, GetAccess = public, Hidden)
        whole_duration_s = []; % Includes pre- and post-stimulus
    end
    
    methods
        % Constructor, called when creating the object
        function obj = PowerUpTrainNIC3Python()
            
            % The only thing to do at startup: init everything
            obj.init();
            
        end
        
        function structOut = struct(obj)
            % STRUCT outputs a structure with the most
            % relevant properties and their values
            %
            %   Example:
            %       stimObj = PowerUpTrainNIC3Python;
            %       s = struct(stimObj)
            %
            %   Or:
            %       s = stimObj.struct
            %
            
            structOut = struct('duration_s', obj.duration_s);
        end
        
        function level_dbua = get_level_dbua(~)
            % GET_LEVEL_DBUA
            %
            %   level_dbua = obj.get_level_dbua()
            %   outputs the max level played in dB re 1 uA
            %
            
            level_dbua = NaN;
        end          
        
        function delete(obj)
            % Delete PowerUpTrainNIC3Python Object
            
            delete([obj.stimulus_file '*'])
        end         
    end
    
    methods (Hidden)
        function init(obj)
            % obj.init() prepares the values to be sent to the implant
            
            
            % file name is written with round(now*1e8) at the beginning to
            % make sure one can create two stimuli in a very short time
            % with different names
            [current_path, ~, ~] = fileparts(mfilename('fullpath'));
            if ~exist(obj.stimulus_file, 'file')
                obj.stimulus_file = [current_path filesep ...
                    sprintf('%d', round(now*1e12)) '_cochlear_stimulus_file.py'];
            end
            
            fid_stimulus = fopen(obj.stimulus_file,'wt');
            
            % Header
            fprintf(fid_stimulus, 'import cochlear.nic3 as nic3\n\n');
            fprintf(fid_stimulus, 'def get_stimulus_seq():\n');            
            
            % Create stimulus with power up pulses
            % Duration of each pulse is adjusted so as to match the whole
            % duration as closely as possible
            possible_pulse_durations_us = 65:.2:1000; % Could go higher 
            % but it's not really needed here. NIC3 rounds the duration to
            % .2 us
            ratios = obj.duration_s./(possible_pulse_durations_us*1e-6);
            integers = round(ratios);
            residuals = abs(ratios-integers);
            [~,best_padded_pulse_index] = min(residuals);
            best_padded_pulse_index = best_padded_pulse_index(1);
            power_up_pulse_duration_us = possible_pulse_durations_us(best_padded_pulse_index);
            
            num_pulses = round(obj.duration_s/(power_up_pulse_duration_us/1000000));
            
            fprintf(fid_stimulus, ...
                '    stim_type = nic3.NullStimulus(%.1f)\n',...
                power_up_pulse_duration_us);
            fprintf(fid_stimulus, ...
                '    stim_command = nic3.StimulusCommand(stim_type)\n');
            fprintf(fid_stimulus, ...
                '    seq = nic3.Sequence(%d)\n', num_pulses);
            fprintf(fid_stimulus, ...
                '    seq.append(stim_command)\n');
            
            % Output the sequence
            fprintf(fid_stimulus, '    return seq\n\n');
            fprintf(fid_stimulus, 'seq = get_stimulus_seq()\n');
            
            fclose(fid_stimulus);
            
            % Set whole duration
            obj.whole_duration_s = obj.duration_s;
        end
        
        function plot(obj)
        % Plots the electrodogram of the stimulus
        
        error('Plotting not implemented yet for this stimulus')
        
        end
    end
    
    methods (Access = protected)
        function check_level(~)
            % Void here. No level is defined for power up pulse trains
        end
    end    
    
    % obj.set methods. Each time a property is updated, initialization
    % should be redone
    methods
        function set.phase_dur_us(~,~)
            error('This is a Power-Up pulse train, only duration_s can be modified')
        end
        
        function set.electrode_IDs(~,~)
            error('This is a Power-Up pulse train, only duration_s can be modified')
        end
        
        function set.rate_pps(~,~)
            error('This is a Power-Up pulse train, only duration_s can be modified')
        end
        
        function set.level(~,~)
            error('This is a Power-Up pulse train, only duration_s can be modified')
        end
        
        function set.max_level(~,~)
            error('This is a Power-Up pulse train, only duration_s can be modified')
        end        
        
        function set.duration_s(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>=', 52e-6};
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
        
        function set.interphase_dur_us(~,~)
            error('This is a Power-Up pulse train, only duration_s can be modified')
        end
        
        function set.polarity(~,~)
            error('This is a Power-Up pulse train, only duration_s can be modified')
        end     
        
        function set.pulse_type(~,~)
            error('This is a Power-Up pulse train, only duration_s can be modified')
        end          
        
    end
end