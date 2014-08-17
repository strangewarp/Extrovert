
return {
	
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

		-- Check for the currently longest loop among all of the active sequences
		self:checkForLongestLoop()

	end,

	-- Iterate through a sequence's incoming flags, increase its tick pointer under certain conditions, and send off all relevant notes
	iterateSequence = function(self, s)

		-- If the sequence has incoming flags...
		if next(self.seq[s].incoming) ~= nil then

			-- If the sequence has an incoming GATE flag...
			if self.seq[s].incoming.gate then

				-- If the global tick corresponds to the incoming GATE size, parse the seq's incoming flags
				local curgate = math.floor(self.gridx * (self.tick / self.longticks))
				local longchunk = self.longticks / self.gridx
				local tickmatch = (self.tick - 1) % longchunk
				local gatematch = curgate % self.seq[s].incoming.gate
				if (gatematch == 0) and (tickmatch == 0) then
					self:parseIncomingFlags(s)
				end

			else -- Else, if the sequence doesn't have an incoming GATE flag, parse its incoming flags
				self:parseIncomingFlags(s)
			end

		end

		-- If the sequence is active...		
		if self.seq[s].active then

			-- Get subsection size
			local subsize = #self.seq[s].tick / self.gridx

			-- Get current subsection, and previous subsection
			local newsub = math.ceil(self.gridx * (self.seq[s].pointer / #self.seq[s].tick))
			local oldsub = math.ceil(self.gridx * ((((self.seq[s].pointer - 2) % #self.seq[s].tick) + 1) / #self.seq[s].tick))

			-- Bound newsub and oldsub to subsections within the sequence's loop
			if newsub > self.seq[s].loop.high then
				newsub = self.seq[s].loop.low
			end
			if oldsub < self.seq[s].loop.low then
				oldsub = self.seq[s].loop.high
			end

			-- Increment the pointer within loop boundaries, and then send tick-notes, on every global tick
			local oldpoint = self.seq[s].pointer
			self.seq[s].pointer = (self.seq[s].pointer % (self.seq[s].loop.high * subsize)) + 1
			if self.seq[s].pointer < oldpoint then
				self.seq[s].pointer = ((self.seq[s].loop.low - 1) * subsize) + 1
			end
			self:sendTickNotes(s, self.seq[s].pointer)
		
			-- If the new subsection corresponds to a different button than the previous subsection...
			if newsub ~= oldsub then
				self:sendMetaSeqRow(s) -- Send Monome sequence rows through the meta apparatus
			end

		end
		
	end,

	-- Convert flags in the "incoming" table into a sequence's internal states
	parseIncomingFlags = function(self, s)

		self:swapAllSeqFlags() -- Swap all sequences and pages in the self.swap and self.pageswap tabs

		-- If there's an incoming OFF flag...
		if self.seq[s].incoming.off then

			-- Deactivate the sequence
			self.seq[s].active = false

		else -- Else, if there isn't an incoming OFF flag...
		
			self.seq[s].active = true -- Flag the sequence as active

			-- If a RESUME command was not received, or both RESUME and RANGE commands were received...
			if (not self.seq[s].incoming.resume)
			or (self.seq[s].incoming.resume and self.seq[s].incoming.range)
			then

				-- Get the boundaries; if only one boundary was received, set it as both low and high;
				-- if low is greater than high, flip them; if no boundaries were received, set them to defaults.
				local r = self.seq[s].incoming.range
				self.seq[s].loop.low, self.seq[s].loop.high =
					(r and math.min(r[#r - 1] or r[#r], r[#r])) or 1,
					(r and math.max(r[#r - 1] or r[#r], r[#r])) or self.gridx

			end

			local chunk = #self.seq[s].tick / self.gridx
			local button = self.seq[s].incoming.button
			local point = self.seq[s].pointer or (((button - 1) * chunk) + 1)

			-- If there's an incoming RESUME flag...
			if self.seq[s].incoming.resume then

				local low = self.seq[s].loop.low
				local high = self.seq[s].loop.high
				local col = button or math.ceil(self.seq[s].pointer / self.gridx)
				local range = high - (low - 1)

				-- Transpose the previous pointer position into the incoming button's subsection
				self.seq[s].pointer = ((point - 1) % chunk) + ((((col - low) % range) + low - 1) * chunk) + 1

			else -- Else, change the pointer position to reflect the button-press position

				if button then
					self.seq[s].pointer = point
				end

			end
			
		end

		self.seq[s].incoming = {} -- Empty the incoming table
		
		self:sendMetaSeqRow(s) -- Send Monome sequence rows through the meta apparatus
		
		self:updateSeqButton(s) -- Update the sequence's on-screen GUI button

	end,

	-- Swap the activity and flags of two sequences
	swapSeqFlags = function(self, s1, s2)

		-- Unset SWAP flags
		self.seq[s1].incoming.swap = nil
		self.seq[s2].incoming.swap = nil

		-- Swap range boundaries
		self.seq[s1].loop, self.seq[s2].loop = self.seq[s2].loop, self.seq[s1].loop

		-- Swap sequence activity
		self.seq[s1].active, self.seq[s2].active = self.seq[s2].active, self.seq[s1].active

		-- Swap pointer positions, adjusted against one another's concrete size
		self.seq[s1].pointer, self.seq[s2].pointer =
			math.floor(self.seq[s2].pointer / (#self.seq[s2].tick / #self.seq[s1].tick)),
			math.floor(self.seq[s1].pointer / (#self.seq[s1].tick / #self.seq[s2].tick))

		pd.post(s1..", "..s2) -- debugging

	end,

	-- Swap the LOOP and INCOMING flags, and comparable pointer positions, of every sequence in the SWAP queue, if applicable
	swapAllSeqFlags = function(self)

		-- Swap the activity of two pages' worth of sequences
		if next(self.pageswap) ~= nil
		and ((#self.pageswap) > 1)
		then
			for i = 1, self.gridy - 2 do
				local s = i + ((self.gridy - 2) * (self.pageswap[#self.pageswap - 1] - 1))
				local s2 = i + ((self.gridy - 2) * (self.pageswap[#self.pageswap] - 1))
				self:swapSeqFlags(s, s2)
			end
		end

		-- Swap the activity of all swap-pairs
		if (next(self.swap) ~= nil)
		and (#self.swap[1] > 1)
		then
			for k, v in ipairs(self.swap) do
				if #v == 2 then
					self:swapSeqFlags(v[1], v[2])
				end
			end
		end

		-- Clear the SWAP and PAGESWAP tables only when this function is activated
		self.swap = {}
		self.pageswap = {}

	end,

}
