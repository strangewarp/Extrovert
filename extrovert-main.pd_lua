
local Extrovert = pd.Class:new():register("extrovert-main")

MIDI = require('MIDI')

local generalfuncs = require('extrovert-generalfuncs')
local guifuncs = require('extrovert-guifuncs')
local monomefuncs = require('extrovert-monomefuncs')

local selfapifuncs = require('extrovert-self-apifuncs')
local selfctrlfuncs = require('extrovert-self-ctrlfuncs')
local selfguifuncs = require('extrovert-self-guifuncs')
local selflongfuncs = require('extrovert-self-longfuncs')
local selfmetrofuncs = require('extrovert-self-metrofuncs')
local selfmonomefuncs = require('extrovert-self-monomefuncs')
local selfnotefuncs = require('extrovert-self-notefuncs')
local selfseqfuncs = require('extrovert-self-seqfuncs')
local selfutilfuncs = require('extrovert-self-utilfuncs')

local metacommands = require('extrovert-metacommands')

generalfuncs.funcsToNewContext(generalfuncs, _G)

funcsToNewContext(guifuncs, _G)
funcsToNewContext(monomefuncs, _G)

function Extrovert:initialize(sel, atoms)

	-- 1. Loadbang
	-- 2. Key commands
	-- 3. Monome button
	-- 4. Monome ADC
	-- 5. MIDI CLOCK IN
	-- 6. External OSC commands (non-Monome)
	self.inlets = 6
	
	-- No outlets. Everything is done through pd.send() instead.
	self.outlets = 0
	
	funcsToNewContext(selfapifuncs, Extrovert)
	funcsToNewContext(selfctrlfuncs, Extrovert)
	funcsToNewContext(selfguifuncs, Extrovert)
	funcsToNewContext(selflongfuncs, Extrovert)
	funcsToNewContext(selfmetrofuncs, Extrovert)
	funcsToNewContext(selfmonomefuncs, Extrovert)
	funcsToNewContext(selfnotefuncs, Extrovert)
	funcsToNewContext(selfseqfuncs, Extrovert)
	funcsToNewContext(selfutilfuncs, Extrovert)

	funcsToNewContext(metacommands, Extrovert) -- Get the list of function-references triggered by their corresponding commands

	self.prefs = self:dofile("extrovert-prefs.lua") -- Get user prefs to reflect the user's particular setup
	
	self.ctrlflags = { -- Holds all control-flags, which correspond to the control-buttons on the Monome
		off = false,
		trig = false,
		loop = false,
		swap = false,
		gate = false, -- Gating commands fill the rest of the control-row. This will hold a number to differentiate between them, or false when not active
	}
	
	self.commands = self.prefs.commands -- Get the user-defined list of computer-keychord commands
	
	self.savepath = self.prefs.dirs.saves -- User-defined absolute path that contains all savefolders
	if self.savepath:sub(-1) ~= "/" then
		self.savepath = self.savepath .. "/"
	end
	
	self.hotseats = self.prefs.hotseats -- List of savefile hotseats
	self.hotseatcmds = self.prefs.hotseatcmds -- List of hotseat keycommands
	self.activeseat = 1 -- Currently active hotseat
	
	self.color = {}
	for k, v in ipairs(self.prefs.gui.color) do -- Split the user-defined colors into regular, light, and dark variants
		table.insert(self.color, modColor(v))
	end
	
	self.gridx = self.prefs.monome.width -- Monome X buttons
	self.gridy = self.prefs.monome.height -- Monome Y buttons
	
	self.adc = self.prefs.monome.adc -- Table of all ADC preferences
	self.dial = {} -- Holds live position data for all ADCs
	for k, _ in pairs(self.adc) do
		self.dial[k] = 0.5 -- Set default values for ADC dials
	end
	
	self.kb = {} -- Keeps track of which keys are currently pressed on the computer-keyboard

	self.gatedefault = self.prefs.seq.gatedefault -- Holds the number of ticks that will elapse between gates, when no sequences are active
	self.longseq = nil -- Sequence with the longest active loop
	self.longticks = self.gatedefault -- Number of ticks in the longest active loop
	
	self.bpm = 120 -- Internal BPM value, for when MIDI CLOCK is not slaved to an external source
	self.tpq = 24 -- Ticks per quarter note
	
	self.overview = false -- Tracks whether Overview Mode is toggled or not. Causes changes to the Monome display, and to keypress behaviors
	
	self.clocktype = self.prefs.midi.clocktype -- User-defined MIDI CLOCK type.
	self.acceptpulse = false -- Tracks whether to accept MIDI CLOCK pulses
	
	self.byteignore = 0 -- Tracks how many inoming raw MIDI bytes to ignore, during the reception of MIDI SONG POSITION commands
	
	self.tick = 1 -- Current clock tick in the sequencer
	
	self.page = 1 -- Active page, for tabbing between pages of sequences in performance

	self.swap = false -- Holds the index of a swap-seq selected by the SWAP command
	self.pageswap = false -- Holds the index of a page-number selected by the SWAP command
	
	self.seq = {} -- Holds all MIDI sequence data, and all sequences' performance-related flags
	
	self.sustain = {} -- Holds all sustain-tracking data
	for i = 0, 15 do
		self.sustain[i] = {}
	end

	return true
	
end

-- Finalize function: only activated when Extrovert is closed down
function Extrovert:finalize()

	self:haltAllSustains() -- Send noteoffs corresponding to all active sustains

	darkenAllButtons() -- Darken all Monome buttons, so that they don't stay lit after the program shuts down

end

-- Run through Extrovert's on-startup functions, after receiving a bang from [loadbang].
-- Some of these use pd.send(), which can't be used from within initialize() or postinitialize() (or from within any other functions thereby invoked), so this is a workaround.
function Extrovert:in_1_bang()

	self:assignHotseatsToCmds()
	
	self:resetAllSequences() -- Populate the self.seq table with default data
	
	self:buildGUI()
	
	self:populateGUI()
	
	self:startMonome()
	
	self:startClock()
	
	self:propagateBPM()
	
	self:startTempo()

	self:startAPI()
	
	self:parseVirtualButtonPress(1, self.gridy - 1) -- Spoof a page-button keypress, so that a page is properly active
	self:parseVirtualButtonPress(1, self.gridy - 1) -- Spoof a second page-button keypress, so Overview Mode is untoggled

end

-- Parse incoming commands from the computer-keyboard
function Extrovert:in_2_list(key)

	-- Chop the "_L" and "_R" off incoming Shift keystrokes
	if key[2]:sub(1, 5) == "Shift" then
		key[2] = "Shift"
	end
	
	if key[1] == 1 then -- On key-down...
	
		if self.kb[key[2]] == nil then -- If the key isn't already set, set it
			self.kb[key[2]] = key[2]
		end
		
		-- Compare the current pressed keys with the list of command keychords
		for k, v in pairs(self.commands) do
		
			-- Organize the command-list data properly for comparison
			local compare = {}
			for _, vv in pairs(v) do
				compare[vv] = vv
			end
			
			if crossCompare(self.kb, compare) then -- If the current keypresses match a command's keychord, clear the non-chorded keys and activate the command
			
				-- Unset all non-chording keys
				for k, _ in pairs(self.kb) do
					if (k ~= "Shift")
					and (k ~= "Tab")
					then
						self.kb[k] = nil
					end
				end
				
				self:parseFunctionCommand(k)
				
				break -- Break from the outer for loop, after finding the correct command
				
			end
		
		end
		
	else -- On key-up...
		self.kb[key[2]] = nil -- Unset the key
	end

end

-- Parse Monome button commands
function Extrovert:in_3_list(t)

	-- Convert from 0-indexing to 1-indexing
	local x = t[1] + 1
	local y = t[2] + 1
	local s = t[3]

	self:parseButtonPress(x, y, s)
	
end

-- Parse Monome ADC commands
function Extrovert:in_4_list(t)

	local knob = t[1] + 1 -- Shift 0-indexing to 1-indexing

	if (next(self.adc) ~= nil) -- If there are ADCs in the user-prefs file...
	and (self.adc[knob] ~= nil) -- And there are prefs for the ADC whose command is being received...
	then -- Set the relevant self.dial value to the current encoder position
		self.dial[knob] = t[2]
	end

end

-- Parse incoming tempo ticks or MIDI CLOCK commands
function Extrovert:in_5(sel, m)

	if sel == "bang" then -- Accept [metro]-based tempo ticks
	
		if self.clocktype == "master" then
			pd.send("extrovert-clock-out", "float", {248})
		end

		self:iterateAllSequences()
	
	elseif sel == "float" then -- Accept MIDI CLOCK tempo commands
	
		if self.byteignore > 0 then -- If incoming bytes are slated to be ignored...
		
			self.byteignore = self.byteignore - 1 -- Decrement the number of bytes to be ignored, after receiving one

		elseif m == 242 then -- MIDI SONG POSITION
		
			self.tick = 0
			self.byteignore = 2
	
		elseif m == 248 then -- MIDI CLOCK PULSE
		
			if self.tick == 0 then -- Compensate for the initial dummy tick
				self.tick = 1
			else -- Accept regular clock ticks
				
				self:iterateAllSequences()
			
			end
		
		elseif m == 250 then -- MIDI CLOCK START
		
			if not self.acceptpulse then
				self.tick = 0 -- Set tick to 0 instead of 1, in order to compensate for the initial dummy downbeat
				self.acceptpulse = true
			end
			
			pd.post("Received MIDI CLOCK START")
			
		elseif m == 251 then -- MIDI CLOCK CONTINUE
		
			if not self.acceptpulse then
				self.acceptpulse = true
			end
			
			pd.post("Received MIDI CLOCK CONTINUE")
		
		elseif m == 252 then -- MIDI CLOCK END
		
			if self.acceptpulse then
				self.acceptpulse = false
			end
			
			pd.post("Received MIDI CLOCK END")
		
		end
		
		if self.clocktype == "thru" then -- Send the MIDI CLOCK messages onward, if the clocktype is set to THRU
			pd.send("extrovert-clock-out", "float", {m})
		end
		
	end
	
end

-- Parse and execute external OSC commands, from external MIDI editor programs designed to work alongside Extrovert
function Extrovert:in_6_list(t)

	pd.post("Received Extrovert-OSC command: " .. table.concat(t, ", "))

	self:parseOSC(t)

end
