classdef (Abstract) FormatBEDCS118 < FormatElectric & handle
    % FormatBEDCS118 < FormatElectric & handle
    %
    %   Class that defines the "must-have" for a stimulus to be played for
    %   direct stimulation with BEDCS 1.18 (Advanced Bionics)
    %
    %   FormatBEDCS118 Properties:
    %       exp_file - BEDCS experiment file used for stimulation
    %       level_mode - Upper Limit Level mode for BEDCS
    %
    %
    %   FormatBEDCS118 Properties (SetAccess = protected, Hidden):
    %       variables_struct - Structure with all variables that will be
    %       passed on to the BEDCS file. This structure is hidden and
    %       protected, only the Stimulus object can implement it, to avoid
    %       the user false manipulation. 
    %
    %   See also PLAYER, BLEEP, FormatElectric, PULSETRAINBEDCS118        
    
    properties (Abstract)
        exp_file
        level_mode
    end
    
    properties (Abstract, SetAccess = protected, Hidden)
        variables_struct
    end
    
end