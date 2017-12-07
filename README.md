# Keyboard Music Player

Made by:

- Daniel Weber
- David Chu
- David Zhang
- Stephen Buttolph

## How to install

We have supplied 2 install scripts in the install folder. The `vm_install.sh` script has been verified to successfully setup the environment on a fresh version of the course vm. It should also work for any linux machine that has the basic course ocaml installations. The `mac_install.sh` script should work on a mac, but we can’t make any guarantees.

## How to run

To run the project, `cd` to the `src` folder and run `make main`. It should start up the GUI.

## How to Use

The initial mode of the system is Keyboard mode, which lets you play the default song file by pressing sequences of keys on your keyboard. 
Don’t know how to play the song? Our midi player can help you out. Press the play button to start playing the default midi file, which will show you what keys to press and will also play the song for you.

### Where to go from there:

- Is the midi player going to fast for you or did you miss something? No problem, use the scrub bar to scrub backwards or forwards in the song. Then, use the BPM slider to slow down the playback, so that you can figure out what keys are pressed. If you want to learn to play, start slow and then work your way up to full speed.
- Bored of the current song? Press the load button to select a different song file. This will automatically load in the first midi file for that song. Notice that there are multiple midi files for each song? That’s because each song has multiple parts to it with different sounds mapped to different keys. We call each part a soundpack, and you can change the current soundpack by using the arrow keys. The midi file will change soundpacks for you automatically.
- Interested in some sound synthesis? Click the synth button to go to Synthesis mode. Each row of keys on your keyboard is now mapped to an octave, and each key in each row is mapped to a note in the octave. We have a few effects for you to play around with. You can select the waveform that you want and adjust the Attack-Decay-Sustain-Release (ADSR) envelope of the sound. You can also add a filter to the sound to create some interesting effects.
- Notice those bars in Keyboard mode when you play a song? Those are a visualization of the Fast Fourier Transform (FFT) of the audio buffer. What it does is it attempts to deconstruct the audio data into its fundamental frequencies and figures out the amplitude of each of those frequencies. So you’ll notice that if you play a very low sound, the bars toward the middle will increase in amplitude. If you play a sound with a higher frequency, bars further away from the middle will increase their amplitudes.
