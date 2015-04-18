
local Extrovert = pd.Class:new():register("extrovert-main")

MIDI = require('MIDI')

local generalfuncs = require('extrovert-generalfuncs')
local guifuncs = require('extrovert-guifuncs')
local monomefuncs = require('extrovert-monomefuncs')

local selfctrlfuncs = require('extrovert-self-ctrlfuncs')
local selfgroovefuncs = require('extrovert-self-groovefuncs')
local selfguifuncs = require('extrovert-self-guifuncs')
local selfmetrofuncs = require('extrovert-self-metrofuncs')
local selfmonomeparsefuncs = require('extrovert-self-monomeparsefuncs')
local selfmonomesendfuncs = require('extrovert-self-monomesendfuncs')
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
	-- 5. Metronome-ticks in
	-- 6. MIDI-IN
	-- 7. Custom filename
	-- 8. Load-file-bang
	-- 9. Save-file-bang
	-- 10. BPM number
	self.inlets = 10
	
	-- No outlets. Everything is done through pd.send() instead.
	self.outlets = 0
	
	funcsToNewContext(selfctrlfuncs, Extrovert)
	funcsToNewContext(selfgroovefuncs, Extrovert)
	funcsToNewContext(selfguifuncs, Extrovert)
	funcsToNewContext(selfmetrofuncs, Extrovert)
	funcsToNewContext(selfmonomeparsefuncs, Extrovert)
	funcsToNewContext(selfmonomesendfuncs, Extrovert)
	funcsToNewContext(selfnotefuncs, Extrovert)
	funcsToNewContext(selfseqfuncs, Extrovert)
	funcsToNewContext(selfutilfuncs, Extrovert)

	funcsToNewContext(metacommands, Extrovert) -- Get the list of function-references triggered by their corresponding commands

	self.prefs = self:dofile("extrovert-prefs.lua") -- Get user prefs to reflect the user's particular setup
	
	self.slice = { -- Holds all control-flags, which correspond to the control-buttons on the Monome
		off = false,
		pitch = false,
		loop = false,
		swap = false,
		gate = false, -- Gating commands fill the rest of the control-row. This will hold a number to differentiate between them, or false when not active
	}
	
	self.commands = self.prefs.commands -- Get the user-defined list of computer-keychord commands
	
	self.savepath = self.prefs.dirs.saves -- User-defined absolute path that contains all savefiles
	if self.savepath:sub(-1) ~= "/" then
		self.savepath = self.savepath .. "/"
	end

	self.activeseat = 1 -- Currently active hotseat
	self.hotseats = self.prefs.hotseats -- List of savefile hotseats
	self.hotseatcmds = self.prefs.hotseatcmds -- List of hotseat keycommands
	
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

	self.slave = self.prefs.midi.slave
	self.thru = self.prefs.midi.thru
	self.clockthru = self.prefs.midi.clockthru
	self.loopticks = self.midi.loopticks or false
	
	self.kb = {} -- Keeps track of which keys are currently pressed on the computer-keyboard

	self.bpm = 120 -- Internal BPM value, for when MIDI CLOCK is not slaved to an external source
	self.tpq = 24 -- Ticks per quarter note
	
	self.tick = 1 -- Current clock tick in the sequencer
	
	self.page = 1 -- Active page, for tabbing between pages of sequences in performance

	self.swap = false -- Holds the index of a swap-seq selected by the SWAP command
	self.pageswap = false -- Holds the index of a page-number selected by the SWAP command
	
	self.seq = {} -- Holds all MIDI sequence data, and all sequences' performance-related flags
	
	self.sustain = {} -- Holds all sustain-tracking data
	for i = 0, 15 do
		self.sustain[i] = {}
	end

	self.g = { -- All groove mode flags and binary-value tables
		velo = {}, -- Note velocity
		velonum = 127,
		octave = {}, -- Octave number
		octavenum = 3,
		dur = {}, -- Note duration
		durnum = 15,
		chan = {}, -- MIDI channel
		channum = 0,
		len = {}, -- Track length (len * tpq * 4)
		lennum = 1,
		seq = {}, -- Sequence number
		seqnum = 1,
		quant = {}, -- Quantize amount
		quantnum = 0,
		pitch = { -- Holds all keypresses on both rows of pitch-keys
			{bool = {}, num = 0},
			{bool = {}, num = 0},
		},
		velorand = false, -- Flag for: randomize velocity values within current velonum-limit?
		move = false, -- Flag for: is "move sequence to absolute slot" button being pressed?
		rec = false, -- Flag for: recording new notes enabled? (toggle button)
		recheld = false, -- Flag for: is the rec-button being held?
		chanerase = false, -- Flag for: erasing notes only in the active channel ofthe active sequence
		erase = false, -- Flag for: currently erasing notes in the active sequence as it plays through? (press-and-hold button)
		gate = false, -- Flag for: is a GATE button being pressed?
	}
	self.g.pitch[1].bool = numToBools(0, false, 1, 8)
	self.g.pitch[2].bool = numToBools(0, false, 1, 8)
	self.g.velo = numToBools(self.g.velonum, false, 1, 7)
	self.g.octave = numToBools(self.g.octavenum, false, 1, 4)
	self.g.dur = numToBools(self.g.durnum, false, 1, 4)
	self.g.chan = numToBools(self.g.channum, false, 1, 4)
	self.g.len = numToBools(self.g.lennum, false, 1, 8)
	self.g.seq = numToBools(self.g.seqnum, false, 1, 8)
	self.g.quant = numToBools(self.g.quantnum, false, 1, 4)

	self.g.seq[1] = true

	self.groove = false -- Tracks whether Groove Mode is toggled or not.
	self.overview = false -- Tracks whether Overview Mode is toggled or not.
	
	-- Holds all currently-tabbed GUI update commands, with their function-name and args listed flatly, e.g.:
	-- [1] = {"sendSeqRow", seqnum}
	-- [2] = {"updateSeqButton", snum}
	self.guiqueue = {}

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
	
	self:propagateBPM()
	
	self:startTempo()

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

	self:updateGUI() -- Update ay changed GUI elements

end

-- Parse Monome button commands
function Extrovert:in_3_list(t)

	-- Convert from 0-indexing to 1-indexing
	local x = t[1] + 1
	local y = t[2] + 1
	local s = t[3]

	self:parseButtonPress(x, y, s)
	
	self:updateGUI() -- Update ay changed GUI elements

end

-- Parse Monome ADC commands
function Extrovert:in_4_list(t)

	local knob = t[1] + 1 -- Shift 0-indexing to 1-indexing

	if (#self.adc > 0) -- If there are ADCs in the user-prefs file...
	and (self.adc[knob] ~= nil) -- And there are prefs for the ADC whose command is being received...
	then -- Set the relevant self.dial value to the current encoder position
		self.dial[knob] = t[2]
	end

	self:updateGUI() -- Update ay changed GUI elements

end

-- Parse incoming tempo ticks
function Extrovert:in_5(sel, m)

	self:iterateAllSequences()
	
	self:updateGUI() -- Update ay changed GUI elements

end

-- Catch an incoming command from an external MIDI device
function Extrovert:in_6_list(t)

	-- If MIDI THRU is enabled, perform a soft-thru operation with the raw noteSend function
	if self.thru then
		self:noteSend(t)
	end

	-- If not in Groove Mode, finish parsing MIDI-IN
	if not self.groove then
		return nil
	end

	local cmd = table.remove(t, 1) -- Get midi-command type

	if cmd == 'NOTE' then -- MIDI NOTE
		if t[2] > 0 then -- Only accept note-ons
			self.g.pitchnum = t[1] -- Change Groove Mode's pitch-value based on incoming note
			self.g.pitch = numToBools(self.g.pitchnum, false, 1, 8)
			self.g.velonum = t[2] -- Change Groove Mode's velocity-value based on incoming note
			self.g.velo = numToBools(self.g.velonum, false, 1, 8)
			self:queueGUI("sendGrooveBinRows")
			self:insertGrooveNote(144, t[1], t[2])
		end
	elseif cmd == 'CTRL' then -- Control-change
		self:insertGrooveNote(176, t[1], t[2])
	elseif cmd == 'PROG' then -- Program-change
		self:insertGrooveNote(192, t[1])
	elseif cmd == 'PTOU' then -- Poly-touch
		self:insertGrooveNote(160, t[2] or 0, t[3] or 0)
	elseif cmd == 'MTOU' then -- Mono-touch
		self:insertGrooveNote(208, t[2] or 0)
	elseif cmd == 'BEND' then -- Pitch-bend
		self:insertGrooveNote(224, t[2])
	end

end

-- Set a custom filename
function Extrovert:in_7_symbol(s)

	if s:sub(-4) ~= ".mid" then
		s = s .. ".mid"
	end

	for i = #self.hotseats, 2, -1 do
		self.hotseats[i] = self.hotseats[i - 1]
	end

	self.hotseats[1] = s

	self.activeseat = 1

	self:queueGUI("updateHotseatBar")

	self:updateGUI() -- Update ay changed GUI elements

end

-- Load a MIDI file with a user-entered filename
function Extrovert:in_8_bang()

	self:loadMidiFile()

	self:updateGUI() -- Update ay changed GUI elements

end

-- Save to a MIDI file, in the user-supplied directory, with a user-entered filename
function Extrovert:in_9_bang()

	self:saveMidiFile()

	self:updateGUI() -- Update ay changed GUI elements

end

-- Get a new user-defined BPM value
function Extrovert:in_10_float(n)

	self.bpm = n

	self:propagateBPM()

end
