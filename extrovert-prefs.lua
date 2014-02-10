return {

	hotseats = { -- Savefile hotseats, which can be called with simple key combinations, to quickly switch between songs during performance
	
		"default",
		"test",
		"rentest",
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
		saves = "C:/Users/Christian/Documents/MUSIC_STAGING/", -- The path of the directory that holds the user's savefiles.
	},

	api = {
		port = 8500, -- Port on which Extrovert listens for commands from any related MIDI-editor programs.
	},
	
	monome = {
	
		height = 8, -- Monome height (in buttons)
		width = 8, -- Monome width (in buttons)
		
		osctype = 0, -- 0 for MonomeSerial; 1 for serialosc
		osclisten = 8000, -- OSC listen port
		oscsend = 8080, -- OSC send port
		
		adc = { -- Table for Monome ADC parameters. ADCs are dials that some Monomes and Arduinomes can have. If you don't know how many ADCs you have, you probably have 0.
		
			{ -- ADC 1
				target = "note", -- Target for the ADC (must be either "note" or "velocity")
				channel = 1, -- MIDI channel affected by the dial
				breadth = 12, -- Breadth of the dial's range
				bottom = -6, -- Bottom of the dial's range, as compared to corresponding note/velocity positions
			},
			
			{ -- ADC 2
				target = "velocity",
				channel = 1,
				breadth = 255,
				bottom = -127,
			},
			
			{ -- ADC 3
				target = "velocity",
				channel = 9,
				breadth = 255,
				bottom = -127,
			},
			
			{ -- ADC 4
				target = "velocity",
				channel = 10,
				breadth = 255,
				bottom = -127,
			},
		
		},
	
	},
	
	seq = {
	
		gatedefault = 192, -- Gating constant, in ticks. Controls how many MIDI ticks will pass between gates, when no sequences are active.
	
	},
	
	midi = {
	
		clocktype = "master", -- MIDI CLOCK type ... "master" / "slave" / "thru" / "none" ... Both "master" and "none" will cause Extrovert to generate its own tempo.
	
	},
	
	undo = {
	
		depth = 20, -- Number of steps that the undo-function is capable of reversing. Note: a very large number of steps may cause lag.
	
	},

	gui = {
	
		seq = { -- Sequence-activity columns
		
			height = 50, -- Segment height (in pixels)
			width = 50, -- Column width (in pixels)
			xmargin = 5, -- Horizontal margins (in pixels)
			ymargin = 2, -- Vertical margins (in pixels)
			
			keyheight = 12, -- Page-key segment height (in pixels)
			
		},
		
		sidebar = { -- Hotseat sidebar
		
			height = 14, -- Tile height (in pixels)
			width = 140, -- Tile width (in pixels)
			xmargin = 3, -- Horizontal margins (in pixels)
			ymargin = 2, -- Vertical margins (in pixels)
			
		},
		
		color = { -- GUI colors, arranged as such: {R, G, B}
		
			{50, 50, 50}, -- GUI background pane
			{130, 20, 20}, -- Hotseat BG 1 (main color 1)
			{105, 20, 105}, -- Hotseat BG 2 (main color 2)
			{70, 70, 70}, -- Hotseat BG 3 (neutral)
			{235, 235, 235}, -- Hotseat Text
			{200, 50, 50}, -- Grid BG 1 (main color 1)
			{50, 50, 200}, -- Grid BG 2 (main color 2)
			{235, 235, 30}, -- Grid BG 3 (activity color)
			{120, 120, 120}, -- Grid BG 4 (neutral)
			
		},
		
	},
	
	commands = { -- Keychord combinations for commands
	
		MIDI_PANIC = {
			"Space",
		},
	
		LOAD = {
			"Shift",
			"Tab",
			"O",
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
	
	-- DO NOT CHANGE. Table of references that joins OSC API commands to their corresponding functions.
	metacommands = {

		-- Keychord commands
		MIDI_PANIC = { "haltAllSustains", "self" },
		LOAD = { "loadMidiFile", "self" },

		-- OSC commands
		buttonpress = { "parseVirtualButtonPress", "self" },
		loadmidi = { "loadMidiFile", "self" },
		testnote = { "parsePianoNote", "self" },

	},
	
}