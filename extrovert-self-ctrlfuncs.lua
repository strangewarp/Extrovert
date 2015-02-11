
return {

	-- Check whether a button falls outside of a loop's boundaries, and if so, unset the loop boundaries
	checkLoopClear = function(self, s, b)
		if not rangeCheck(b, self.seq[s].loop.low or 1, self.seq[s].loop.high or self.gridx) then
			self.seq[s].loop = {
				low = false,
				high = false,
			}
			self.seq[s].ltab = false
		end
	end,

	-- Assign an incoming GATE-value to a given sequence
	ctrlGate = function(self, s)
		self.seq[s].incoming.gate = self.slice.gate
	end,

	-- Build an incoming table based on a PRESS command
	ctrlPress = function(self, s, b)
		self.seq[s].incoming.cmd = {"parsePress", s, b}
	end,

	-- Parse an incoming PRESS command
	parsePress = function(self, s, b)

		local point = self.seq[s].pointer
		local chunk = math.floor(self.seq[s].total / self.gridx)

		-- If the pointer is empty, set it to the beginning of the button's chunk.
		-- If the pointer is filled, set it to a position in the button's chunk equivalent to its previous chunk-position.
		self.seq[s].pointer = ((point and ((point - 1) % chunk)) or 0) + (chunk * (b - 1)) + 1

		self:checkLoopClear(s, b) -- If button falls outside loop, clear loop vals

		-- Empty the incoming-command table
		self.seq[s].incoming.cmd = false

	end,

	-- Build an incoming table based on a PRESS-TRIG command.
	ctrlPressTrig = function(self, s, b)
		self.seq[s].incoming.cmd = {"parsePressTrig", s, b}
	end,

	-- Parse an incoming PRESS-TRIG command
	parsePressTrig = function(self, s, b)

		local chunk = math.floor(self.seq[s].total / self.gridx)

		-- Set the seq's pointer to the first tick in the button's corresponding chunk
		self.seq[s].pointer = (chunk * (b - 1)) + 1

		self:checkLoopClear(s, b) -- If button falls outside loop, clear loop vals

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
		self.seq[s].ltab = false
		self.seq[s].incoming.cmd = false

	end,

	-- Parse an incoming OFF-PITCH command
	ctrlPressOffPitch = function(self, s)
		self.seq[s].pitch = 0
		self.seq[s].ptab = {}
		for i = 1, self.gridx do
			self.seq[s].ptab[i] = false
		end
	end,

	-- Parse an incoming PITCH command
	ctrlPressPitch = function(self, s, col)

		self.seq[s].ptab[col] = not self.seq[s].ptab[col]
		self.seq[s].pitch = 0

		local sidex = math.floor(self.gridx / 2)

		local pitch = 0
		for i = 1, self.gridx do
			if self.seq[s].ptab[i] then
				local direction = -1
				local offset = sidex - i
				if i > sidex then
					direction = 1
					offset = (i - 1) - sidex
				end
				pitch = pitch + (math.max(1, 2 ^ offset) * direction)
			end
		end

		self.seq[s].pitch = pitch

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
			self.seq[s2].pointer and math.ceil(self.seq[s2].pointer / (self.seq[s2].total / self.seq[s1].total)),
			self.seq[s1].pointer and math.ceil(self.seq[s1].pointer / (self.seq[s1].total / self.seq[s2].total))

		-- Empty the incoming-command tables
		self.seq[s1].incoming.cmd = false
		self.seq[s2].incoming.cmd = false

	end,

	-- Build a loop-table based on a PRESS-LOOP command.
	ctrlPressLoop = function(self, s, b)

		if self.seq[s].ltab == false then

			self.seq[s].ltab = b

		else

			-- Get the stored loop-keystroke, and the current keystroke
			local b1 = self.seq[s].ltab
			local b2 = b

			-- Clear the previous tabbed loop-key
			self.seq[s].ltab = false

			-- Order the loop-bounds properly, and set them to the seq's local loop table
			if b1 > b2 then
				b1, b2 = b2, b1
			end
			self.seq[s].loop.low = b1
			self.seq[s].loop.high = b2

			local point = self.seq[s].pointer
			if point then -- If the sequence has a pointer...

				-- Get the corresponding button for the sequence's pointer
				local seqbut = math.ceil((point / self.seq[s].total) * self.gridx)

				-- If the seq-pointer falls outside of loop range, reposition it at the low location
				if not rangeCheck(seqbut, self.seq[s].loop.low, self.seq[s].loop.high) then
					self:ctrlPress(s, self.seq[s].loop.low)
				end

			end

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

	-- Build a scatter table based on the PRESS-SCATTER command, then call a function to build a meta-tick table.
	ctrlPressScatter = function(self, s, col)

		self.seq[s].stab[col] = not self.seq[s].stab[col]
		self.seq[s].sfactors = {}
		self.seq[s].samount = 0

		local sidex = math.floor(self.gridx / 2)

		local scatter = {}
		local amt = 0

		for i = 1, self.gridx do
			if self.seq[s].stab[i] then
				if i <= sidex then
					amt = amt + math.max(1, 2 ^ (sidex - i))
				else
					table.insert(scatter, math.max(1, 2 ^ ((i - sidex) - 1)))
				end
			end
		end

		local sdup = deepCopy(scatter)
		for i = 1, #scatter do
			table.insert(sdup, -scatter[i])
			for j = i + 1, #scatter do
				local putplus = scatter[i] + scatter[j]
				table.insert(sdup, putplus)
				table.insert(sdup, -putplus)
				if (j / i) ~= 2 then
					local putminus = scatter[j] - scatter[i]
					table.insert(sdup, putminus)
					table.insert(sdup, -putminus)
				end
			end
		end

		amt = amt / ((2 ^ sidex) - 1)

		self.seq[s].sfactors = sdup
		self.seq[s].samount = amt

		self:buildScatterTable(s)

	end,

	-- On an OFF-SCATTER command, unset a sequence's scatter-table, and empty its metatick table
	ctrlPressOffScatter = function(self, s)
		self.seq[s].sfactors = {}
		self.seq[s].samount = 0
		self.seq[s].stab = {}
		for i = 1, self.gridx do
			self.seq[s].stab[i] = false
		end
		self.seq[s].metatick = {}
	end,

	-- Set the scatter-tables of a page of sequences to contain the column's boolean bit, using SCATTER commands.
	ctrlPageScatter = function(self, page, col)
		for i = 1 + ((self.gridy - 2) * (page - 1)), (self.gridy - 2) * page do
			self:ctrlPressScatter(i, col)
		end
	end,

	-- Set the scatter-tables of a page of sequences to their default values, using SCATTER-OFF commands.
	ctrlPageOffScatter = function(self, p)

		-- For every sequence in the page, set a SCATTER-OFF command
		for i = 1, self.gridy - 2 do
			self:ctrlPressOffScatter(((self.gridy - 2) * (p - 1)) + i)
		end

	end,

	-- Build incoming tables based on a PAGE-OFF command.
	ctrlPageOff = function(self, p)

		-- For every sequence in the page, set an incoming OFF command
		for i = 1, self.gridy - 2 do
			self:ctrlPressOff(((self.gridy - 2) * (p - 1)) + i)
		end

	end,

	-- Set the pitch-tables of a page of sequences to their default values, using PITCH-OFF commands.
	ctrlPageOffPitch = function(self, p)

		-- For every sequence in the page, set a PITCH-OFF command
		for i = 1, self.gridy - 2 do
			self:ctrlPressOffPitch(((self.gridy - 2) * (p - 1)) + i)
		end

	end,

	-- Set the pitch-tables of a page of sequences to contain the column's boolean bit, using PITCH commands.
	ctrlPagePitch = function(self, page, col)
		for i = 1 + ((self.gridy - 2) * (page - 1)), (self.gridy - 2) * page do
			self:ctrlPressPitch(i, col)
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
