return {

	hotseats = { -- Savefile hotseats, which can be called with simple key combinations, to quickly switch between songs during performance
	
		"default",
		"test",
		"default",
		"default",
		"default",

		"default",
		"default",
		"default",
		"default",
		"default",
		
		"default",
		"default",
		"default",
		"default",
		"default",
		
		"default",
		"default",
		"default",
		"default",
		"default",
		
	},
	
	dirs = { -- User directories
	
		saves = "C:/Users/Christian/Documents/MUSIC_STAGING/", -- The path of the directory that holds the user's savefolders.
	
	},
	
	monome = {
	
		height = 8, -- Monome height (in buttons)
		width = 8, -- Monome width (in buttons)
		
		osctype = 0, -- 0 for MonomeSerial; 1 for serialosc
		osclisten = 8000, -- OSC listen port
		oscsend = 8080, -- OSC send port
	
	},
	
	midi = {
	
		clocktype = "master", -- MIDI CLOCK type ... "master" / "slave" / "thru" / "none" ... Both "master" and "none" will cause Extrovert to generate its own tempo.
	
	},
	
	undo = {
	
		depth = 20, -- Number of steps that the undo-function is capable of reversing. Note: a very large number of steps may cause lag.
	
	},

	gui = {
	
		seq = { -- Sequence-grid rows
		
			height = 10, -- Segment height (in pixels)
			width = 40, -- Segment width (in pixels)
			xmargin = 2, -- Horizontal margins (in pixels)
			ymargin = 4, -- Vertical margins (in pixels)
			
		},
		
		page = { -- Page summary panel
		
			height = 8, -- Seq atom height (in pixels)
			width = 12, -- Seq atom width (in pixels)
			xmargin = 6, -- Horizontal margins (in pixels)
			ymargin = 3, -- Vertical margins (in pixels)
		
		},
			
		editor = { -- Editor panel
		
			cols = 3, -- Number of editor columns
			rows = 36, -- Number of editor rows
			height = 12, -- Row height (in pixels)
			width = { -- Editor row segment widths (in pixels)
				tick = 40, -- Tick segment
				chan = 20, -- Channel segment
				cmd = 40, -- Command segment
				note = 55, -- Note segment
				velo = 30, -- Velocity segment
				dur = 30, -- Duration segment
			},
			xmargin = 3, -- Horizontal margins (in pixels)
			ymargin = 2, -- Vertical margins (in pixels)
			
		},
		
		sidebar = { -- Editor info sidebar
		
			height = 14, -- Tile height (in pixels)
			width = 140, -- Tile width (in pixels)
			xmargin = 3, -- Horizontal margins (in pixels)
			ymargin = 2, -- Vertical margins (in pixels)
			
			tiles = { -- DO NOT CHANGE. Names and data for sidebar buttons in the GUI.
			
				{3, 2, "acceptpiano", "Piano", "extrovert-piano-button"},
				{2, 1, "bpm", "BPM", "extrovert-bpm-button"},
				{2, 1, "clocktype", "CLOCK", "extrovert-clock-button"},
				{3, 1, "key", "Seq", "extrovert-sequence-button"},
				{3, 3, "pointer", "Tick", "extrovert-tick-button"},
				{3, 2, "spacing", "Space", "extrovert-spacing-button"},
				{3, 2, "quant", "Quant", "extrovert-quant-button"},
				{2, 1, "octave", "Octave", "extrovert-octave-button"},
				{2, 2, "channel", "CHAN", "extrovert-chan-button"},
				{2, 2, "command", "CMD", "extrovert-cmd-button"},
				{2, 1, "velocity", "VELO", "extrovert-velo-button"},
				{2, 2, "duration", "DUR", "extrovert-dur-button"},
				
			},
			
		},
		
		color = { -- GUI colors, arranged as such: {R, G, B}
		
			{50, 50, 50}, -- GUI background pane
			{130, 20, 20}, -- Editor BG 1 (main color 1)
			{105, 20, 105}, -- Editor BG 2 (main color 2)
			{70, 70, 70}, -- Editor BG 3 (neutral)
			{235, 235, 235}, -- Editor Text
			{200, 50, 50}, -- Grid BG 1 (main color 1)
			{50, 50, 200}, -- Grid BG 2 (main color 2)
			{235, 235, 30}, -- Grid BG 3 (activity color)
			{120, 120, 120}, -- Grid BG 4 (neutral)
			
		},
		
	},
	
	keynames = { -- Buttons that are used in the editor as a computer-keyboard-piano, indexed by the notes they represent
		"z", "s", "x", "d", "c", "v", "g", "b", "h", "n", "j", "m",
		{",", "q"},
		{"l", "2"},
		"w", "3", "e", "r", "5", "t", "6", "y", "7", "u", "i", "9", "o", "0", "p",
	},

	commands = { -- Keychord combinations for commands
	
		RECORD = {
			"Escape",
		},
	
		LOAD = {
			"Shift",
			"Tab",
			"Return",
		},
		
		SAVE = {
			"Shift",
			"Tab",
			"~",
			"|",
		},
		
		UNDO = {
			"Shift",
			"Tab",
			"Z",
		},
		
		REDO = {
			"Shift",
			"Tab",
			"Y",
		},
		
		SET_COPY_POINT_1 = {
			"Shift",
			"<",
		},
		
		SET_COPY_POINT_2 = {
			"Shift",
			">",
		},
		
		UNSET_COPY_POINTS = {
			"Shift",
			"?",
		},
		
		CUT = {
			"Shift",
			"Tab",
			"X",
		},
		
		COPY = {
			"Shift",
			"Tab",
			"C",
		},
		
		PASTE = {
			"Shift",
			"Tab",
			"V",
		},
		
		FRIENDLY_VIEW_TOGGLE = {
			"Shift",
			"M",
		},
		
		NAVIGATE_PREVPAGE = {
			"Prior",
		},

		NAVIGATE_NEXTPAGE = {
			"Next",
		},

		NAVIGATE_UP = {
			"Up",
		},
		
		NAVIGATE_DOWN = {
			"Down",
		},
		
		NAVIGATE_HOME = {
			"Home",
		},
		
		NAVIGATE_INVERSE = {
			"End",
		},
		
		NOTE_DELETE = {
			"Delete",
		},
		
		SPACE_INSERT = {
			"BackSpace",
		},
		
		SPACE_DELETE = {
			"Shift",
			"Delete",
		},
		
		KEY_PREV = {
			"Left",
		},
		
		KEY_NEXT = {
			"Right",
		},
		
		KEY_ACROSS_LEFT = {
			"Shift",
			"Left",
		},
		
		KEY_ACROSS_RIGHT = {
			"Shift",
			"Right",
		},
		
		MOVE_SEQ_UP = {
			"Shift",
			"Tab",
			"Up",
		},
		
		MOVE_SEQ_DOWN = {
			"Shift",
			"Tab",
			"Down",
		},
		
		MOVE_SEQ_LEFT = {
			"Shift",
			"Tab",
			"Left",
		},
		
		MOVE_SEQ_RIGHT = {
			"Shift",
			"Tab",
			"Right",
		},
		
		SPACING_INC = {
			"Shift",
			"Up",
		},

		SPACING_DEC = {
			"Shift",
			"Down",
		},
		
		QUANTIZATION_INC = {
			"Shift",
			"Prior",
		},

		QUANTIZATION_DEC = {
			"Shift",
			"Next",
		},
		
		CHANNEL_INC = {
			"'",
		},
		
		CHANNEL_DEC = {
			";",
		},
		
		VELOCITY_INC1 = {
			"=",
		},
		
		VELOCITY_DEC1 = {
			"-",
		},
		
		VELOCITY_INC10 = {
			"Shift",
			"+",
		},
		
		VELOCITY_DEC10 = {
			"Shift",
			"_",
		},
		
		DURATION_INC = {
			"Shift",
			"Tab",
			"+",
		},
		
		DURATION_DEC = {
			"Shift",
			"Tab",
			"_",
		},
		
		OCTAVE_INC = {
			"]",
		},
		
		OCTAVE_DEC = {
			"[",
		},
		
		COMMAND_INC = {
			"/",
		},
		
		COMMAND_DEC = {
			".",
		},
		
		MOVE_NOTE_BACK = {
			"Shift",
			"T",
		},
		
		MOVE_NOTE_FORWARD = {
			"Shift",
			"Y",
		},
		
		MOVE_ALL_NOTES_BACK = {
			"Shift",
			"U",
		},
		
		MOVE_ALL_NOTES_FORWARD = {
			"Shift",
			"I",
		},
		
		MOVE_CHANNEL_DOWN = {
			"Shift",
			"W",
		},
		
		MOVE_CHANNEL_UP = {
			"Shift",
			"Q",
		},
		
		MOVE_PITCH_DOWN = {
			"Shift",
			"A",
		},
		
		MOVE_PITCH_UP = {
			"Shift",
			"S",
		},
		
		MOVE_VELOCITY_DOWN = {
			"Shift",
			"Z",
		},
		
		MOVE_VELOCITY_UP = {
			"Shift",
			"V",
		},
		
		MOVE_DURATION_DOWN = {
			"Shift",
			"Tab",
			"A",
		},
		
		MOVE_DURATION_UP = {
			"Shift",
			"Tab",
			"S",
		},
		
		MOVE_ALL_CHANNELS_DOWN = {
			"Shift",
			"E",
		},
		
		MOVE_ALL_CHANNELS_UP = {
			"Shift",
			"R",
		},
		
		MOVE_ALL_PITCHES_DOWN = {
			"Shift",
			"D",
		},
		
		MOVE_ALL_PITCHES_UP = {
			"Shift",
			"F",
		},
		
		MOVE_ALL_VELOCITIES_DOWN = {
			"Shift",
			"C",
		},
		
		MOVE_ALL_VELOCITIES_UP = {
			"Shift",
			"V",
		},
		
		MOVE_ALL_DURATIONS_DOWN = {
			"Shift",
			"Tab",
			"D",
		},
		
		MOVE_ALL_DURATIONS_UP = {
			"Shift",
			"Tab",
			"F",
		},
		
	},
	
	-- Hotseat keychord combinations. In order from 1 to 20.
	hotseatcmds = {
	
		{"Shift", "!"},
		{"Shift", "@"},
		{"Shift", "#"},
		{"Shift", "$"},
		{"Shift", "%"},
		
		{"Shift", "^"},
		{"Shift", "&"},
		{"Shift", "*"},
		{"Shift", "("},
		{"Shift", ")"},
		
		{"Shift", "Tab", "!"},
		{"Shift", "Tab", "@"},
		{"Shift", "Tab", "#"},
		{"Shift", "Tab", "$"},
		{"Shift", "Tab", "%"},
		
		{"Shift", "Tab", "^"},
		{"Shift", "Tab", "&"},
		{"Shift", "Tab", "*"},
		{"Shift", "Tab", "("},
		{"Shift", "Tab", ")"},
	
	},
	
	-- DO NOT CHANGE. Table of references and args that joins the command names to their corresponding functions.
	cmdfunctions = {
	
		RECORD = { "togglePianoRecording" },
	
		SAVE = { "saveData" },
		LOAD = { "loadData" },
	
		NAVIGATE_UP = { "moveToRelativePoint", -1 },
		NAVIGATE_DOWN = { "moveToRelativePoint", 1 },
		NAVIGATE_PREVPAGE = { "moveByPage", -1 },
		NAVIGATE_NEXTPAGE = { "moveByPage", 1 },
		NAVIGATE_HOME = { "moveToPoint", 1 },
		NAVIGATE_INVERSE = { "moveToInversePoint" },
		
		KEY_PREV = { "moveToRelativeKey", -1 },
		KEY_NEXT = { "moveToRelativeKey", 1 },
		KEY_ACROSS_LEFT = { "moveKeyAcross", -1 },
		KEY_ACROSS_RIGHT = { "moveKeyAcross", 1 },
		
		MOVE_SEQ_UP = { "moveSequence", -1 },
		MOVE_SEQ_DOWN = { "moveSequence", 1 },
		MOVE_SEQ_LEFT = { "moveSequenceAcross", -1 },
		MOVE_SEQ_RIGHT = { "moveSequenceAcross", 1 },
	
		FRIENDLY_VIEW_TOGGLE = { "toggleFriendlyMode" },
		
		UNDO = { "undo" },
		REDO = { "redo" },
		
		SET_COPY_POINT_1 = { "setUpperCopyPoint" },
		SET_COPY_POINT_2 = { "setLowerCopyPoint" },
		UNSET_COPY_POINTS = { "unsetCopyPoints" },
		CUT = { "cutSequence" },
		COPY = { "copySequence" },
		PASTE = { "pasteSequence" },
		
		NOTE_DELETE = { "deleteCurrentNote" },
		
		SPACE_INSERT = { "addSpaceToSequence" },
		SPACE_DELETE = { "deleteSpaceFromSequence" },
		
		SPACING_DEC = { "shiftSpacing", -1 },
		SPACING_INC = { "shiftSpacing", 1 },
		
		QUANTIZATION_DEC = { "shiftQuant", -1 },
		QUANTIZATION_INC = { "shiftQuant", 1 },
		
		DURATION_DEC = { "shiftDuration", -1 },
		DURATION_INC = { "shiftDuration", 1 },
		
		COMMAND_DEC = { "shiftCommand", -1 },
		COMMAND_INC = { "shiftCommand", 1 },
		
		CHANNEL_DEC = { "shiftChannel", -1 },
		CHANNEL_INC = { "shiftChannel", 1 },
		
		VELOCITY_DEC1 = { "shiftVelocity", -1 },
		VELOCITY_INC1 = { "shiftVelocity", 1 },
		VELOCITY_DEC10 = { "shiftVelocity", -10 },
		VELOCITY_INC10 = { "shiftVelocity", 10 },
		
		OCTAVE_DEC = { "shiftOctave", -1 },
		OCTAVE_INC = { "shiftOctave", 1 },
		
		MOVE_NOTE_BACK = { "moveNote", -1 },
		MOVE_NOTE_FORWARD = { "moveNote", 1 },
		MOVE_ALL_NOTES_BACK = { "moveAllNotes", -1 },
		MOVE_ALL_NOTES_FORWARD = { "moveAllNotes", 1 },
		
		MOVE_CHANNEL_DOWN = { "moveChannel", -1 },
		MOVE_CHANNEL_UP = { "moveChannel", 1 },
		MOVE_ALL_CHANNELS_DOWN = { "moveAllChannels", -1 },
		MOVE_ALL_CHANNELS_UP = { "moveAllChannels", 1 },
		
		MOVE_PITCH_DOWN = { "movePitch", -1 },
		MOVE_PITCH_UP = { "movePitch", 1 },
		MOVE_ALL_PITCHES_DOWN = { "moveAllPitches", -1 },
		MOVE_ALL_PITCHES_UP = { "moveAllPitches", 1 },
		
		MOVE_VELOCITY_DOWN = { "moveVelocity", -1 },
		MOVE_VELOCITY_UP = { "moveVelocity", 1 },
		MOVE_ALL_VELOCITIES_DOWN = { "moveAllVelocities", -1 },
		MOVE_ALL_VELOCITIES_UP = { "moveAllVelocities", 1 },
		
		MOVE_DURATION_DOWN = { "moveDuration", -1 },
		MOVE_DURATION_UP = { "moveDuration", 1 },
		MOVE_ALL_DURATIONS_DOWN = { "moveAllDurations", -1 },
		MOVE_ALL_DURATIONS_UP = { "moveAllDurations", 1 },
		
	},
	
	-- DO NOT CHANGE. Names of flags that are used to signify control-commands in sequences.
	flagnames = {
	
		"off", -- Toggles whether a sequence should be turned off when pressed. If a page button is pressed instead, that page's sequences will all turn off.
		"gate", -- Toggles whether a given performative command should be interpreted immediately, or on the next quantization-based timing gate.
		"snap", -- Toggles whether to snap to the first tick in a given sub-segment, or continue from within that segment at a position comparable to the current pointer.
		"loop", -- Toggles whether a sequence will merely loop a single button's worth of notes.
		"reverse", -- Toggles whether the sequence will advance in reverse.
		"stutter", -- Causes the previous note to stutter, at 24-tick increments, while the sequence's row is held.
		
		-- NOTE: The slow-flag must be last in the list, because it covers multiple buttons to the right of the others. 
		"slow", -- Slows the rate at which a sequence's ticks progress. False when not in use, else holds slow value.
	
	},
	
	-- DO NOT CHANGE. Numeric values for command-types that the user toggles between.
	cmdnames = {
	
		{ "GBPM", -20 }, -- Global BPM
		{ "LBPM", -10 }, -- Local BPM
		{ "OFF", 128 }, -- MIDI NOTE-OFF
		{ "ON", 144 }, -- MIDI NOTE-ON
		{ "Poly", 160 }, -- MIDI poly-key pressure
		{ "Ctrl", 176 }, -- MIDI control change
		{ "Prog", 192 }, -- MIDI program change
		{ "Pres", 208 }, -- MIDI mono-key pressure
		{ "Bend", 224 }, -- MIDI pitch bend
		{ "Sys", 240 }, -- MIDI system message
	
	},

	-- DO NOT CHANGE. Table of user-readable note values, indexed in ascending order.
	-- Pd keeps the pound sign (#) as a reserved character, and throws a fit if it has to handle them in any manner, so we'll just use flats instead.
	notenames = {
	
		"C",
		"Db",
		"D",
		"Eb",
		"E",
		"F",
		"Gb",
		"G",
		"Ab",
		"A",
		"Bb",
		"B",
		
	},
	
}