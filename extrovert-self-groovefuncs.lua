
return {

	-- Toggle/untoggle Groove Mode	
	toggleGrooveMode = function(self, s)

		if self.groove then -- If toggling out of Groove Mode...

			-- Get the page that the active groove-sequence belongs to
			self.page = math.ceil(self.g.seqnum / (self.gridy * 2))

			-- Untoggle whatever Groove Mode command-buttons might be being pressed
			self.g.track = false
			self.g.rec = false
			self.g.chanerase = false
			self.g.erase = false
			self.g.gate = false

		else -- If toggling into Groove Mode...

			-- Untoggle whatever Slice Mode command-buttons might be being pressed
			for k, _ in pairs(self.slice) do
				self.slice[k] = false
			end

			for i = 1, #self.seq do -- Unset all INCOMING and LOOP commands from all sequences
				self.seq[i].incoming = {
					cmd = false,
					gate = false,
				}
				self.seq[i].ltab = false
				self.seq[i].loop = {
					low = false,
					high = false,
				}
				if self.seq[i].pointer then
					self.seq[i].pointer = 1 -- Reset the sequence's internal tick-pointer value, if it's playing
				end
			end

			self:setGrooveSeq(s)

			-- Clear any tabbed swap and pageswap values
			self.swap = false
			self.pageswap = false

		end

		self.tick = 1 -- Reset global tick-counter

		self.groove = not self.groove

		self:queueGUI("sendMetaGrid") -- Send full GUI

	end,

	-- Set the currently active Groove Mode length, and sanitize all related data-structures
	seqToGrooveLength = function(self, s)
		self.seq[s].total = self.g.lennum * (self.tpq * 4) -- Make the seq's total ticks into a multiple of the TPQ*4 (beat) value
		self.seq[s].pointer = (((self.seq[s].pointer or 1) - 1) % self.seq[s].total) + 1 -- Wrap sequence's pointer to the total-ticks range
	end,

	-- Set the currently active Groove Mode seq, and sanitize all related data-structures
	setGrooveSeq = function(self, s)

		self.g.seqnum = s -- Set the user-selected sequence to be the active Groove Mode sequence
		self.g.lennum = math.max(1, math.min(128, math.floor(self.seq[s].total / (self.tpq * 4)))) -- Set length, in beats

		self.g.seq = numToBools(self.g.seqnum, false, 1, self.gridx)
		self.g.len = numToBools(self.g.lennum, false, 1, 128) -- Reflect changed value in len table

		self:seqToGrooveLength(s)

		for i = 1, #self.seq do -- For all sequences...
			self.seq[i].pointer = self.seq[i].pointer and 1 -- If sequence is playing, reset its internal-tick-pointer
		end

		self.tick = 1 -- Reset the global tick

	end,

	-- Insert a Groove Mode note, built from the current Groove Mode MIDI channel, plus an incoming MIDI command
	insertGrooveNote = function(self, ...)

		local cmd = {...}

		-- If this is a NOTE command, apply random humanization to its velocity
		if cmd[1] == 144 then
			cmd[3] = math.max(1, math.min(127, cmd[3] + roundNum((math.random() * self.g.humanizenum) - (self.g.humanizenum / 2))))
		end

		table.insert(cmd, 1, self.g.channum) -- Put the channel-number into the command
		table.insert(cmd, self.g.durnum) -- Put the duration-number into the command

		self:noteParse(cmd) -- Send an example-note, regardless of whether recording is enabled

		pd.post("GROOVE NOTE: "..table.concat(cmd," "))--debugging

		if self.g.rec then -- If Groove Mode is toggled to RECORD...

			-- Get the correct insert-tick, with quantization applied
			local s = self.g.seqnum
			local p = self.seq[s].pointer
			local pminus = p - 1
			local tot = self.seq[s].total
			local quant = math.max(1, roundNum((self.tpq * 4) / self.g.quantnum))
			local chunk = math.max(1, ((quant == 0) and 1) or roundNum(tot / quant))
			local lessamt = pminus % chunk
			local moreamt = chunk - lessamt
			local dist = ((moreamt < lessamt) and moreamt) or -lessamt
			local t = (((p + dist) - 1) % tot) + 1

			-- Build the tick's table, if it's nil
			self.seq[s].tick[t] = self.seq[s].tick[t] or {}

			-- If any commands exactly match the new command, then remove them
			local notes = self.seq[s].tick[t]
			for i = #notes, 1, -1 do
				local match = false
				for k, v in pairs(notes[i]) do
					if v == cmd[k] then
						match = true
						break
					end
				end
				if match then
					table.remove(self.seq[s].tick[t], i)
				end
			end

			-- Insert the command that was generated at the start of the function
			table.insert(self.seq[s].tick[t], cmd)

			pd.post("GROOVE NOTE INSERT:")
			pd.post("seq "..s)
			pd.post("pointer "..p)
			pd.post("total "..tot)
			pd.post("quantize "..quant)
			pd.post("chunk-size"..chunk)
			pd.post("lessamt "..lessamt)
			pd.post("moreamt "..moreamt)
			pd.post("dist "..dist)
			pd.post("tick "..t)

		end

	end,

	-- Insert the current Groove Mode note, built from Groove Mode's current default values (non-incoming-MIDI-triggered)
	insertDefaultGrooveNote = function(self)
		self:insertGrooveNote(144, self.g.pitchnum, self.g.velonum)
	end,

	-- Clear notes from the tick if any of the Groove Mode erase-commands are active
	clearGrooveTick = function(self)

		if self.g.erase or self.g.chanerase then

			local chan = self.g.chanerase and self.g.channum
			local s = self.g.seqnum
			local p = self.seq[s].pointer

			if self.seq[s].tick[p] then -- If there are any commands on the present tick within the active groove sequence...
				for i = #self.seq[s].tick[p], 1, -1 do -- For every command within the tick...
					local note = self.seq[s].tick[p][i]
					if (not chan) or (note[1] == chan) then -- If all channels are being erased, or if this note's channel matches a specific channel being erased...
						table.remove(self.seq[s].tick[p], i) -- Remove the note from the tick
					end
				end
				if #self.seq[s].tick[p] == 0 then -- If tick was emptied of notes...
					self.seq[s].tick[p] = nil -- Unset the tick's table
				end
			end

		end

	end,

}
