% This is an example of a subclass derived from the class PlayerBEDCS.
% You can modify it as you want (keep in mind to always check new stimuli
% on the oscilloscope before using with CI subjects)

classdef MyNewStimulus < PulseTrainBEDCS118
    % MyNewStimulus Help message for your stimulus

    properties
        my_extra_property = 'this'; % You can create as many new properties as you wish
    end

    methods
        function obj = MyNewStimulus()
            % Constructor of MyNewStimulus
            % 
            % This function is called when creating the stimulus object. It
            % is the perfect place to update default values from the
            % superclass.
            %
            % Note that the constructor of the superclass is called first,
            % meaning that all properties will have the default values of
            % the superclass.

            % Update the default rate for example
            obj.rate_pps = 100;
        end

        function my_new_method(obj)
            % my_new_method
            %
            % You can also create new methods!

            fprintf('%s is my new property.\n', obj.my_extra_property)
        end

        % Set properties. It is good practice to check on the values you are
        % trying to impose to your new properties.
        %
        % It also allows to call methods when changing properties.
        % 
        % You can check in the different PulseTrain classes how the "set"
        % functions are implemented 
        function set.my_extra_property(obj, value)
            
            % Settings
            property_class = {'char'};
            property_attributes = {'nonempty'};
            string_attributes = {'This', 'Here'};
            prop_name = 'my_extra_property';
            
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
    end

end