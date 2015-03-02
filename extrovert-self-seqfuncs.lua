
return {
	
	-- Check whether a seq's incoming gate-value divides cleanly into the global tick
	checkGateMatch = function(self, s)

		-- If the seq has no incoming gate, that defaults to a match
		if not self.seq[s].incoming.gate then
			return true
		end

		-- If the global tick doesn't correspond to a sequence's incoming GATE size, then there is no match, so return false
		local bound = self.seq[(self.groove and self.g.seqnum) or 1].total
		local curgate = math.floor(self.gridx * (self.tick / bound))
		local longchunk = bound / self.gridx
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

		local bound = self.seq[(self.groove and self.g.seqnum) or 1].total -- Get current boundary for sequence-looping

		self.tick = (self.tick % bound) + 1 -- Increment global tick, bounded by global gate-size

		if self.groove then -- If Groove Mode is active...

			self:clearGrooveTick() -- Clear notes from the tick if any of the Groove Mode erase-commands are active

			-- If the groove-seq has looped around, automatically reset the pointers of all other active seqs
			if self.tick == 1 then
				for i = 1, #self.seq do
					self.seq[i].pointer = self.seq[i].pointer and 1
				end
			end

			-- Check currently-active Groove-seq for eraseable notes, and erase them if applicable
			local s = self.g.seqnum
			local p = self.seq[s].pointer
			if self.seq[s].tick[p] then
				for i = #self.seq[s].tick[p], 1, -1 do
					if self.g.chanerase then
						if self.seq[s].tick[p][i][1] == self.g.channum then
							table.remove(self.seq[s].tick[p], i)
						end
					elseif self.g.erase then
						table.remove(self.seq[s].tick[p], i)
					end
				end
			end

		end

		-- If the GATE button isn't held, and the current tick is the first tick in a new column, update the GATE counting buttons
		if (not self.slice.gate)
		and (((self.tick - 1) % (bound / self.gridx)) == 0)
		then
			self:queueGUI("sendGateCountButtons")
		end

		self:decayAllSustains() -- Decay all currently-active sustains

		-- Send all regular commands within all sequences, and check against longseq
		for i = 1, (self.gridy - 2) * self.gridx do
			self:iterateSequence(i)
		end

	end,

	-- Iterate through a sequence's incoming flags, increase its tick pointer under certain conditions, and send off all relevant notes
	iterateSequence = function(self, s)

		local ticks = self.seq[s].total
		local chunk = ticks / self.gridx

		-- Get the current column, or false if there is no active pointer, for later comparison
		local oldcol = self.seq[s].pointer and math.ceil(math.max(1, self.seq[s].pointer - 1) / self.gridx)

		-- If the sequence has no incoming gate, or it matches the global tick, parse its incoming command
		if (not self.seq[s].incoming.gate) or self:checkGateMatch(s) then

			-- Set the sequence's gate-flag to false, because it is either being fulfilled, or empty
			self.seq[s].incoming.gate = false

			-- If any commands are set...
			if self.seq[s].incoming.cmd then

				-- Get the sequence's incoming command
				local c = table.remove(self.seq[s].incoming.cmd, 1)
				local args = self.seq[s].incoming.cmd

				local swapsend = false
				if c == "parsePressSwap" then
					swapsend = ((args[1] == s) and args[2]) or args[1]
				end

				-- Parse the sequence's incoming command
				self[c](self, unpack(args))

				-- Set the seq's incoming-command to false
				self.seq[s].incoming.cmd = false

				-- Queue whatever GUI updates might apply
				if swapsend then
					self:queueGUI("updateSeqButton", swapsend)
					self:queueGUI("sendMetaSeqRow", swapsend)
				end
				self:queueGUI("updateSeqButton", s)

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

		-- If not in Groove Mode...
		if not self.groove then

			-- If the seq's active column has shifted or been emptied, send an updated sequence row to the Monome apparatus
			local newcol = self.seq[s].pointer and math.ceil(math.max(1, self.seq[s].pointer - 1) / self.gridx)
			if not self.slice.pitch then
				if newcol ~= oldcol then
					self:queueGUI("sendMetaSeqRow", s)
				end
			end

		end

	end,

	-- Build a meta version of a sequence's tick-table, based on its SCATTER values
	buildScatterTable = function(self, s)

		if #self.seq[s].sfactors == 0 then
			self.seq[s].metaticks = {}
			return nil
		end

		local ticks = self.seq[s].total
		local tempnotes = {}
		local shiftnotes = {}

		-- Copy all commands from the original sequence, and store extra info on NOTE commands
		for k, v in pairs(self.seq[s].tick) do
			for _, vv in pairs(v) do
				if vv[2] == 144 then -- If this is a NOTE, increase NOTE-counter, and store its tempnotes-index
					table.insert(tempnotes, {k, deepCopy(vv)})
				else -- Else, for non-NOTE commands, put them straight into the meta-sequence
					self.seq[s].metatick[k] = self.seq[s].metatick[k] or {} -- Build the tick's table if it's empty
					table.insert(self.seq[s].metatick[k], deepCopy(vv)) -- Copy every command into a tempnotes table
				end
			end
		end

		local limit = math.max(1, #tempnotes * (1 - self.seq[s].samount))

		while #tempnotes > limit do
			local pnote = table.remove(tempnotes, math.random(1, #tempnotes)) -- Get random NOTE command to shift
			table.insert(shiftnotes, pnote) -- Put the note into the notes-to-be-shifted table
		end

		-- Put non-shifted tempnotes into the sequence's metatick table
		for _, v in pairs(tempnotes) do
			local tick, note = unpack(v)
			self.seq[s].metatick[tick] = self.seq[s].metatick[tick] or {}
			table.insert(self.seq[s].metatick[tick], note)
		end

		-- Shift the positions of all remaining notes
		for _, v in pairs(shiftnotes) do
			local didput = false -- Track whether a note was successfully placed
			local tick, note = unpack(v) -- Unpack the previously combined note elements
			local fdup = deepCopy(self.seq[s].sfactors) -- Make a copy of seq[s].sfactors, to avoid depopulating the original
			while #fdup > 0 do -- While there are viable distance-factors remaining...
				local factor = table.remove(fdup, math.random(#fdup)) -- Get a random factor
				local dist = self.tpq * factor -- Get a distance-value, of (TPQ * factor)
				local newtick = (((tick + dist) - 1) % ticks) + 1 -- Get the note's new tick-position, wrapping to sequence boundaries
				if not self.seq[s].metatick[newtick] then -- If the tick's metatick slot is empty...
					self.seq[s].metatick[newtick] = {note} -- Build the metatick tick's table, and put the note in there
					didput = true -- Confirm that a note was placed
					break -- Exit the while-loop
				end
			end
			if not didput then -- If a note wasn't successfully placed, then place it in a random factor that overlaps with other note-starts
				local newtick = (((tick + (self.tpq * self.seq[s].sfactors[math.random(#self.seq[s].sfactors)])) - 1) % ticks) + 1
				self.seq[s].metatick[newtick] = self.seq[s].metatick[newtick] or {}
				table.insert(self.seq[s].metatick[newtick], note)
			end
		end

	end,

}
