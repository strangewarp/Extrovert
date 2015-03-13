
return {
	
	-- Table of references that joins OSC API commands to their corresponding functions.
	metacommands = {

		-- Keychord commands
		LOAD = { "loadMidiFile", "self" }, -- Load the MIDI savefile whose filename is currently active
		SAVE = { "saveMidiFile", "self" }, -- Save the current sequences to the currently active filename
		MIDI_PANIC = { "haltAllSustains", "self" }, -- Halt all presently-playing MIDI notes

	},

}
