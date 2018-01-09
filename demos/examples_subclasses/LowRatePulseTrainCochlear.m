% With NIC3 (Cochlear), it is not possible to have by very low pulse rates.
% The alternative is to modulate a higher rate pulse train
%
% You can modify it as you want (keep in mind to always check new stimuli
% on the oscilloscope before using with CI subjects)

classdef LowRatePulseTrainCochlear < PulseTrainNIC3Python
    % LowRatePulseTrainCochlear
    %
    % Inherits all properties and methods from PulseTrainNIC3Python
    % Default properties are overwritten in the constructor
    %
    % Adds one property (low_rate_pps), the desired low rate
    
    properties
        low_rate_pps = 20;
    end
    
    methods
        function obj = LowRatePulseTrainCochlear()
            % Constructor for the standard stimulus
            
            % Main parameters
            obj.rate_pps = 2000; % High enough to be doable in NIC3
            obj.duration_s = 0.5; % for illustration. every property can be 
            % overwritten in the constructor.
            
            % Modulate the carrier rate at the desired low rate
            obj.modulate_low_rate();
            
        end
        function structOut = struct(obj)
            
            % Call superclass struct function
            structOut = struct@PulseTrainPyCochlear(obj);
            
            % Add the desired rate in pps
            structOut.desired_rate_pps = obj.desired_rate_pps;
            
        end
    end
    
    methods (Hidden)
        function modulate_low_rate(obj)
            % Desired rate is too low to be achieved without modulating a
            % higher rate pulse train
            
            fs = obj.rate_pps;
            t = 0:1/fs:obj.duration_s;
            modulator = zeros(size(t));
            period_samples = round(fs/obj.low_rate_pps);
            modulator(1:period_samples:numel(t)) = 1;
            obj.modulator = [t' modulator'];            
            
        end
    end
    
    methods
        function set.low_rate_pps(obj, value)
            
            % Settings
            property_class = {'numeric'};
            property_attributes = {'scalar', 'integer', '>=', 1, '<=', 100};
            prop_name = 'low_rate_pps';
            
            % Try initialization
            validateattributes(value, property_class, property_attributes)            
            tmp_value = obj.(prop_name);
            try
                obj.(prop_name) = value;
                obj.check_level();
                obj.init;
                obj.modulate_low_rate();
            catch error_msg
                obj.(prop_name) = tmp_value;
                obj.init;
                obj.modulate_low_rate();
                warning('%s could not be changed, and was kept to its previous value.\n\nCf. error message below for more info.', prop_name)
                rethrow(error_msg)
            end            
            
        end
    end
end