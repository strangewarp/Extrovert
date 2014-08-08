
return {
	
	-- Convert flags in the "incoming" table into a sequence's internal states
	parseIncomingFlags = function(self, s)

		self:swapAllSeqFlags() -- Swap all sequences and pages in the self.swap and self.pageswap tabs

		-- If there's an incoming OFF flag...
		if self.seq[s].incoming.off then

			-- Deactivate the sequence
			self.seq[s].active = false

		else -- Else, if there isn't an incoming OFF flag...
		
			self.seq[s].active = true -- Flag the sequence as active
			
			if self.seq[s].incoming.range == nil then -- If the incoming range boundaries are unset, set them to the default values
				self.seq[s].loop.low = 1
				self.seq[s].loop.high = self.gridx
			else
				local r = self.seq[s].incoming.range
				if #r == 1 then -- If there is only one range boundary, set it to both low and high
					self.seq[s].loop.low = r[1]
					self.seq[s].loop.high = r[1]
				else -- Else, if there are 2 or more range points, set low and high to the two most-recently-entered ones
					local low = r[#r - 1]
					local high = r[#r]
					if low > high then -- If low is greater than high, switch their values
						low, high = high, low
					end
					self.seq[s].loop.low, self.seq[s].loop.high = low, high
				end
			end
			
			local chunksize = #self.seq[s].tick / self.gridx -- Calculate the size of each subsection
			local bpoint = ((self.seq[s].loop.low - 1) * chunksize) + 1 -- Calculate the tick that corresponds to the incoming button-position
			
			-- If RESUME is true...
			if self.seq[s].incoming.resume then
				-- If the seq's old tick-pointer doesn't fall between the ticks corresponding to low/high, resume it on the low subsection. Otherwise leave it alone
				if not rangeCheck(self.seq[s].pointer, (self.seq[s].loop.low - 1) * chunksize, (self.seq[s].loop.high - 1) * chunksize) then
					self.seq[s].pointer = ((self.seq[s].pointer - 1) % chunksize) + bpoint -- Transpose the previous pointer position into the incoming button's subsection
				end
			else -- Else, change the pointer position to reflect the button-press position
				if self.seq[s].incoming.button then
					self.seq[s].pointer = (chunksize * (self.seq[s].incoming.button - 1)) + 1
				end
			end
			
		end

		-- Empty the incoming table
		self.seq[s].incoming = {}
		
		self:sendMetaSeqRow(s) -- Send Monome sequence rows through the meta apparatus
		
		self:updateSeqButton(s) -- Update the sequence's on-screen GUI button

	end,

	-- Iterate through a sequence's incoming flags, increase its tick pointer under certain conditions, and send off all relevant notes
	iterateSequence = function(self, s)

		if next(self.seq[s].incoming) ~= nil then -- If the sequence has incoming flags...
		
			if self.seq[s].incoming.gate then -- If the GATE flag is active...
				if ((self.tick - 1) % math.floor(self.longticks / self.seq[s].incoming.gate)) == 0 then -- On global ticks that correspond to the gate-tick amount...
					self:parseIncomingFlags(s)
				end
			else -- If the GATE flag is false, process the flags on the soonest tick
				self:parseIncomingFlags(s)
			end
			
		end

		if self.seq[s].active then -- If the sequence is active...

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
		
			if newsub ~= oldsub then -- If the new subsection corresponds to a different button than the previous subsection...
				self:sendMetaSeqRow(s) -- Send Monome sequence rows through the meta apparatus
			end

		end
		
	end,

	-- Send automatic noteoffs for duration-based notes that have expired
	decayAllSustains = function(self)

		for chan, notes in pairs(self.sustain) do
			if next(notes) ~= nil then -- Check for active note-sustains within the channel before trying to act upon them
				for note, dur in pairs(notes) do
				
					self.sustain[chan][note] = math.max(0, dur - 1) -- Decrease the relevant duration value
				
					if dur == 0 then -- If the duration has expired...
						self:noteParse({chan, 128, note, 127, 0}) -- Parse a noteoff for the relevant channel and note
					end
					
				end
			end
		end

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

	end,

	-- Swap the LOOP and INCOMING flags, and comparable pointer positions, of every sequence in the SWAP queue, if applicable
	swapAllSeqFlags = function(self)

		-- Swap the activity of two pages' worth of sequences
		if next(self.pageswap) ~= nil
		and ((#self.pageswap) > 1)
		then
			pd.post("pageswap: " .. table.concat(self.pageswap, ", ")) -- debugging
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

	-- Cycle through all MIDI commands on the active tick within every active sequence
	iterateAllSequences = function(self)

		-- Increment global tick, bounded by global gate-size
		self.tick = (self.tick % self.longticks) + 1
		
		self:decayAllSustains()

		-- Send all regular commands within all sequences, and check against longseqs
		for i = 1, (self.gridy - 2) * self.gridx do
			self:iterateSequence(i)
		end

		self:checkForLongestLoop()

	end,

}
