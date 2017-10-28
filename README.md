# atom-transcribe package

A simple audio player for atom to aid text/interview transcription.
Based on sdinesh86/atom-music.

![A screenshot of the program.](screenshot.png)

Features:

* load audio files
* jump to a position (via GUI)
* rewind and fast forward in two different configurable steps (via GUI and keys)
* pause and resume playback, and optionally rewind the track upon playback (via GUI and keys)
* adjust the speed of the playback (via GUI and keys)
* insert a timestamp (via GUI and keys)
* inserted timestamps are highlighted, on-click the audio jumps to the highlighted time

Planned for future releases:

* configure speakers and implement shortcuts to add names
* write file name of audio into YAML metadata (for markdown)
* make use of the TextTrack-feature in order to create a visual representation of speakers in the progressbar
