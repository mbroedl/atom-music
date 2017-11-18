# atom-transcribe

A simple audio player for atom to aid text/interview transcription.
Originally based on sdinesh86/atom-music.

![Screencast of the program.](screencast.gif)

## Functionality

![Screenshot of the program with numbered functions.](screenshot.png)

| num |        key         | function              | description                                                                                         |
| ---:|:------------------:|:--------------------- | --------------------------------------------------------------------------------------------------- |
|   1 |      `ctrl-1`      | large jump back       | (default: 10sec)                                                                                    |
|   2 |      `ctrl-2`      | short jump back       | (default: 2sec)                                                                                     |
|   3 |    `ctrl-space`    | play/pause            |                                                                                                     |
|   4 |      `ctrl-5`      | small jump forward    | (default: 2sec)                                                                                     |
|   5 |      `ctrl-6`      | large jump forward    | (default: 10sec)                                                                                    |
|   6 |      `ctrl-t`      | insert timestamp      | (default: `_[mm:ss.ms]_`)                                                                           |
|   7 |     (`click`)      | jump to position      |                                                                                                     |
|   8 | `ctrl-3`, `ctrl-4` | change playback speed |                                                                                                     |
|   9 |                    | open file             |                                                                                                     |
|  10 |    (`dblclick`)    | jump to position      | jump to timestamp;  a double click in text interpolates the time between the surrounding timestamps | 
 
## Possible future features?

* configure speakers and implement shortcuts to add names
* write file name of audio into YAML metadata (for markdown)
* make use of the TextTrack-feature in order to create a visual representation of speakers in the progressbar
