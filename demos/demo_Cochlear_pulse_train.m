% Demo to play a pulse train

%% Load the player

p = PlayerL34;

%% Load the Stimulus

stim = PulseTrainCochlear;

%% Play it

p.play(stim)

%% Change the pulse rate and play it again

stim.rate_pps = 880;

p.play(stim)

%% Change the pulse rate back and play it again

stim.rate_pps = 440;

p.play(stim)