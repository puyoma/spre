# spre

**A generative synthesizer for monome norns.**

spre combines a 12-voice SuperCollider synthesis engine with five melody generators, eight polyphonic voicings, adjustable chord strum, scale quantization, MIDI and grid performance modes, and two kinds of looping. It can play by itself, respond to an external MIDI keyboard, or become a scale-aware instrument on a 16×8 grid.

The sound moves between clean, resonant tones and saturated, dusty, tape-worn textures. Melody and harmony can be reshaped while the instrument is running.

> [日本語マニュアル](README_ja.md)

## Requirements

- monome norns
- 16×8 grid: optional
- USB MIDI keyboard/controller: optional

spre includes its own SuperCollider engine. After the first installation, shut norns down completely and turn it back on; a software restart may not be sufficient.

Project structure:

```text
spre/
├── spre.lua
├── README.md
├── README_ja.md
└── lib/
    └── Engine_Spre.sc
```

## Installation

In the Maiden REPL:

```text
;install https://github.com/puyoma/spre
```

After installation, shut norns down completely, turn it back on, then launch `spre` from SELECT. If only a software restart is performed, norns may report `AUDIO SYSTEM FAIL` until the next full power cycle.

## Quick start

spre starts in **AUTO** mode and begins generating notes automatically.

- Turn **E2** to select a parameter.
- Turn **E3** to change the selected parameter.
- When FILTER is selected, turn **E1** to choose AIR, GLASS, AMBER, or WOOD.
- Press **K3** to open the MEL / POLY / STRUM page.
- Set **FLOCK** to zero to stop new AUTO notes.

Start with the norns output/headphone level low. Saturation, resonance, chords, and high FLOCK and RAIN settings can create sudden level changes.

## norns controls

These controls work from the main parameter page unless noted otherwise.

| Control | Action |
|---|---|
| E1 | When FILTER is selected: choose AIR / GLASS / AMBER / WOOD |
| E2 | Select parameter |
| E3 | Change selected parameter |
| K2 | Jump to the next parameter row |
| K3 | Toggle between parameter and MEL / POLY / STRUM pages |
| K1 + E1 | Cycle parameter, MEL / POLY / STRUM, and visualizer pages |
| K1 + K2 | Octave down |
| K1 + K3 | Octave up |
| K2 + K3 | Clear the selected audio loop, or note-loop slot 1 |

When **LOOP** is selected, K2 operates the loop instead of jumping to the next row.

On the MEL / POLY / STRUM page:

| Control | Action |
|---|---|
| E2 or K2 | Select MEL, POLY, or STRUM |
| E3 | Choose the melody algorithm or voicing, or adjust strum amount |
| K3 | Return to the parameter page |

The visualizer page shows an animated rainy alley and has no dedicated editing controls. Use K1 + E1 to leave it.

## Modes

### AUTO

The internal generator creates notes from the selected ROOT and SCALE.

- **FLOCK** controls how frequently events are generated. Zero stops new notes.
- **RAIN** is the probability that a generated event will be skipped. At zero, every event plays; at maximum, all events are skipped.
- **ATK / DEC** shape the percussive envelope.
- MELODY chooses how pitches move.
- POLY chooses how each pitch is voiced.
- STRUM spreads notes within generated chords for a looser, human feel.

### MIDI

Incoming MIDI notes are quantized to ROOT and SCALE, then played with an ADSR envelope. ATTACK, DECAY, SUSTAIN, and RELEASE become available on the parameter page. A connected grid can also be played as a scale keyboard without leaving MIDI mode.

### GRID

A connected 16×8 grid becomes a scale-based keyboard. Notes sound while held and use the same ADSR envelope as MIDI mode.

## Melody generators

| Name | Behaviour |
|---|---|
| RAND | Uniform random notes, with occasional octave jumps |
| GAUSS | Random movement weighted toward the middle of the range |
| MRKV | Markov-like movement that tends to stay near the previous note |
| ORBIT | Movement attracted to chord tones, with approaches and occasional jumps |
| FOLD | A four-note motif that gradually climbs and descends |

## Polyphonic voicings

Intervals follow degrees of the selected scale.

| Name | Voicing |
|---|---|
| MONO | Single note |
| OCT | Note plus octave |
| 5TH | Note plus four scale degrees |
| TRIAD | Note plus two and four scale degrees |
| 7TH | TRIAD plus six scale degrees |
| RAND | One or two random upper scale tones |
| ADD4 | Note plus two and three scale degrees |
| JAZZ | Note plus two and six scale degrees |

## Strum

STRUM controls the timing between notes in AUTO-mode chords. At zero, every note starts together. Higher values spread the note-ons with slight random variation, up to approximately 130 ms, for a strummed or humanized feel. It does not change single-note MONO voicing.

## Sound parameters

| Parameter | Description |
|---|---|
| ATK | Attack |
| DEC | Decay |
| FM | Pitch modulation depth |
| BRIT | Tonal brightness |
| SAT | Saturation and drive |
| TAPE | Sample-rate reduction and tape noise |
| FILTER | E3 controls cutoff/resonance: left is darker and more resonant; right is brighter and more open. E1 selects AIR, GLASS, AMBER, or WOOD |
| DUST | High-frequency noise |
| SPREAD | Randomized stereo placement |
| INTONE | Tuning color: center is equal temperament; turning away introduces interval-dependent offsets |
| SUSTAIN | ADSR sustain in MIDI / GRID |
| RELEASE | ADSR release in MIDI / GRID |

### Filter types

Turn E1 while FILTER is selected, or use FILTER TYPE in PARAMS, to choose a model. A change applies to notes triggered afterward; notes already sounding keep their original filter.

| Type | Character |
|---|---|
| AIR | Bright, open 12 dB low-pass with pronounced resonance |
| GLASS | Smooth, clean 24 dB low-pass with restrained resonance |
| AMBER | Thick, warm ladder filter with a little grit |
| WOOD | Vactrol-style low-pass gate with an organic decay |

## Loopers

spre has two loop systems.

### Note looper

- Six slots are available from grid column 16, rows 3–8.
- First press: record.
- Second press: finish recording and begin playback.
- Further presses: stop / resume.
- Double press: clear that slot.
- Without a grid, select LOOP and press K2 to operate slot 1.

The note looper records AUTO-generated notes and notes played from the grid in MIDI or GRID mode. External MIDI input is not currently captured. Timing is recorded as performed and is not beat-quantized.

### Audio looper

Two softcut audio slots are available. Each slot can record up to approximately 30 seconds.

The audio looper receives spre's engine output as well as the norns audio inputs.

- Select the audio looper and slot with the LOOP control.
- First press: record.
- Second press: close the loop on the next clock beat and begin playback.
- Further presses: stop / resume.
- Double press on grid, or K2 + K3, clears the selected slot.
- Direction, speed (×0.25–×4), and level can be changed from the parameter page.

Ending a new audio recording sets FLOCK to zero so the recorded loop can be heard clearly.

## 16×8 grid layout

### AUTO mode

| Grid area | Function |
|---|---|
| Row 1, columns 1–12 | Root pitch class |
| Row 1, columns 15–16 | Octave down / up |
| Row 2, columns 1–16 | Scale selection |
| Row 3, columns 1–8 / 9–15 | FLOCK / BRIT |
| Row 4, columns 1–8 / 9–15 | RAIN / SAT |
| Row 5, columns 1–8 / 9–15 | ATK / TAPE |
| Row 6, columns 1–8 / 9–15 | DEC / DUST |
| Row 7, columns 1–8 / 9–15 | FM / SPREAD |
| Row 8, columns 1–8 / 9–15 | FILTER / INTONE |
| Column 16, rows 3–8 | Loop slots 1–6; audio looper uses slots 1–2 |

### MIDI / GRID modes

| Grid area | Function |
|---|---|
| Row 1, columns 1–12 | Root pitch class |
| Row 1, columns 15–16 | Octave down / up |
| Row 2, columns 1–16 | Scale selection |
| Rows 3–8, columns 1–15 | Scale-note keyboard |
| Column 16, rows 3–8 | Loop slots |

The grid directly plays notes in both MIDI and GRID modes.

## Included scales

Minor pentatonic, major pentatonic, major, minor, Dorian, Lydian, Mixolydian, Phrygian, Locrian, Phrygian dominant, blues, whole tone, diminished, Hungarian minor, In Sen, Hirajoshi, Arabic, bebop major, enigmatic, and chromatic.

The norns interface and MIDI CC 20 can access all 20 scales. The 16×8 grid’s second row directly selects the first 16.

## MIDI CC

| CC | Function |
|---:|---|
| 1–12 | FLOCK, RAIN, ATK, DEC, FM, FILTER, BRIT, SAT, TAPE, DUST, SPREAD, INTONE |
| 13 / 14 | Octave down / up when value is above 63 |
| 15 / 16 | SUSTAIN / RELEASE |
| 17 | Filter type |
| 18 | AUTO / MIDI / GRID mode |
| 19 | Root, MIDI notes 48–72 |
| 20 | Scale |
| 21 | Octave shift, −3 to +3 |
| 22 | Melody generator |
| 23 | Note / audio looper selection |
| 24–29 | Loop slots 1–6 when value is above 63 |
| 30 / 31 | Selected audio-loop speed / level |
| 32 | softcut pre-level |
| 33 | Selected audio-loop direction: reverse / forward |

MIDI notes generated by spre are also sent to MIDI port 1 on channel 1.

## Support

spre is free to use. If you enjoy it and would like to support future development, you can [buy me a coffee](https://ko-fi.com/puyoma). Thank you — every cup helps keep the melodies growing.

## Author

Puyoma

## License

MIT License. See [LICENSE](LICENSE).

## Status

Version 1.0. Feedback, bug reports, and recordings are welcome.
