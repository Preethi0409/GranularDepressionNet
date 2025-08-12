% Load EEG signal (Example: Assume 'eeg_signal' is a 1D array)
fs = 256; % Sampling frequency in Hz (Adjust based on dataset)
t = (0:length(eeg_signal)-1)/fs; % Time vector

% Generate Spectrogram
figure;
spectrogram(eeg_signal, 128, 120, 256, fs, 'yaxis');
title('EEG Spectrogram');
colormap jet;
colorbar;

% Save the image
saveas(gcf, 'EEG_Spectrogram.png');
% Load EEG signal
fs = 256; % Sampling frequency
t = (0:length(eeg_signal)-1)/fs;

% Compute Continuous Wavelet Transform (CWT)
[cfs, f] = cwt(eeg_signal, fs);

% Plot scalogram
figure;
imagesc(t, f, abs(cfs));
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('EEG Wavelet Scalogram');
colormap jet;
colorbar;

% Save the image
saveas(gcf, 'EEG_Wavelet.png');
% Load EEG data (Example: EEG from 19 channels)
load('eeg_data.mat'); % Assume EEG data is in matrix form [channels x time]
fs = 256; % Sampling rate

% Compute mean voltage across time for each electrode
mean_values = mean(eeg_data, 2);

% Load electrode positions (Standard 10-20 system)
load('Standard_1020.mat'); % Contains 'X', 'Y', 'Z' coordinates

% Plot topographic map
figure;
topoplot(mean_values, 'Standard_1020.elp', 'electrodes', 'on', 'maplimits', 'absmax', 'colormap', jet);
title('EEG Topographic Map');

% Save the image
saveas(gcf, 'EEG_Topomap.png');
