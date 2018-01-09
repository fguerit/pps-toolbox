% Demo to play a pulse train


%% Parameters

player = @PlayerAB; % @PlayerAB or @PlayerL34
stimulus = @PulseTrainAB; % @PulseTrainAB or @PulseTrainCochlear

%% Load the player

p = player();

%% Load the Stimulus

stim = stimulus();

%% Play it

p.play(stim)

