classdef (Abstract) PulseTrain < Stimulus
    % PulseTrain < Stimulus
    %
    %   Simple pulse train class for Cochlear Implant direct stimulation.
    %
    %   PulseTrain Properties:
    %       phase_dur_us - Phase Duration (microseconds)
    %       interphase_dur_us - Interphase Gap Duration (microseconds)
    %       electrode_IDs - Electrodes on which the pulse train is played
    %       rate_pps - Rate of the pulse train (pps)
    %       level - Level (Device Units)
    %       duration_s - Pulse train duration (seconds)
    %
    %   This is the top class of several implementations. To be played by a
    %   PLAYER object, a PulseTrain also needs to be a subclass of a FORMAT.
    %
    % See also FormatElectric, PLAYER, Stimulus, PULSETRAINBEDCS118, PulseTrainNIC3Python, 
    %   PulseTrainRIB2
    
    properties (Abstract)
        phase_dur_us % Phase Duration (microseconds)
        interphase_dur_us % Interphase Gap Duration (microseconds)
        electrode_IDs % Electrodes on which the pulse train is played
        rate_pps % Rate of the pulse train (pps)
        level % Level (Device Units)
        duration_s % Pulse train duration (seconds)
    end
end