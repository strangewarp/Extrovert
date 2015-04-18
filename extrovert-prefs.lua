return {

	hotseats = { -- Savefile hotseats, which can be called with simple key combinations, to quickly switch between songs during performance
	
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
		"default",
		"default",
		
	},
	
	dirs = { -- User directories
		saves = "C:/Users/Christian/Documents/MUSIC_STAGING/", -- The path of the directory that holds the user's savefiles.
	},

	file = {

		-- 0 to pad a sequence's ticks to a multiple of the Monome-width; 1 to pad them to a multiple of the Ticks-Per-Beat value.
		-- Note: if the Ticks-Per-Beat value is not itself a multiple of the Monome width, setting this value to 1 may cause errors.
		padding = 1,
		
	},

	midi = { -- MIDI options

		slave = true, -- If true, sync Extrovert's clock to external MIDI CLOCK pulses.

		thru = true, -- If true, resend all incoming MIDI messages that are not MIDI CLOCK ticks.

		clockthru = true, -- If true, resend all incoming MIDI CLOCK messages.

		gateloop = 192, -- Number of ticks in the loop for the global GATE-counter. Must be a multiple of grid-width. If false, defaults to ticks in top sequence.

	},

	monome = {
	
		height = 8, -- Monome height (in buttons)
		width = 8, -- Monome width (in buttons)
		
		osctype = 0, -- 0 for MonomeSerial; 1 for serialosc
		osclisten = 8000, -- OSC listen port
		oscsend = 8080, -- OSC send port
		
		adc = { -- Table for Monome ADC parameters. ADCs are dials that some Monomes and Arduinomes can have. If you don't know how many ADCs you have, you probably have 0.
			10, 11, 13, 14, -- MIDI channels affected by each ADC, in order
		},

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

		SAVE = {
			"Shift",
			"Tab",
			"S",
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
	
}