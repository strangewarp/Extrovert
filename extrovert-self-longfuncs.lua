
return {

	-- Check all sequences against longest-seq data
	checkForLongestLoop = function(self, oldticks, depth)

		depth = depth or 0
		local changed = false

		-- For every sequence...
		for num = 1, #self.seq do

			local s = self.seq[num]

			-- If the sequence is active...
			if s.pointer then

				-- If the sequence is longer than longticks, make it into the new longseq
				local t = #s.tick
				if t > self.longticks then
					self.tick = s.pointer - ((t / self.gridx) * ((s.loop.low or 1) - 1))
					self.longseq = num
					self.longticks = t
					changed = true
				end

			else -- Else, if the sequence isn't active...

				-- If the inactive sequence is longseq, set longseq to nil, and start another search
				if self.longseq == num then
					local ot = self.longticks
					self.longticks = 1
					self.longseq = nil
					self:checkForLongestLoop(ot, depth + 1)
					changed = true
					break
				end

			end

		end

		-- If the longseq is still unset after a full search, set longticks to the previous value, or the default value
		if self.longseq == nil then
			if oldticks then
				self.longticks = oldticks
			else
				self.longticks = self.gatedefault
				changed = true
			end
		end

		-- If this is the outermost recursion of longticks checking, and longticks was changed, update the gate-counting display
		if (depth == 0) and changed then
			self:sendGateCountButtons()
		end

	end,

}
