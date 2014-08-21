
return {

	-- If a button falls outside a seq's loop boundaries, widen the loop boundaries
	widenLoop = function(self, s, b)
		if self.seq[s].loop.low
		and (b < self.seq[s].loop.low)
		then
			self.seq[s].loop.low = b
		elseif self.seq[s].loop.high
		and (b > self.seq[s].loop.high) then
			self.seq[s].loop.high = b
		end
	end,

	-- Assign an incoming GATE-value to a given sequence
	ctrlGate = function(self, s)
		self.seq[s].incoming.gate = self.ctrlflags.gate
	end,

	-- Build an incoming table based on a PRESS command
	ctrlPress = function(self, s, b)
		self.seq[s].incoming.cmd = {"parsePress", s, b}
	end,

	-- Parse an incoming PRESS command
	parsePress = function(self, s, b)

		local point = self.seq[s].pointer
		local chunk = #self.seq[s].tick / self.gridx

		-- If the pointer is empty, set it to the beginning of the button's chunk.
		-- If the pointer is filled, set it to a position in the button's chunk equivalent to its previous chunk-position.
		self.seq[s].pointer = ((point and ((point - 1) % chunk)) or 0) + (chunk * (b - 1)) + 1

		self:widenLoop(s, b) -- If button falls outside loop, widen loop edges

		-- Empty the incoming-command table
		self.seq[s].incoming.cmd = false

	end,

	-- Build an incoming table based on a PRESS-OFF command.
	ctrlPressOff = function(self, s)
		self.seq[s].incoming.cmd = {"parsePressOff", s}
	end,

	-- Parse an incoming PRESS-OFF command
	parsePressOff = function(self, s)

		-- Unset/reset all activity variables within the sequence
		self.seq[s].pointer = false
		self.seq[s].loop = {
			low = false,
			high = false,
		}
		self.seq[s].incoming.cmd = false

	end,

	-- Build an incoming table based on a PRESS-TRIG command.
	ctrlPressTrig = function(self, s, b)
		self.seq[s].incoming.cmd = {"parsePressTrig", s, b}
	end,

	-- Parse an incoming PRESS-TRIG command
	parsePressTrig = function(self, s, b)

		local chunk = #self.seq[s].tick / self.gridx

		-- Set the seq's pointer to the first tick in the button's corresponding chunk
		self.seq[s].pointer = (chunk * (b - 1)) + 1

		self:widenLoop(s, b) -- If button falls outside loop, widen loop edges

		-- Empty the incoming-command table
		self.seq[s].incoming.cmd = false

	end,

	-- Build an incoming table based on a PRESS-SWAP command.
	ctrlPressSwap = function(self, s)

		-- If a swap-seq is tabled, set an incoming command; else table this seq's index as the swap-seq.
		if self.swap then
			self.seq[s].incoming.cmd = {"parsePressSwap", self.swap, s}
			self.swap = false
		else
			self.swap = s
		end

	end,

	-- Parse an incoming PRESS-SWAP command.
	parsePressSwap = function(self, s1, s2)

		-- Switch loop commands
		self.seq[s1].loop, self.seq[s2].loop = self.seq[s2].loop, self.seq[s1].loop

		-- Switch relative pointer positions
		self.seq[s1].pointer, self.seq[s2].pointer =
			self.seq[s2].pointer and math.ceil(self.seq[s2].pointer / (#self.seq[s2].tick / #self.seq[s1].tick)),
			self.seq[s1].pointer and math.ceil(self.seq[s1].pointer / (#self.seq[s1].tick / #self.seq[s2].tick))

		-- Empty the incoming-command table
		self.seq[s].incoming.cmd = false

	end,

	-- Build an incoming table based on a PRESS-LOOP command.
	ctrlPressLoop = function(self, s, b)

		-- If the sequence doesn't have a pointer, treat this like a PRESS command before assigning a loop
		if not self.seq[s].pointer then
			self:ctrlPress(s, b)
		end

		-- Get the sequence's pointer and its corresponding button
		local point = self.seq[s].pointer
		local seqbut = math.ceil(point / self.gridx)

		-- If the press-button is lower than the pointer-button, make the press-button the loop's lower bound
		if b < seqbut then
			self.seq[s].loop.low = b
		elseif b == seqbut then -- Else, if press-button equals pointer-button, set loop's low or high bound to press-button, favoring low before high
			if self.seq[s].loop.low then
				self.seq[s].loop.high = b
			else
				self.seq[s].loop.low = b
			end
		else -- Else, set the loop's high bound to the press-button
			self.seq[s].loop.high = b
		end

		-- If one of the loop boundaries is unfilled, fill it
		self.seq[s].loop.low = self.seq[s].loop.low or 1
		self.seq[s].loop.high = self.seq[s].loop.high or self.gridx

		-- If the seq-pointer falls outside of loop range, reposition it at the button-press location
		if not rangeCheck(seqbut, self.seq[s].loop.low, self.seq[s].loop.high) then
			self:ctrlPress(s, b)
		end

	end,

	-- Build an incoming table based on the GATE-PRESS command.
	ctrlGatePress = function(self, s, b)
		self:ctrlGate(s)
		self:ctrlPress(s, b)
	end,

	-- Build an incoming table based on the GATE-OFF command.
	ctrlGateOff = function(self, s)
		self:ctrlGate(s)
		self:ctrlPressOff(s)
	end,

	-- Build an incoming table based on the GATE-SWAP command.
	ctrlGateSwap = function(self, s)
		self:ctrlGate(s)
		self:ctrlPressSwap(s)
	end,

	-- Build incoming tables based on a PAGE-OFF command.
	ctrlPageOff = function(self, p)

		-- For every sequence in the page, set an incoming OFF command
		for i = 1, self.gridy - 2 do
			self:ctrlPressOff(((self.gridy - 2) * (p - 1)) + i)
		end

	end,

	-- Build incoming tables based on a PAGE-SWAP command.
	ctrlPageSwap = function(self, p)

		-- If swap-page is tabled, set a page's worth of incoming commands; else table this page's index as the swap-page.
		if self.pageswap then
			for i = 1, self.gridy - 2 do
				self:ctrlPressSwap(((self.gridy - 2) * (self.pageswap - 1)) + i)
				self:ctrlPressSwap(((self.gridy - 2) * (p - 1)) + i)
			end
			self.pageswap = false
		else
			self.pageswap = p
		end

	end,

	-- Build incoming tables based on a PAGE-GATE command.
	ctrlPageGate = function(self, p)

		-- For every sequence in the page, set an incoming GATE value, and an incoming PRESS command on button 1
		for i = 1, self.gridy - 2 do
			local seq = ((self.gridy - 2) * (p - 1)) + i
			self:ctrlGate(seq)
			self:ctrlPress(seq, 1)
		end

	end,

	-- Build incoming tables based on a PAGE-GATE-OFF command.
	ctrlPageGateOff = function(self, p)

		-- For every sequence in the page, set an incoming GATE value, and an incoming OFF command
		for i = 1, self.gridy - 2 do
			local seq = ((self.gridy - 2) * (p - 1)) + i
			self:ctrlGate(seq)
			self:ctrlPressOff(seq)
		end

	end,

	-- Build incoming tables based on a PAGE-GATE-SWAP command.
	ctrlPageGateSwap = function(self, p)

		-- For every sequence in the page, set an incoming GATE value
		for i = 1, self.gridy - 2 do
			local seq = ((self.gridy - 2) * (p - 1)) + i
			self:ctrlGate(seq)
		end

		self:ctrlPageSwap(p)

	end,

}
