classdef PlayerRIB2 < Player
    % PlayerRIB2 < Player
    %
    %   Class that defines the PlayerRIB2 object, to play stimuli with RIB2
    %   software (MedEl).
    %
    %   PlayerRIB2 Properties:
    %       stimulus_format - Format that can be read by the player
    %       is_blocking - 0 here: PlayerRIB2 doesn't block the matlab prompt when playing      
    %
    %   PlayerRIB2 Methods:
    %       play(obj, stimObj) - obj.play(stimObj) plays the stimulus
    %
    %   Example:
    %       p = PlayerRIB2(); % Load the player
    %       stim = PulseTrainRIB2(); % Load the stimulus
    %       p.play(stim)
    %
    %   See also PLAYER, FORMATRIB2, BLEEP, PULSETRAINRIB2
    
    properties (SetAccess = protected)
        stimulus_format = @FormatRIB2; % Format that can be read by the player
        is_blocking = 0; % PlayerRIB2 doesn't block the matlab prompt when playing         
        buffer_length_ms = 100;
        number_buffers = 3;
    end
    
    methods
        function obj = PlayerRIB2()
            % constructor.
            
            obj.init();
        end
        
        function init(obj)
            
            % Add paths
            addpath('C:\RIB2\DLL\');
            addpath('C:\RIB2\DLL\64 bit\');
            addpath('C:\RIB2\Matlab\');
            
            % Load RIB2 library
            loadlibrary('RIB2.dll', 'RIB2.h')
            
            % Set 3 buffers of 100 ms in RIB2
            calllib('RIB2','srConfigureBuffer', obj.buffer_length_ms, ...
                obj.number_buffers);
            
        end
        
        function play(obj, stimObj)
            % PLAY plays the stimulus
            %
            %   Example:
            %       p = PlayerRIB2(); % Laura speech processor
            %       stim = PulseTrainRIB2();
            %       p.play(stim)
            
            % Check that the format is correct
            if ~isa(stimObj, func2str(obj.stimulus_format))
                error(['"p.play(stimObj)": stimObj should be of class "'...
                    func2str(obj.stimulus_format)...
                    '". Type "showSubClassesFormat" to get the current list.'])
            end
            
            vp = libpointer('int8Ptr', [int8(stimObj.stimulus_file) 0]);
            sequenceHandle = calllib('RIB2', 'srLoadStimulationSequence', vp, 100);
            calllib('RIB2', 'srClearFgStimulations', 1,1);
            calllib('RIB2', 'srAddFgStimulation',sequenceHandle, 1,0);
            calllib('RIB2', 'srSwitchStimulation',2,0,0,0);
            
        end
        
        function delete(obj)
            calllib('RIB2', 'srStopStimulation');
            unloadlibrary('RIB2');
        end
    end
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            % To avoid glitches when saving to .mat file, only modifiable
            % properties are saved (saveobj) in a structure and the object is
            % reconstructed when loading it.
            if isstruct(s)
                obj = PlayerRIB2();
            else
                obj = s;
            end
        end
    end    
    
    methods (Hidden)
        
        function s = saveobj(obj)
            % To avoid glitches when saving to .mat file, only modifiable
            % properties are saved (saveobj) in a structure and the object is
            % reconstructed when loading it.
            %
            % for now, empty struct.
            s = struct();
        end
    end        
end