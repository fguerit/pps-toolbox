classdef PulseTrainRIB2ABR < PulseTrainRIB2
    % PulseTrainRIB2ABR < PulseTrainRIB2
    %
    %   Variation of PulsTrainMedel designed for eABR (jittered pulse train
    %       and alternated polarity).
    %       A 20 ms (20000 us) jitter is recommended for removing 50 Hz line
    %       noise in eABR recordings.
    %
    %   Help on PulseTrainRIB2 properties and methods:
    %       help PulseTrainRIB2
    %
    %   PulseTrainRIB2ABR Properties:
    %       jitter_window_us - Max jitter (in us) added or removed to the period (1/rate_pps) of the pulse train
    %
    %
    % See also FORMATRIB2, PLAYERRIB2, PulseTrainRIB2
    
    properties
        jitter_window_us = 0; % Jitter (in us) added to the period (1/rate_pps) of the pulse train
    end
       
    methods
        % Constructor, called when creating the object
        function obj = PulseTrainRIB2ABR()
            
            % Init rate_pps with a low rate, to allow the default jitter
            obj.rate_pps = 10;
            obj.jitter_window_us = 20000;
            
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
                'duration_s', obj.duration_s, ...
                'jitter_window_us', obj.jitter_window_us);
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
            
            %Jittered periods
            periods_jittered = repmat(periods, 1, num_pulses(1));
            jittered_time = (1:num_pulses)*obj.jitter_window_us/num_pulses - ...
                obj.jitter_window_us/2;
            rng('shuffle');
            idx_permutation = randperm(length(jittered_time));
            jittered_time = jittered_time(idx_permutation);
            periods_jittered = round(periods_jittered + jittered_time);       
            
            % Set polarity for each pulse
            polarity_vector = cell(1, num_pulses(1));
            if strcmp(obj.polarity, 'alt')
                polarity_vector(1:2:end) = {'-'};
                polarity_vector(2:2:end) = {'+'};
            else
                polarity_vector(:) = {obj.polarity};
            end
            
            if any(periods_jittered <= 2*obj.phase_dur_us + obj.interphase_dur_us)
                error('%d pps can not be achieved with a jitter of %.1f us.\nDecrease the jitter window or the rate.',...
                    obj.rate_pps, obj.jitter_window_us)
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
                    fprintf(fid_stimulus, 'Distance %d  ',  periods_jittered(1));
                    fprintf(fid_stimulus, '%s  ', polarity_vector{1});
                    fprintf(fid_stimulus, 'Number 1  ');
                    fprintf(fid_stimulus, 'Channel %d  ', electrode);
                    fprintf(fid_stimulus, 'Amplitude %d  \n\n', amplitudes(1));
                    
                    % All other pulses
                    for idx = 2:num_pulses(1)
                        fprintf(fid_stimulus, '%s ', obj.pulse_type);
                        fprintf(fid_stimulus, 'Distance %d  ',  periods_jittered(idx));
                        fprintf(fid_stimulus, '%s  ', polarity_vector{idx});
                        fprintf(fid_stimulus, 'Number 1  ');
                        fprintf(fid_stimulus, 'Channel %d  ', electrode);
                        fprintf(fid_stimulus, 'Amplitude %d  \n\n', amplitudes(1));
                    end
                    
                case 'none'
                    
                    % All pulses
                    for idx = 1:num_pulses(1)
                        fprintf(fid_stimulus, '%s ', obj.pulse_type);
                        fprintf(fid_stimulus, 'Distance %d  ',  periods_jittered(idx));
                        fprintf(fid_stimulus, '%s  ', polarity_vector{idx});
                        fprintf(fid_stimulus, 'Number 1  ');
                        fprintf(fid_stimulus, 'Channel %d  ', electrode);
                        fprintf(fid_stimulus, 'Amplitude %d  \n\n', amplitudes(1));
                    end
                    
                case 'all'

                    % All pulses
                    for idx = 1:num_pulses(1)
                        fprintf(fid_stimulus, '%s ', obj.pulse_type);
                        fprintf(fid_stimulus, 'Trig TLength %.2f ', obj.trig_dur_us);
                        fprintf(fid_stimulus, 'Distance %d  ',  periods_jittered(idx));
                        fprintf(fid_stimulus, '%s  ', polarity_vector{idx});
                        fprintf(fid_stimulus, 'Number 1  ');
                        fprintf(fid_stimulus, 'Channel %d  ', electrode);
                        fprintf(fid_stimulus, 'Amplitude %d  \n\n', amplitudes(1));
                    end               
            end
            
            fclose(fid_stimulus);
        end
        
        function plot(obj)
        % Plots the electrodogram of the stimulus
        
        error('Plotting not implemented yet for this stimulus')
        
        end        
    end
    
    % obj.set methods. Each time a property is updated, initialization
    % should be redone
    methods
        function set.jitter_window_us(obj,value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', '>=', 0, '<', 500000};
            prop_name = 'jitter_window_us';
            
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