
return {
	
	-- Check whether a seq's incoming gate-value divides cleanly into the global tick
	checkGateMatch = function(self, s)

		-- If the seq has no incoming gate, that defaults to a match
		if not self.seq[s].incoming.gate then
			return true
		end

		-- If the global tick doesn't correspond to a sequence's incoming GATE size, then there is no match, so return false
		local curgate = math.floor(self.gridx * (self.tick / self.longticks))
		local longchunk = self.longticks / self.gridx
		local tickmatch = (self.tick - 1) % longchunk
		local gatematch = curgate % self.seq[s].incoming.gate
		if (gatematch ~= 0) or (tickmatch ~= 0) then
			return false
		end

		-- Return true for match, after filtering out non-matches
		return true

	end,

	-- Cycle through all MIDI commands on the active tick within every active sequence
	iterateAllSequences = function(self)

		-- Increment global tick, bounded by global gate-size
		self.tick = (self.tick % self.longticks) + 1

		-- If the GATE button isn't held, and the current tick is the first tick in a new column, update the GATE counting buttons
		if (not self.ctrlflags.gate)
		and (((self.tick - 1) % (self.longticks / self.gridx)) == 0)
		then
			self:sendGateCountButtons()
		end

		-- Decay all currently-active sustains
		self:decayAllSustains()

		-- Send all regular commands within all sequences, and check against longseq
		for i = 1, (self.gridy - 2) * self.gridx do
			self:iterateSequence(i)
		end

	end,

	-- Iterate through a sequence's incoming flags, increase its tick pointer under certain conditions, and send off all relevant notes
	iterateSequence = function(self, s)

		local ticks = #self.seq[s].tick
		local chunk = ticks / self.gridx

		-- Get the current column, or false if there is no active pointer, for later comparison
		local oldcol = self.seq[s].pointer and math.ceil(math.max(1, self.seq[s].pointer - 1) / self.gridx)

		-- If the sequence has no incoming gate, or it matches the global tick, parse its incoming command
		if (not self.seq[s].incoming.gate) or self:checkGateMatch(s) then

			-- Set the sequence's gate-flag to false, because it is either being fulfilled, or empty
			self.seq[s].incoming.gate = false

			-- If any commands are set...
			if self.seq[s].incoming.cmd then

				-- Parse the sequence's incoming command
				local c = table.remove(self.seq[s].incoming.cmd, 1)
				local args = self.seq[s].incoming.cmd
				self[c](self, unpack(args))

				-- Set the seq's incoming-command to false
				self.seq[s].incoming.cmd = false

				self:updateSeqButton(s) -- Update on-screen GUI

			end

		end

		-- If, after the previous changes, the sequence still has an active pointer, then iterate a tick's worth of the sequence
		if self.seq[s].pointer then

			self:sendTickNotes(s, self.seq[s].pointer)

			-- Advance the pointer by 1, and bound it within its loop-range
			self.seq[s].pointer = self.seq[s].pointer + 1
			local oldp = self.seq[s].pointer
			local low = self.seq[s].loop.low or 1
			local high = self.seq[s].loop.high or self.gridx
			if self.seq[s].pointer > (chunk * high) then
				self.seq[s].pointer = self.seq[s].pointer % (chunk * high)
			end
			if self.seq[s].pointer < (chunk * (low - 1)) then
				self.seq[s].pointer = (chunk * (low - 1)) + 1
			end

		end

		-- If the seq's active column has shifted or been emptied, send an updated sequence row to the Monome apparatus
		local newcol = self.seq[s].pointer and math.ceil(math.max(1, self.seq[s].pointer - 1) / self.gridx)
		if newcol ~= oldcol then
			self:sendMetaSeqRow(s)
		end

	end,

}
