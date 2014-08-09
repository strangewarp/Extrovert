
return {

	-- Check all sequences against longest-seq data
	checkForLongestLoop = function(self, oldticks)

		-- For every sequence...
		for num = 1, #self.seq do

			local s = self.seq[num]

			-- If the sequence is active...
			if s.active then

				-- If the sequence is longer than longticks, make itinto the new longseq
				local t = #s.tick
				if t > self.longticks then
					self.tick = s.pointer - ((t / self.gridx) * (s.loop.low - 1))
					self.longseq = num
					self.longticks = t
				end

			else -- Else, if the sequence isn't active...

				-- If the inactive sequence is longseq, set longseq to nil, and start another search
				if self.longseq == num then
					local ot = self.longticks
					self.longticks = 1
					self.longseq = nil
					self:checkForLongestLoop(ot)
					break
				end

			end

		end

		-- If the longseq is still unset after a full search, set longticks to the previous value, or the default value
		if self.longseq == nil then
			self.longticks = oldticks or self.gatedefault
		end

	end,

}
