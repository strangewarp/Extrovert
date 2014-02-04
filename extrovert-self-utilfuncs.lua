return {
	
	-- Load a MIDI savefile folder, via the MIDI.lua apparatus
	loadMidiFile = function(self)

		self:stopTempo() -- Stop the tempo system, if applicable

		local tab, stats = {}, {}
		local bpm, tpq = false, false

		-- Get the MIDI file's full path and name
		local fileloc = self.savepath .. self.hotseats[self.activeseat] .. ".mid"
		pd.post("Now loading: " .. fileloc)
			
		-- Try to open the MIDI file
		local midifile = io.open(fileloc, 'r')
		if midifile ~= nil then

			tab = MIDI.midi2score(midifile:read('*all'))
			midifile:close()

			stats = MIDI.score2stats(tab)
			tpq = table.remove(tab, 1)

		else -- If the file doesn't exist, throw an error and end the function
			pd.post("Could not load file: file does not exist!")
			self:startTempo() -- Start the tempo system again
			return nil
		end
		
		for tracknum, track in ipairs(tab) do -- Read every track in the MIDI file's score table

			-- If there are more tracks than sequence-tables, break from the loop
			if tracknum > #self.seq then
				do break end
			end

			local outtab = {}

			for k, v in ipairs(track) do -- Read every command in a track's sub-table
			
				-- Convert various values into their Extrovert counterparts
				if v[1] == "note" then
					table.insert(outtab[v[2]], {v[4], 144, v[5], v[6], v[3]})
				elseif v[1] == "channel_after_touch" then
					table.insert(outtab[v[2]], {v[3], 160, v[4], 0, 0})
				elseif v[1] == "control_change" then
					table.insert(outtab[v[2]], {v[3], 176, v[4], v[5], 0})
				elseif v[1] == "patch_change" then
					table.insert(outtab[v[2]], {v[3], 192, v[4], 0, 0})
				elseif v[1] == "key_after_touch" then
					table.insert(outtab[v[2]], {v[3], 208, v[4], v[5], 0})
				elseif v[1] == "pitch_wheel_change" then
					table.insert(outtab[v[2]], {v[3], 224, v[4], 0, 0})
				elseif v[1] == "set_tempo" then -- Grab tempo commands
					if v[2] == 0 then -- Set global tempo
						bpm = bpm or (60000000 / v[3])
					else -- Insert local tempo command into sequence
						table.insert(outtab[v[2]], {0, -10, 60000000 / v[3], 0, 0})
					end
				else
					pd.post("Discarded unsupported command: " .. v[1])
				end
				
			end

			-- Insert padding ticks at the end of the sequence, so it fits the Monome-width without the potential for button-based rounding errors
			while (#outtab % self.gridx) ~= 0 do
				table.insert(outtab, {})
			end
			
			self.seq[tracknum].tick = outtab

			pd.post("Loaded sequence " .. i .. ": ~" .. roundNum((#outtab / tpq) / 4, 2) .. " beats")

		end
		
		-- Set BPM and TPQ to their respective first captured values, or defaults if no values were captured
		self.bpm = bpm or 120
		self.tpq = tpq or 24
		
		pd.post("Loaded savefolder /" .. self.hotseats[self.activeseat] .. "/!")
		pd.post("Beats Per Minute:" .. self.bpm)
		pd.post("Ticks Per Beat:" .. self.tpq)

		self:propagateBPM() -- Propagate the new BPM value
		
		self:startTempo() -- Start the tempo system again

	end,

	-- Toggle to a saveload filename within the hotseats list
	toggleToHotseat = function(self, seat)
		self.activeseat = seat
		pd.post("Saveload hotseat: " .. self.activeseat .. ": " .. self.hotseats[self.activeseat])
		self:updateHotseatBar()
	end,

	-- Analyze an incoming command name, and invoke its corresponding function and arguments
	parseFunctionCommand = function(self, ...)

		local name = table.remove(arg, 1)
		local items = {}

		if self.cmdnames[name] ~= nil then -- Get the command's name, and self-arg (or lack thereof)
			items = self.cmdnames[name]
		else -- On invalid name, quit the function
			pd.post("Error: Received unknown command: \"" .. name .. "\"")
			return nil
		end

		-- Grab the target function-name
		local target = table.remove(items, 1)

		-- Combine the internal and external args
		for k, v in ipairs(arg) do
			table.insert(items, v)
		end

		pd.post("Received command: \"" .. name .. "\" -- args: " .. table.concat(items, " "))

		-- Replace "self" with self, if applicable, and invoke the function with correct shape
		if items[1] == "self" then
			items[1] = self
			self[target](unpack(items))
		else
			_G[target](unpack(items))
		end

	end,

	-- Send a test-note to the example-note apparatus
	parsePianoNote = function(self, n)
		-- Get values, and bound outliers within their respective ranges
		local chan = n[1] % 16
		local note = n[2] % 128
		local velo = n[3] % 128
		pd.send("extrovert-examplenote", "list", {note, velo, chan}) -- Send the example note
	end,

	-- Assign hotseat commands to the keycommand and function-hash tables
	assignHotseatsToCmds = function(self)
		for k, _ in pairs(self.hotseats) do
			if self.hotseatcmds[k] ~= nil then
				local cmdname = "HOTSEAT_" .. k
				self.cmdnames[cmdname] = {"toggleToHotseat", k}
			end
		end
	end,

	-- Reset a single sequence of MIDI data to an empty, default state
	resetSequence = function(self, i)

		self.seq[i] = {}
		
		self.seq[i].pointer = 1
		self.seq[i].active = false
		
		self.seq[i].loop = {
			low = 1,
			high = self.gridx,
		}
		
		self.seq[i].incoming = {} -- Holds all flag changes that will occur upon the next tick, or the next button-gate if a "gate" flag is present
		
		self.seq[i].tick = {}
		for t = 1, self.gridx do -- Insert dummy ticks
			self.seq[i].tick[t] = {}
		end
		
		pd.post("Reset all flags and notes in sequence " .. i)

	end,

	-- Reset all sequences of MIDI data to an empty, default state
	resetAllSequences = function(self)
		for i = 1, self.gridx * (self.gridy - 2) do -- Iterate through all sequence positions, refilling them with default settings
			self:resetSequence(i)
		end
	end,

}