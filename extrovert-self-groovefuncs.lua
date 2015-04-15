
return {

	-- Toggle/untoggle Groove Mode	
	toggleGrooveMode = function(self, s)

		if self.groove then -- If toggling out of Groove Mode...

			-- Get the page that the active groove-sequence belongs to
			self.page = math.ceil(self.g.seqnum / (self.gridy * 2))

			-- Untoggle whatever Groove Mode command-buttons might be being pressed
			self.g.move = false
			self.g.rec = false
			self.g.recheld = false
			self.g.chanerase = false
			self.g.erase = false
			self.g.gate = false

			-- Unset all pitch-keypress data
			for k, v in pairs(self.g.pitch) do
				self.g.pitch[k] = numToBools(0, false, 1, self.gridx)
			end

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

		self:queueGUI("sendMetaGrid") -- Send upper rows
		self:queueGUI("sendPageRow") -- Send page row, if applicable

	end,

	-- Set the currently active Groove Mode length, and sanitize all related data-structures
	seqToGrooveLength = function(self, s)
		self.seq[s].total = self.g.lennum * (self.tpq * 4) -- Make the seq's total ticks into a multiple of the TPQ*4 (beat) value
		self.seq[s].pointer = (((self.seq[s].pointer or 1) - 1) % self.seq[s].total) + 1 -- Wrap sequence's pointer to the total-ticks range
		self.tick = self.seq[s].pointer -- Match the global tick to the local pointer
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

		-- If this is a NOTE command, and velorand is toggled, apply a random velocity
		if (cmd[1] == 144) and self.g.velorand then
			cmd[3] = math.random(1, self.g.velonum)
		end

		local beat = self.tpq * 4
		local q1 = self.g.quantnum + 1
		local quant = math.max(1, roundNum(beat / q1))
		local dur = math.ceil((beat / q1) / (self.g.durnum + 1))

		table.insert(cmd, 1, self.g.channum) -- Put the channel-number into the command's first index
		table.insert(cmd, dur) -- Put the duration-number into the command's last index

		self:noteParse(cmd) -- Send an example-note, regardless of whether recording is enabled

		pd.post("GROOVE NOTE: "..table.concat(cmd," "))--debugging

		if self.g.rec then -- If Groove Mode is toggled to RECORD...

			-- Get the correct insert-tick, with quantization applied
			local s = self.g.seqnum
			local p = self.seq[s].pointer
			local pminus = p - 1
			local tot = self.seq[s].total
			local lessamt = pminus % quant
			local moreamt = quant - lessamt
			local dist = ((moreamt < lessamt) and moreamt) or -lessamt
			local t = wrapNum(p + dist, 1, tot)

			-- Build the tick's table, if it's nil
			self.seq[s].tick[t] = self.seq[s].tick[t] or {}

			-- If any commands exactly match the new command, remove them
			local notes = self.seq[s].tick[t]
			for i = #notes, 1, -1 do
				local match = true
				for k, v in pairs(notes[i]) do
					if (not cmd[k]) or (v ~= cmd[k]) then
						match = false
						break
					end
				end
				if match then
					table.remove(self.seq[s].tick[t], i)
				end
			end

			-- Insert the command that was generated at the start of the function
			table.insert(self.seq[s].tick[t], cmd)

			pd.post("GROOVE NOTE INSERT:")--debugging
			pd.post("seq "..s)
			pd.post("pointer "..p)
			pd.post("total "..tot)
			pd.post("chunk-size"..quant)
			pd.post("lessamt "..lessamt)
			pd.post("moreamt "..moreamt)
			pd.post("dist "..dist)
			pd.post("tick "..t)

		end

	end,

	-- Insert the current Groove Mode note, built from a Groove Mode pitch keypress (non-incoming-MIDI-triggered)
	insertDefaultGrooveNote = function(self, x, y)
		local obase = self.g.octavenum * 12
		local offset = ((x - 1) * 2) + (2 - y)
		local pitch = wrapNum(obase + offset, 0, 127)
		self:insertGrooveNote(144, pitch, self.g.velonum)
	end,

	-- Clear notes from the tick if any of the Groove Mode erase-commands are active
	clearGrooveTick = function(self)

		if self.g.erase or self.g.chanerase then

			local chan = self.g.chanerase and self.g.channum
			local s = self.g.seqnum
			local p = self.seq[s].pointer

			if self.g.chanerase then -- debugging
				pd.post("erase chan: "..self.g.channum)--debugging
			end--debugging

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

	-- Move a Groove Mode sequence to a new position in the sequence-order by a distance of 1 or -1
	moveGrooveSeq = function(self, dist)

		if (dist ~= -1) and (dist ~= 1) then
			return nil
		end

		local i = self.g.seqnum
		local i2 = wrapNum(i + dist, 1, #self.seq)
		self.seq[i], self.seq[i2] = deepCopy(self.seq[i2]), deepCopy(self.seq[i])

		self.g.seqnum = i2

	end,

}
