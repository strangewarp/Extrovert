
return {

	-- Parse a Monome button press
	parseButtonPress = function(self, x, y, s)

		if y == (self.gridy - 1) then -- Parse page-row commands
			self:parsePageButton(x, s)
		elseif y == self.gridy then -- Parse control-row commands
			self:parseCommandButton(x, s) -- Toggle global command flags
		else -- Parse sequence-button commands
			self:parseSeqButton(x, y, s)
		end
		
		pd.post("Monome cmd: " .. x .. " " .. y .. " " .. s)

	end,

	-- Parse an incoming control-row command from the Monome
	parseCommandButton = function(self, x, s)

		local light = 1 -- Stays set to 1 if the button is to be lit; else will be set to 0
		local flagbool = true -- Sets flags to true if the key is pressed; sets them to false if they are unpressed
		
		if s == 0 then -- On up-keystrokes...
			light = 0 -- The button will be darkened
			flagbool = false -- The flag will be set to false
		end
		
		-- Empty swap and pageswap storage on any upstroke or downstroke
		self.swap = false
		self.pageswap = false

		if x == 1 then -- Parse OFF button
			self.ctrlflags.off = flagbool
		elseif x == 2 then -- Parse RETRIG button
			self.ctrlflags.trig = flagbool
		elseif x == 3 then -- Parse LOOP button
			self.ctrlflags.loop = flagbool
		elseif x == 4 then -- Parse SWAP button
			self.ctrlflags.swap = flagbool
		elseif rangeCheck(x, 5, self.gridx) then -- Parse GATE buttons

			-- Left to right on 8 width: 1, 2, 4, 8
			-- Left to right on 16 width: 1, 2, 4, 8, 16, 16, 16, etc

			-- If this is a down keystroke...
			if flagbool then

				-- Set the GATE command to the corresponding value
				self.ctrlflags.gate = math.min(self.gridx, math.max(1, (2 ^ (x - 4)) / 2))

				-- Turn LEDs on and off, based on which button is held
				for i = 5, self.gridx do
					sendLED(i - 1, self.gridy - 1, ((x == i) and 1) or 0)
				end

			else -- Else, if this is an up keystroke...

				-- Unset the GATE value
				self.ctrlflags.gate = false

				-- Revert to displaying the GATE counter
				self:sendGateCountButtons()

			end

		end

		-- If this wasn't a GATE button, send the LED straightforwardly
		if x < 5 then
			sendLED(x - 1, self.gridy - 1, light)
		end

	end,

	-- Parse an incoming page-row command from the Monome
	parsePageButton = function(self, x, s)

		if s == 1 then -- On down-keystrokes...

			if self.ctrlflags.off then -- If OFF is held...

				-- If GATE is also held, send PAGE-GATE-OFF command. Else send PAGE-OFF command.
				if self.ctrlflags.gate then
					self:ctrlPageGateOff(x)
				else
					self:ctrlPageOff(x)
				end

			elseif self.ctrlflags.swap then -- If OFF is not held, but SWAP is held...

				-- If GATE is also held, send PAGE-GATE-SWAP command. Else send PAGE-SWAP command.
				if self.ctrlflags.gate then
					self:ctrlPageGateSwap(x)
				else
					self:ctrlPageSwap(x)
				end

			elseif self.ctrlflags.gate then -- If neither OFF nor SWAP is held, but GATE is held, then send PAGE-GATE command.

				self:ctrlPageGate(x)

			else -- If neither OFF, SWAP, nor GATE are held...

				-- If the page was double-clicked, tab into overview mode. Else, set overview mode to false, and tab to the given page.
				if self.page == x then
					self.overview = not self.overview
				else
					self.overview = false
					self.page = x
				end

				self:sendPageRow() -- Send the page-row butons to the Monome.

			end

			self:sendMetaGrid() -- Send the seq-rows to the Monome, for any mode.

			if self.ctrlflags.gate then
				self:updateSeqPage(x) -- Update on-screen GUI to reflect pending GATE
			end

		end

	end,

	-- Parse an incoming sequence-row command from the Monome
	parseSeqButton = function(self, x, y, s)

		-- If this isn't a down-keystroke, abort function
		if s ~= 1 then
			return nil
		end

		local snum = 1 -- Sequence number
		local col = 1 -- Column is 1, by default
	
		if self.overview then -- In overview mode...
			snum = y + ((x - 1) * (self.gridy - 2)) -- Convert an overview button into its snum sequence
		else -- In beatslice-view mode...
			snum = y + ((self.page - 1) * (self.gridy - 2)) -- Convert y row, and page value, into a sequence-key
			col = x -- Match the col-value to the column of the button that has been pressed
		end

		-- If GATE is held, apply the globl gate-value to the sequence
		if self.ctrlflags.gate then
			self:ctrlGate(snum)
		end

		if self.ctrlflags.off then -- If OFF is held, send PRESS-OFF command.
			self:ctrlPressOff(snum)
		elseif self.ctrlflags.trig then -- Else if TRIG is held, send PRESS-TRIG command.
			self:ctrlPressTrig(snum, col)
		elseif self.ctrlflags.loop then -- Else if LOOP is held, send PRESS-LOOP command.
			self:ctrlPressLoop(snum, col)
		elseif self.ctrlflags.swap then -- Else if SWAP is held, send PRESS-SWAP command.
			self:ctrlPressSwap(snum)
		else -- Else, if no control-buttons are held (aside from GATE, optionally), send a PRESS command.
			if self.ctrlflags.gate then -- If GATE is held, send the PRESS as a TRIG command, to prevent accidental offsets
				self:ctrlPressTrig(snum, col)
			else -- Else, if GATE isn't held, send a regular PRESS command
				self:ctrlPress(snum, col)
			end
		end

		if self.ctrlflags.gate then
			self:updateSeqButton(snum) -- Update on-screen GUI to reflect pending GATE
		end

	end,

	-- Spoof a series of x,y button presses, as held in a list
	parseVirtualButtonPress = function(self, ...)
		local arg = {...}
		for s = 1, 0, -1 do -- Spoof all downstrokes, and then spoof all upstrokes, to allow keychords
			for i = 1, #arg, 2 do
				self:parseButtonPress(arg[i], arg[i + 1], s)
			end
		end
	end,

	-- Send the binary counting buttons for current tick position as related to GATE values
	sendGateCountButtons = function(self)

		-- Get the offset position of the last binary-counting button
		local offset = 0
		local multi = 1
		while (multi * 2) <= self.gridx do
			offset = offset + 1
			multi = multi * 2
		end

		-- Based on tick position within the longest seq's bounds, display a binary value within the GATE buttons
		local chunk = self.longticks / self.gridx
		local cols = math.ceil(self.tick / chunk)
		for i = 5 + offset, 5, -1 do
			local igate = math.min(self.gridx, math.max(1, (2 ^ (i - 4)) / 2))
			if (cols - igate) >= 0 then
				sendLED(i - 1, self.gridy - 1, 1)
				cols = cols - igate
			else
				sendLED(i - 1, self.gridy - 1, 0)
			end
		end

	end,
	
	-- Refresh the sequence-buttons, in different ways depending on self.overview
	sendMetaGrid = function(self)
		local s = 1 -- Change overview-button to on
		if self.overview then -- Overview Mode...
			self:sendOverviewSeqButtons()
		else -- Not Overview Mode...
			s = 0 -- Change overview-button to off
			self:sendVisibleSeqRows()
		end
	end,

	-- Refresh a sequence's buttons, in different ways depending on self.overview
	sendMetaSeqRow = function(self, s)
		if self.overview then -- Overview Mode...
			self:sendOverviewSeqLED(s)
		else -- Not Overview Mode...
			self:sendSeqRowIfVisible(s)
		end
	end,

	-- Send all sequences to the Monome's buttons in overview mode
	sendOverviewSeqButtons = function(self)
		for i = 1, self.gridx * (self.gridy - 2) do
			self:sendOverviewSeqLED(i)
		end
	end,

	-- Send a single LED button representing an entire sequence, for overview-mode
	sendOverviewSeqLED = function(self, s)
		sendLED( -- Send the LED information to the Monome apparatus... (Note: this translates keys into columns aligned with their corresponding page buttons)
			math.floor((s - 1) / (self.gridy - 2)), -- Grab button's page value, translated into X
			(s - 1) % (self.gridy - 2), -- Grab button's on-page position, translated to Y
			(self.seq[s].pointer and 1) or 0 -- Grab activity value, translated from boolean to 0/1
		)
	end,

	-- Send the page-command row a new set of button data
	sendPageRow = function(self)
		if self.overview then
			self:sendSimpleRow(false, self.gridy - 2, true)
		else
			self:sendSimpleRow(self.page - 1, self.gridy - 2, false)
		end
	end,

	-- Send the Monome button-data for a single visible sequence-row
	sendSeqRow = function(self, s)
		local yrow = (s - 1) % (self.gridy - 2)
		local subpoint = self.seq[s].pointer and (math.ceil(self.seq[s].pointer / (#self.seq[s].tick / self.gridx)) - 1)
		self:sendSimpleRow(subpoint, yrow)
	end,

	-- Check whether a single sequence-row would be visible, before sending its Monome button-data
	sendSeqRowIfVisible = function(self, s)
		if rangeCheck((s - 1), (self.page - 1) * (self.gridy - 2), (self.page * (self.gridy - 2)) - 1) then -- If the sequence is upon a currently-visible page...
			self:sendSeqRow(s) -- Send the sequence's Monome GUI row
		end
	end,

	-- Send a row containing only one lit button to the Monome apparatus (incoming values should be 0-indexed!)
	-- If xpoint is set to false, then a blank row is sent.
	sendSimpleRow = function(self, xpoint, yrow, invert)

		invert = invert or false

		local rowbytes = {0, yrow} -- These bytes mean: "this command is offset by 0 spaces, and affects row number yrow"
		if self.prefs.monome.osctype == 0 then
			rowbytes = {yrow} -- If in MonomeSerial communications mode, remove the X-offset value from the rowbytes table so that the byte sequence is properly formed
		end
		
		-- Generate a series of bytes, each holding the on-off values for an 8-button slice of the relevant row
		for b = 0, self.gridx - 8, 8 do
		
			local pbyte = (invert and 255) or 0

			-- If an xpoint was given...
			if xpoint then

				-- If the xpoint is within this row-chunk, highlight it based on Overview Mode style
				if rangeCheck(xpoint, b, b + 7) then
					pbyte = 2 ^ (xpoint - b)
					if invert then -- If the style is inverted, invert the byte
						pbyte = 255 - pbyte
					end
				end

			end

			-- Put the 8-button byte into the row-bytes table
			table.insert(rowbytes, pbyte)

		end
		
		pd.send("extrovert-monome-out-row", "list", rowbytes) -- Send the row-out command to the Puredata Monome-row apparatus
		
	end,

	-- Send the Monome button-data for all visible sequence-rows
	sendVisibleSeqRows = function(self)
		for i = ((self.page - 1) * (self.gridy - 2)) + 1, self.page * (self.gridy - 2) do
			self:sendSeqRow(i)
		end
	end,

	-- Initialize the parameters of the Puredata Monome apparatus
	startMonome = function(self)
		pd.send("extrovert-osc-type", "float", {self.prefs.monome.osctype})
		pd.send("extrovert-osc-in-port", "float", {self.prefs.monome.osclisten})
		pd.send("extrovert-osc-out-port", "float", {self.prefs.monome.oscsend})
		pd.post("Initialized Monome settings")
	end,

}
