
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
				self:buildScatterTable(s) -- Build a new SCATTER table on every loop
			end
			if self.seq[s].pointer < (chunk * (low - 1)) then
				self.seq[s].pointer = (chunk * (low - 1)) + 1
			end

		end

		-- If the seq's active column has shifted or been emptied, send an updated sequence row to the Monome apparatus
		local newcol = self.seq[s].pointer and math.ceil(math.max(1, self.seq[s].pointer - 1) / self.gridx)
		if not self.ctrlflags.pitch then
			if newcol ~= oldcol then
				self:sendMetaSeqRow(s)
			end
		end

	end,

	-- Build a meta version of a sequence's tick-table, based on its SCATTER values
	buildScatterTable = function(self, s)

		local seq = self.seq[s]

		if #seq.sfactors == 0 then
			self.seq[s].metaticks = {}
			return nil
		end

		local ticks = #seq.tick
		local tempnotes = {}
		local shiftnotes = {}

		for i = 1, #seq.tick do
			self.seq[s].metatick[i] = {}
		end

		-- Copy all commands from the original sequence, and store extra info on NOTE commands
		for k, v in pairs(self.seq[s].tick) do
			for _, vv in pairs(v) do
				if vv[2] == 144 then -- If this is a NOTE, increase NOTE-counter, and store its tempnotes-index
					table.insert(tempnotes, {k, deepCopy(vv)})
				else -- Else, for non-NOTE commands, put them straight into the meta-sequence
					table.insert(self.seq[s].metatick[k], deepCopy(vv)) -- Copy every command into a tempnotes table
				end
			end
		end

		local limit = math.max(1, #tempnotes * (1 - seq.samount))

		while #tempnotes > limit do
			local pnote = table.remove(tempnotes, math.random(1, #tempnotes)) -- Get random NOTE command to shift
			table.insert(shiftnotes, pnote) -- Put the note into the notes-to-be-shifted table
		end

		-- Put non-shifted tempnotes into the sequence's metatick table
		for _, v in pairs(tempnotes) do
			local tick, note = unpack(v)
			table.insert(self.seq[s].metatick[tick], note)
		end

		-- Shift the positions of all remaining notes
		for _, v in pairs(shiftnotes) do
			local didput = false -- Track whether a note was successfully placed
			local tick, note = unpack(v) -- Unpack the previously combined note elements
			local fdup = deepCopy(seq.sfactors) -- Make a copy of seq.factors, to avoid depopulating the original
			while #fdup > 0 do -- While there are viable distance-factors remaining...
				local factor = table.remove(fdup, math.random(#fdup)) -- Get a random factor
				local dist = self.tpq * factor -- Get a distance-value, of (TPQ * factor)
				local newtick = (((tick + dist) - 1) % ticks) + 1 -- Get the note's new tick-position, wrapping to sequence boundaries
				if #self.seq[s].metatick[newtick] == 0 then -- If the tick's metatick slot is empty...
					table.insert(self.seq[s].metatick[newtick], note) -- Put the note in the metatick tick
					didput = true -- Confirm that a note was placed
					break -- Exit the while-loop
				end
			end
			if not didput then -- If a note wasn't successfully placed, then place it in a random factor that overlaps with other note-starts
				local newtick = (((tick + (self.tpq * seq.sfactors[math.random(#seq.sfactors)])) - 1) % ticks) + 1
				table.insert(self.seq[s].metatick[newtick], note)
			end
		end

	end,

}
