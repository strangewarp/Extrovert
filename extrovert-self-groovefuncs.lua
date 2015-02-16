
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

			self.longticks = self.seq[1].total -- Set longticks to match the first sequence

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
			end

			self.g.lennum = math.max(1, math.min(128, math.floor(self.seq[s].total / (self.tpq * 4)))) -- Set length, in beats
			self.seq[s].total = self.g.lennum * (self.tpq * 4) -- Tweak the total ticks in seqs that don't match the TPQ*4 beat-size regime

			self.g.seqnum = s -- Set the user-selected sequnce to be the active Groove Mode sequence

			-- Set the len and seq tables to reflect the changed values
			self.g.len = numToBools(self.g.lennum, false, 1, 128)
			self.g.seq = numToBools(self.g.seqnum, false, 1, self.gridx)

			self.longticks = self.seq[s].total -- Set longticks to match the groove-active sequence

		end

		self.tick = 1 -- Reset global tick-counter

		self.groove = not self.groove

	end,

	-- Insert the current Groove Mode note
	insertGrooveNote = function(self)

		local veloshift = math.max(1, math.min(127, self.g.velonum + roundNum(math.random(0, self.humanizenum) - (self.humanizenum / 2))))

		self:noteParse({self.g.channum, 144, self.g.pitchnum, veloshift, self.g.durnum})

		if self.g.rec then -- If Groove Mode is toggled to RECORD...

			local s = self.g.seqnum
			local p = self.seq[s].pointer
			local pminus = p - 1
			local tot = self.seq[s].total
			local quant = math.max(1, roundNum((self.tpq * 4) / self.g.quantnum))
			local chunk = roundNum(tot / quant)
			local lessamt = pminus % chunk
			local moreamt = chunk - pminus
			local dist = ((moreamt < lessamt) and moreamt) or -lessamt
			local t = (((p + dist) - 1) % tot) + 1

			-- Build the tick's table, if it's nil
			self.seq[s].tick[t] = self.seq[s].tick[t] or {}

			-- If any notes are on the same pitch, tick, and channel, then remove them
			local notes = self.seq[s].tick[t]
			for i = #notes, 1, -1 do
				if (notes[i][3] == self.g.pitchnum) and (notes[i][1] == self.g.channum) then
					table.remove(self.seq[s].tick[t], i)
				end
			end

			table.insert(self.seq[s].tick[t], {self.g.channum, 144, self.g.pitchnum, veloshift, self.g.durnum})

		end

	end,

}
