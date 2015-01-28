
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
-- extrovert-self-guifuncs.lua
-- extrovert-self-metrofuncs.lua
-- extrovert-self-monomefuncs.lua
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

Here's a short overview of the controls, as plotted out on an 8x8 Monome or Monome-compatible grid-controller:

1 1 1 1 1 1 1 1
2 2 2 2 2 2 2 2
3 3 3 3 3 3 3 3
4 4 4 4 4 4 4 4
5 5 5 5 5 5 5 5
6 6 6 6 6 6 6 6
P P P P P P P P
O H L S G G G G

1-6: Sequences within the active page.
-- Tap to trigger the sequence, or to jump to a sub-slice within an already-active sequence.
-- Chord a sequence-button with buttons on the bottommost row for useful sequence-effects! (Described a few lines below)

P: Page buttons.
-- Tab between pages of sequences.
-- Double-tap the active page's button to tab into Overview Mode, where a summary of all loaded sequences is visible. In Overview Mode, one can still use OFF, SWAP, and GATE commands on the visible sequences. To tab out of Overview Mode, simply tap any page button.
-- Page buttons can be chorded with OFF, PITCH, SWAP, GATE, OFF-PITCH, OFF-GATE, and SWAP-GATE.

O: OFF button.
-- Turns a sequence off, by chording OFF with any button on that sequence's row.
-- Can be chorded with GATE, PAGE, and GATE-PAGE.

H: PITCH button.
-- When held down, toggles a new screen, where half of each row is a bitwise value corresponding to pitch-offset. Like so:
-- 8 4 2 1 1 2 4 8
-- The left-side bits are for pitch-down; and right-side bits are for pitch-up. This is applied to all pitch-values of all notes in the sequence, and fully reversible.
-- OFF chord: Tap a sequence-row to reset that sequence's pitch-value to default.
-- PAGE chord: Sets a given pitch-mod byte for all sequences in the active page. The page-button, here, corresponds to a pitch-bit on the active page, rather than that button's usual page! Be aware!
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
