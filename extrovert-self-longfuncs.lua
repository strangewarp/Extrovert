
return {

	-- Check all sequences against longest-seq data
	checkForLongestLoop = function(self)

		local oldticks = self.longticks
		local flagoff = false
		local totals = {}
		local long = 0

		-- For every sequence...
		for num = 1, #self.seq do

			local s = self.seq[num]

			-- If the sequence is active...
			if s.pointer then

				-- At least one sequence has been activated, so set longchanged to true
				self.longchanged = true

				-- Index the sequence's key by its number of ticks
				local ticks = #s.tick
				totals[ticks] = totals[ticks] or {}
				table.insert(totals[ticks], num)

				-- Save the longest found ticks value
				if ticks > long then
					long = ticks
				end

			else -- Else, if the sequence isn't active...

				-- If the inactive sequence is longseq, flag a change
				if self.longseq == num then
					flagoff = true
				end

			end

		end

		-- If the longseq hasn't been changed from the default value, or is longer than longticks, or has been turned off, then set a new longseq.
		-- Note: if two seqs of the same long tick-value are triggered at once, then the pointer-position of the lowest-keyed seq takes precedence.
		if (not self.longchanged) or (long > self.longticks) or flagoff then
			local s = totals[long][1]
			local t = #s.tick
			self.tick = s.pointer - ((t / self.gridx) * ((s.loop.low or 1) - 1))
			self.longseq = s
			self.longticks = long
			self.longchanged = true
		end

	end,

}
