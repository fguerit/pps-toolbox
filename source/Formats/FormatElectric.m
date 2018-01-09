classdef (Abstract) FormatElectric < Format
    % FormatElectric < Format   Class that defines must-have properties for
    % electric stimuli
    %
    %   FormatElectric Properties
    %       electrodgram - "electrodogram{el_ID}.t_s", ".amp_cu", ".pulse_start_times_s"
    %
    % See also Format, FormatRIB2, FormatBEDCS118, FormatNIC3Python
    
    properties (Abstract, SetAccess = protected)
        electrodogram % "electrodogram{el_ID}.t_s", ".amp_cu", ".pulse_start_times_s" 
    end  
    
end