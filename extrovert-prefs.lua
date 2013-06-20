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

	monome = {
	
		height = 8, -- Monome height (in buttons)
		width = 8, -- Monome width (in buttons)
		
		osctype = 0, -- 0 for MonomeSerial; 1 for serialosc
		osclisten = 8000, -- OSC listen port
		oscsend = 8080, -- OSC send port
	
	},
	
	midi = {
	
		clocktype = "master", -- MIDI CLOCK type ... "master" / "slave" / "none" ... Both "master" and "none" will cause Extrovert to generate its own tempo.
	
	},
	
	undo = {
	
		depth = 50, -- Number of steps that the undo-function is capable of reversing. Note: a very large number of steps may cause lag.
	
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
				note = 50, -- Note segment
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
			
			tiles = { -- DO NOT CHANGE. Names of sidebar buttons in the GUI.
			
				{2, 1, "BPM", "extrovert-bpm-button"},
				{2, 2, "Clock", "extrovert-clock-button"},
				{3, 2, "Quant", "extrovert-quant-button"},
				{3, 1, "Octave", "extrovert-octave-button"},
				{3, 2, "Seq", "extrovert-seq-button"},
				{2, 1, "TICK", "extrovert-tick-button"},
				{2, 2, "CHAN", "extrovert-chan-button"},
				{2, 1, "CMD", "extrovert-cmd-button"},
				{2, 2, "VELO", "extrovert-velo-button"},
				{2, 1, "DUR", "extrovert-dur-button"},
				
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
	
		LOAD = {
			"Shift",
			"Tab",
			"Return",
		},
		
		SAVE = {
			"Shift",
			"?",
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
			"Tab",
			"!",
		},
		
		SET_COPY_POINT_2 = {
			"Shift",
			"Tab",
			"@",
		},
		
		UNSET_COPY_POINTS = {
			"Shift",
			"Tab",
			"#",
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
		
		VIEW_MODE_TOGGLE = {
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
		
		KEY_ACROSS_RIGHT = {
			"Shift",
			"Right",
		},
		
		KEY_ACROSS_LEFT = {
			"Shift",
			"Left",
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
		
		SHIFT_CHANNEL_DOWN = {
			"Shift",
			"W",
		},
		
		SHIFT_CHANNEL_UP = {
			"Shift",
			"Q",
		},
		
		SHIFT_PITCH_DOWN = {
			"Shift",
			"A",
		},
		
		SHIFT_PITCH_UP = {
			"Shift",
			"S",
		},
		
		SHIFT_VELOCITY_DOWN = {
			"Shift",
			"Z",
		},
		
		SHIFT_VELOCITY_UP = {
			"Shift",
			"X",
		},
		
		SHIFT_ALL_CHANNELS_DOWN = {
			"Shift",
			"E",
		},
		
		SHIFT_ALL_CHANNELS_UP = {
			"Shift",
			"R",
		},
		
		SHIFT_ALL_PITCHES_DOWN = {
			"Shift",
			"D",
		},
		
		SHIFT_ALL_PITCHES_UP = {
			"Shift",
			"F",
		},
		
		SHIFT_ALL_VELOCITY_DOWN = {
			"Shift",
			"C",
		},
		
		SHIFT_ALL_VELOCITY_UP = {
			"Shift",
			"V",
		},
		
		SHIFT_SEQ_UP = {
			"Shift",
			"BackSpace",
			"Up",
		},
		
		SHIFT_SEQ_DOWN = {
			"Shift",
			"BackSpace",
			"Down",
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
	
		NAVIGATE_UP = { "moveToRelativePoint", -1 },
		NAVIGATE_DOWN = { "moveToRelativePoint", 1 },
		NAVIGATE_HOME = { "moveToPoint", 1 },
		NAVIGATE_INVERSE = { "moveToInversePoint" },
		
		
		
		UNDO = { "undo" },
		REDO = { "redo" },
		
		SET_COPY_POINT_1 = { "setUpperCopyPoint" },
		SET_COPY_POINT_2 = { "setLowerCopyPoint" },
		CUT = { "cutSequence" },
		COPY = { "copySequence" },
		PASTE = { "pasteSequence" },
		
		NOTE_DELETE = { "deleteCurrentNote" },
		
		SPACE_INSERT = { "addSpaceToSequence" },
		SPACE_DELETE = { "deleteSpaceFromSequence" },
		
		
		
	
	},
	
	-- DO NOT CHANGE. Numeric values for command-types that the user toggles between.
	cmdnames = {
	
		BPM = -2, -- Global BPM
		OFF = 128, -- MIDI NOTE-OFF
		ON = 144, -- MIDI NOTE-ON
		Poly = 160, -- MIDI poly-key pressure
		Ctrl = 176, -- MIDI control change
		Prog = 192, -- MIDI program change
		Pres = 208, -- MIDI mono-key pressure
		Bend = 224, -- MIDI pitch bend
		Sys = 240, -- MIDI system message
		
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