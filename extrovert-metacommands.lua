return {
	
	-- Table of references that joins OSC API commands to their corresponding functions.
	metacommands = {

		-- Keychord commands
		LOAD = { "loadMidiFile", "self" }, -- Load the MIDI savefile in the currently-active hotseat (alias of "loadmidi")
		MIDI_PANIC = { "haltAllSustains", "self" }, -- Halt all presently-playing MIDI notes

		-- OSC commands
		buttonpress = { "parseVirtualButtonPress", "self" }, -- Simulate a Monome button-press
		loadmidi = { "loadMidiFile", "self" }, -- Load the MIDI savefile in the currently-active hotseat (alias of "LOAD")
		testnote = { "parsePianoNote", "self" }, -- Play a test-note via the MIDI-OUT apparatus

	},

}