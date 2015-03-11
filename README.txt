
Extrovert

A MIDI beatslicing sequencer for the Monome.

Installation:

1. Put the following files in your /pd/extras folder:
-- extrovert-generalfuncs.lua
-- extrovert-guifuncs.lua
-- extrovert-main.pd_lua
-- extrovert-metacommands.lua
-- extrovert-monomefuncs.lua
-- extrovert-self-ctrlfuncs.lua
-- extrovert-self-groovefuncs.lua
-- extrovert-self-guifuncs.lua
-- extrovert-self-metrofuncs.lua
-- extrovert-self-monomeparsefuncs.lua
-- extrovert-self-monomesendfuncs.lua
-- extrovert-self-notefuncs.lua
-- extrovert-self-seqfuncs.lua
-- extrovert-self-utilfuncs.lua
-- MIDI.lua

2. Put the following files into whatever directory you want, preferably somewhere adjacent to your music files:
-- extrovert.pd
-- extrovert-makecolor.pd
-- extrovert-prefs.lua

3. Open extrovert-prefs.lua, and change the variables depending on your setup. Important lines include:
	A. saves = "C:/Users/Christian/Documents/MUSIC_STAGING/", -- The path of the directory that holds the user's savefiles.
	-- Right now, my save-directory is in there. Put your save-directory in there instead!
	B. osctype = 0, -- 0 for MonomeSerial; 1 for serialosc
	C. osclisten = 8000, -- OSC listen port
	D. oscsend = 8080, -- OSC send port

4. In serialosc, MonomeSerial, or whatever you're using, set your app name to "/extrovert", and make sure the listen/send ports match.

5. Now open up extrovert.pd in Puredata 0.43.4-extended, enter a filename or load a hotseat, and have yourself some Extrovert!

6. Every track in a given MIDI file corresponds to an Extrovert sequence.
-- Sequences can contain notes from multiple MIDI channels, or even overlapping note-ons for the same channel and pitch. Extrovert's sustain-tracking system is pretty robust.
-- If a MIDI track's length (e.g. the position of its end-track command) isn't a multiple of the Monome-grid's X-width, odd behavior might occur.

Here's a short overview of the controls:

SLICE MODE:
1 1 1 1 1 1 1 1
2 2 2 2 2 2 2 2
3 3 3 3 3 3 3 3
4 4 4 4 4 4 4 4
5 5 5 5 5 5 5 5
6 6 6 6 6 6 6 6
P P P P P P P P
O H L S G G G G

OVERVIEW MODE:
s s s s s s s s
s s s s s s s s
s s s s s s s s
s s s s s s s s
s s s s s s s s
s s s s s s s s
p p p p p p p p
O H L S G G G G

Slice Mode is Extrovert's default view. It is designed for beatslicing, with each of several rows filled by sequences laid out horizontally, and then a row to tab between pages of sequences, and then a row of various control-buttons.

Overview Mode is an extension of Slice Mode, where every sequence is collapsed into a single button, so that they are all visible at once, but not slice-able.

1-6: Sequences within the active page.
-- Tap to trigger the sequence, or to jump to a sub-slice within an already-active sequence.
-- Chord a sequence-button with buttons on the bottommost row for useful sequence-effects! (Described a few lines below)

s: A whole sequence, represented by a single button in Overview Mode.
-- Control-commands can be applied to sequences in Overview Mode, but if the command relies on some aspect of slice-view (e.g. LOOP, PITCH, and SCATTER), it will act as though the first button in a Slice Mode row was pressed. GATE, SWAP, OFF, and the combinations thereof will work as intended, though.

P: Page buttons.
-- Tab between pages of sequences.
-- Double-tap the active page's button to tab into Overview Mode, where a summary of all loaded sequences is visible. In Overview Mode, one can still use OFF, SWAP, and GATE commands on the visible sequences. To tab out of Overview Mode, simply tap any page button.
-- Page buttons can be chorded with OFF, PITCH, SWAP, GATE, OFF-PITCH, OFF-GATE, and SWAP-GATE.

O: OFF button.
-- Turns a sequence off, by chording OFF with any button on that sequence's row.
-- Can be chorded with GATE, PAGE, and GATE-PAGE.

H: PITCH button.
-- When held down, toggles a new screen, where half of each row is a bitwise value corresponding to pitch-offset. Like so:
-- -8 -4 -2 -1 1 2 4 8
-- The left-side bits are for pitch-down; and right-side bits are for pitch-up. This is applied to all pitch-values of all notes in the sequence, and fully reversible.
-- OFF chord: Tap a sequence-row to reset that sequence's pitch-value to default.
-- PAGE chord: Sets a given pitch-bit, in a column across all sequences in the active page. The page-button, here, corresponds to a pitch-bit on the active page, rather than that button's usual page! Be aware!
-- OFF-PAGE chord: Resets pitch-values to default for all sequences in the active page.

L: LOOP button.
-- When held down, if two sub-buttons are touched in a currently-playing sequence, the sequence's activity will be bounded between those two buttons.

S: SWAP button.
-- When held down, if two sequences or two page-buttons are touched, the activity of their contents will be switched.
-- Can be chorded with GATE, PAGE, and GATE-PAGE.

G: GATE button.
-- When not held down, displays the global gate-counter.
-- When held down, a given sequence or command won't be triggered until the global gate-counter reaches a corresponding value.
-- Gate buttons are arranged in a bitwise layout, but are not chordable with each other, for gate-value ambiguity reasons. Layout is as such:
-- 1 2 4 8
-- On a wider Monome, the layout should default to: 1 2 4 8 16 16 16 16 ... etc.
-- Can be chorded with OFF, SWAP, PAGE, OFF-PAGE, and SWAP-PAGE.

SLICE/OVERVIEW SPECIAL COMMANDS:

SHIFT GATE: Chord OFF, SWAP, and GATE buttons.
-- Advances the global GATE counter by a number of chunks corresponding to the pressed GATE button.

SCATTER: Chord PITCH and LOOP buttons.
-- When held down, toggles a new screen, where every button represents a bitwise value. The left half of each row represents a row's scatter amount, while the right half represents the allowed scatter distances. Like so:
-- scatter amount 8 4 2 1 | 1 2 4 8 scatter distance
-- "Scatter amount": The SCATTER command will be applied to a fraction of notes in the sequence equal to scatter/((2^floor(gridX/2))-1) ... Basically: the higher the scatter amount, the more notes get scattered.
-- "Scatter distance": Creates a set of distances, which are multiplied by the song's TPQ value to find a new note-position for scattered notes. Values will be combined, and flipped into negative values as well: e.g. if distances of [1, 4, 8] are active, then distances of [1, 4, 8, -1, -4, -8, 3, 5, 7, 9, 12, -3, -5, -7, -9, -12] will be generated.
-- OFF chord: Tap a sequence-row to reset that sequence's scatter-values to default.
-- PAGE chord: Sets a given scatter-bit, in a column across all sequences in the active page. The page-button, here, corresponds to a scatter-bit on the active page, rather than the button's usual page! Be aware!
-- OFF-PAGE chord: Resets scatter-values to default for all sequences in the active page.

GROOVE MODE:
p p p p p p p H
v v v v v v v L
d d d d d d d d
c c c c h h h h
l l l l l l l l
q q q q q q q q
s s s s s s s s
T R C E G G G G

Groove Mode allows the user to compose or modify sequences inside of Extrovert, in a manner comparable to the workflow of certain grooveboxes.

p: Note pitch. Little-endian binary value, 0-127.

v: Note base velocity. Little-endian binary value, 1-127.

d: Note duration, in ticks. Little-endian binary value, 1-255.

c: MIDI channel. Big-endian binary value, 0-15.

h: Humanize-velocity rate. Applies a random value to the velocity of every note entered. Little-endian binary value, 0 or 16-128.

l: Sequence length, in beats (tpq*4). Little-endian binary value, 1-128.

q: Quantize amount. Entered notes will snap to the nearest tick that is a multiple of q. Little-endian binary value, 1-255.

s: Currently active sequence for Groove Mode editing. Little-endian binary value, 1 to ((gridy-2)*gridx)

T: Test or track the current note.

R: Toggle whether notes triggered by "T" are being recorded.

C: Erase notes on the current channel, as the play-pointer moves through the sequence.

E: Erase all notes, as the play-pointer moves through the sequence.

G: Local gate-counter. Chord these buttons to tab to a given portion of the active sequence.

H: Move sequence to higher index.

L: Move sequence to lower index.

KEYBOARD COMMANDS:

MIDI PANIC: Space
-- Ends all current MIDI sustains.

LOAD HOTSEAT FILE: Shift-Tab-O
-- Loads currently selected hotseat-file.

SWITCH TO HOTSEAT FILE: Shift-number, or Shift-Tab-number
-- Switches between hotseat files.
