
return {

	-- Save a MIDI savefile, via the MIDI.lua apparatus
	saveMidiFile = function(self)

		self:stopTempo()

		local score = {}

		-- Get proper save location and filename
		local shortname = self.filename
		if self.filename:sub(-4) ~= ".mid" then
			shortname = shortname .. ".mid"
		end
		local saveloc = self.savepath .. shortname
		print("saveFile: Now saving: " .. saveloc)

		-- For every sequence, translate it to a valid score track
		for tracknum, track in ipairs(self.seq) do

			local sk = #score + 1
			score[sk] = {}

			-- Copy over all notes and cmds to the score-track-table
			for i = 1, track.total do
				if track.tick[i] then
					for _, n in pairs(track.tick[i]) do
						local im = i - 1
						if n[2] == 144 then
							table.insert(score[sk], {'note', im, n[5], n[1], n[3], n[4]})
						elseif n[2] == 160 then
							table.insert(score[sk], {'channel_after_touch', im, n[1], n[3]})
						elseif n[2] == 176 then
							table.insert(score[sk], {'control_change', im, n[1], n[3], n[4]})
						elseif n[2] == 192 then
							table.insert(score[sk], {'patch_change', im, n[1], n[3]})
						elseif n[2] == 208 then
							table.insert(score[sk], {'key_after_touch', im, n[1], n[3], n[4]})
						elseif n[2] == 224 then
							table.insert(score[sk], {'pitch_wheel_change' im, n[1], n[3]})
						end
					end
				end
			end

			-- Insert an end_track command, so MIDI.lua knows how long the sequence is.
			table.insert(score[sk], {'end_track', track.total})

			pd.post("saveMidiFile: copied sequence " .. tracknum .. " to save-table. " .. #score[tracknum] .. " items!")

		end

		-- Insert tempo information in the first track,
		-- and the TPQ value in the first score-table entry, as per MIDI.lua spec.
		local outbpm = 60000000 / self.bpm
		table.insert(score, 1, self.tpq)
		table.insert(score[2], 1, {'time_signature', 0, 4, 4, self.tpq, 8})
		table.insert(score[2], 2, {'set_tempo', 0, outbpm})
		print("saveFile: BPM " .. self.bpm .. " :: TPQ " .. self.tpq .. " :: uSPQ " .. outbpm)

		-- Save the score into a MIDI file within the savefolder
		local midifile = io.open(saveloc, 'w')
		if midifile == nil then
			pd.post("Could not save file! Filename contains invalid characters, or is in a location that could not be opened!")
			return nil
		end
		midifile:write(MIDI.score2midi(score))
		midifile:close()

		pd.post("Saved " .. (#score - 1) .. " track" .. (((#score ~= 2) and "s") or "") .. " to file: " .. shortname)

		print("saveFile: saved " .. (#score - 1) .. " sequences to file \"" .. saveloc .. "\"!")

		self:startTempo()

	end,
	
	-- Load a MIDI savefile, via the MIDI.lua apparatus
	loadMidiFile = function(self)

		self:stopTempo() -- Stop the tempo-metronome

		local score, stats = {}, {}
		local bpm, tpq = false, false

		-- Get the MIDI file's full path and name
		local fileloc = self.savepath .. self.filename
		if fileloc:sub(-4) ~= ".mid" then
			fileloc = fileloc .. ".mid"
		end
		pd.post("Now loading: " .. fileloc)
			
		-- Try to open the MIDI file
		local midifile = io.open(fileloc, 'r')
		if midifile ~= nil then
			score = MIDI.midi2score(midifile:read('*all'))
			midifile:close()
			stats = MIDI.score2stats(score)
			tpq = table.remove(score, 1)
		else -- If the file doesn't exist, throw an error and end the function
			pd.post("Could not load file: file does not exist!")
			self:startTempo() -- Start the tempo system again
			return nil
		end

		-- Reset all sequences, so that if the savefile doesn't contain enough sequences, there won't be any leftover data from the previous song
		self:resetAllSequences()

		pd.post("Tracks in file: " .. #score)

		for tracknum, track in ipairs(score) do -- Read every track in the MIDI file's score table

			-- If there are more tracks than sequence-tables, break from the loop
			if tracknum > #self.seq then
				pd.post("Tried to load track " .. tracknum .. ", but max allowed seqs is " .. #self.seq)
				break
			end

			pd.post("Loading track " .. tracknum .. "...")

			local outtab = {}
			local endpoint = 0

			for k, v in pairs(track) do -- Read every command in a track's sub-table

				local vplus = v[2] + 1

				if v[1] == "end_track" then
					endpoint = math.max(endpoint, v[2])
				elseif v[1] == "text_event" then
					endpoint = math.max(endpoint, v[2])
				end

				-- Convert various values into their Extrovert counterparts
				if v[1] == "note" then
					v[3] = math.max(1, v[3])
					v[5] = v[5] or 40
					endpoint = math.max(endpoint, v[2] + v[3])
					outtab[vplus] = outtab[vplus] or {}
					table.insert(outtab[vplus], {v[4], 144, v[5], v[6], v[3]})
				elseif v[1] == "channel_after_touch" then
					endpoint = math.max(endpoint, vplus)
					outtab[vplus] = outtab[vplus] or {}
					table.insert(outtab[vplus], {v[3], 160, v[4]})
				elseif v[1] == "control_change" then
					endpoint = math.max(endpoint, vplus)
					outtab[vplus] = outtab[vplus] or {}
					table.insert(outtab[vplus], {v[3], 176, v[4], v[5]})
				elseif v[1] == "patch_change" then
					endpoint = math.max(endpoint, vplus)
					outtab[vplus] = outtab[vplus] or {}
					table.insert(outtab[vplus], {v[3], 192, v[4]})
				elseif v[1] == "key_after_touch" then
					endpoint = math.max(endpoint, vplus)
					outtab[vplus] = outtab[vplus] or {}
					table.insert(outtab[vplus], {v[3], 208, v[4], v[5]})
				elseif v[1] == "pitch_wheel_change" then
					endpoint = math.max(endpoint, vplus)
					outtab[vplus] = outtab[vplus] or {}
					table.insert(outtab[vplus], {v[3], 224, v[4]})
				elseif v[1] == "set_tempo" then -- Grab tempo commands
					if v[2] == 0 then -- Set global tempo
						bpm = bpm or (60000000 / v[3])
					else -- Insert local tempo command into sequence
						endpoint = math.max(endpoint, vplus)
						outtab[vplus] = outtab[vplus] or {}
						table.insert(outtab[vplus], {0, -10, 60000000 / v[3], 0, 0})
					end
				elseif v[1] == "track_name" then -- Post the track's name
					pd.post("Track name: " .. v[3])
				else
					pd.post("Discarded unsupported command: " .. v[1])
				end
				
			end

			-- Insert padding ticks, to a value that is either modulo the Monome width, or modulo the Ticks-Per-Beat value
			local padtobeat = self.prefs.file.padding == 1
			if (endpoint % self.gridx) ~= 0 then
				if padtobeat then
					endpoint = endpoint + ((tpq * 4) - (endpoint % (tpq * 4)))
				else
					endpoint = endpoint + (self.gridx - (endpoint % self.gridx))
				end
			end

			-- Transfer the loaded sequence-table into the global sequences
			self.seq[tracknum].tick = outtab
			self.seq[tracknum].total = endpoint

			-- Print information about the sequence
			local beatsnum = roundNum((endpoint / (tpq * 4)), 2)
			if (beatsnum % 1) ~= 0 then
				beatsnum = "~" .. beatsnum
			end
			pd.post("Loaded sequence " .. tracknum .. " ::: page " .. math.ceil(tracknum / (self.gridy - 2)) .. ", row " .. (((tracknum - 1) % (self.gridy - 2)) + 1) .. " ::: " .. beatsnum .. " beats")

		end
		
		-- Set BPM and TPQ to their respective first captured values, or defaults if no values were captured
		self.bpm = bpm or 120
		self.tpq = tpq or 24

		-- Reset global tick
		self.tick = 1
		
		pd.post("Loaded savefile \"" .. fileloc .. "\"!")
		pd.post("Beats Per Minute: " .. self.bpm)
		pd.post("Ticks Per Beat: " .. self.tpq)

		self:propagateBPM() -- Propagate the new BPM value

		-- Queue changes to the GUI elements that might have changed
		self:queueGUI("sendMetaGrid")
		self:queueGUI("sendGateCountButtons")
		self:queueGUI("updateSeqGrid")
		
		self:startTempo() -- Start the tempo system again

	end,

	-- Toggle to a saveload filename within the hotseats list
	toggleToHotseat = function(self, seat)
		local fn = self.hotseats[seat]
		if fn:sub(-4) ~= ".mid" then
			fn = fn . ".mid"
		end
		self.filename = fn
		pd.post("Saveload hotseat: " .. seat .. ": " .. self.hotseats[seat] .. " (" .. fn .. ")")
		self:queueGUI("updateHotseatBar")
	end,

	-- Analyze an incoming command name, and invoke its corresponding function and arguments
	parseFunctionCommand = function(self, ...)

		local name = table.remove(arg, 1)
		local items = {}

		if self.metacommands[name] ~= nil then -- Get the command's name, and self-arg (or lack thereof)
			items = deepCopy(self.metacommands[name], {})
		else -- On invalid name, quit the function
			pd.post("Error: Received unknown command: \"" .. name .. "\"")
			return nil
		end

		local target = table.remove(items, 1) -- Grab the target function-name

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

	-- Assign hotseat commands to the keycommand and function-hash tables
	assignHotseatsToCmds = function(self)
		for k, _ in pairs(self.hotseats) do
			if self.hotseatcmds[k] ~= nil then
				local cmdname = "HOTSEAT_" .. k
				self.commands[cmdname] = self.hotseatcmds[k]
				self.metacommands[cmdname] = {"toggleToHotseat", "self", k}
			end
		end
	end,

	-- Reset a single sequence of MIDI data to an empty, default state
	resetSequence = function(self, i)

		self.seq[i] = {}
		
		self.seq[i].pointer = false

		self.seq[i].pitch = 0 -- Holds the value that modifies the sequence's pitch
		self.seq[i].samount = 0 -- Percent of notes to affect with scattering (value from 0.0 to 1.0)
		self.seq[i].sfactors = {} -- Holds all scatter-factor values that are generated by .stab buttons
		self.seq[i].ptab = {} -- Holds all booleans, each standing for a bit that modifies the sequence's pitch value
		self.seq[i].stab = {} -- Holds all booleans, half standing for scatter value, half for svelo
		for t = 1, self.gridx do
			self.seq[i].ptab[t] = false
			self.seq[i].stab[t] = false
		end
		
		self.seq[i].loop = { -- Holds the sub-loop boundaries
			low = false,
			high = false,
		}

		self.seq[i].ltab = false -- Holds the previous loop-button keystroke, if any
		
		self.seq[i].incoming = { -- Holds all flag changes that will occur upon the next tick, or the next button-gate if a "gate" flag is present
			cmd = false,
			gate = false,
		}
		
		self.seq[i].tick = {} -- Holds all notes in the sequence
		self.seq[i].metatick = {} -- Holds a modified dupliate of the .tick table, to use when SCATTER is active

		self.seq[i].total = self.gridx -- Total number of ticks in the sequence
		
		pd.post("Reset all flags and notes in sequence " .. i)

	end,

	-- Reset all sequences of MIDI data to an empty, default state
	resetAllSequences = function(self)
		for i = 1, self.gridx * (self.gridy - 2) do -- Iterate through all sequence positions, refilling them with default settings
			self:resetSequence(i)
		end
	end,

}
