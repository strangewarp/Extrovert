
return {
	
	-- Check all sequences against longest-seq data
	checkForLongestLoop = function(self)

		for num = 1, #self.seq do

			local s = self.seq[num]

			if s.active then -- If the sequence is active...

				-- Change longest-loop tracking vars, based on the seq's loop size.
				local t = #s.tick
				if t > self.longticks then
					self.tick = 0
					self.longseqs = {[num] = true}
				elseif t == self.longticks then
					self.longseqs[num] = true
				else
					self.longseqs[num] = nil
				end

			else -- Else, if the sequence is inactive...

				-- If the inactive sequence has a longseqs entry...
				if self.longseqs[num] ~= nil then

					-- Nullify that longseqs entry
					self.longseqs[num] = nil

					-- Search for a new longest seq or seq-group
					self:findLongestActiveSeqs()

				end

			end

		end

		self:checkLongTicks()

	end,

	-- Find the currently-playing sequences that contain the largest number of concrete ticks
	findLongestActiveSeqs = function(self)

		local longest = 0
		local seqnums = {}

		-- Look through all sequences and get the longest-in-ticks value, and a table of sequences that share that value
		for k, v in pairs(self.seq) do
			if v.active then
				local t = #v.tick
				if t > longest then
					longest = t
					seqnums = {k}
				elseif t == longest then
					table.insert(seqnums, k)
				end
			end
		end

		-- If any sequences are playing...
		if next(seqnums) ~= nil then

			-- Put those sequences' keys into the longseqs table
			self.longseqs = {}
			for _, v in pairs(seqnums) do
				self.longseqs[v] = true
			end

		end

		-- Check longseqs against longticks
		self:checkLongTicks()

	end,

	-- Check all longseqs for the largest longticks value
	checkLongTicks = function(self)

		-- Find the longseq with positional priority
		local priority = false
		for k, _ in pairs(self.longseqs) do
			priority = math.min(priority or k, k)
		end

		-- If there is at least one longseq, modify things based on that sequence
		if priority then

			-- Get sequence information
			local s = self.seq[priority]
			local t = #s.tick

			-- Set global longticks to the sequence's total ticks
			self.longticks = t

			-- Figure out whether the sequence's sub-loop covers a number of cells that is an even divisor of gridx
			local cells = s.loop.high - (s.loop.low - 1)
			local isdiv = false
			local x = self.gridx
			repeat
				if x == cells then
					isdiv = true
					break
				end
				x = x / 2
			until (x - math.floor(x)) > 0

			-- If loop cleanly divides grid, then set global tick based on loop pointer; else set global tick to 1
			if isdiv then
				self.tick = s.pointer - ((t / self.gridx) * (s.loop.low - 1))
			end

		else -- If there are no longseqs, set global longticks to default, and global tick to 1
			self.longticks = self.gatedefault
		end

	end,

}
