
return {
	
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

		local bound = self.seq[(self.groove and self.g.seqnum) or 1].total

		-- Get the offset position of the last binary-counting button
		local offset = 0
		local multi = 1
		while (multi * 2) <= self.gridx do
			offset = offset + 1
			multi = multi * 2
		end

		-- Based on tick position within the longest seq's bounds, display a binary value within the GATE buttons
		local chunk = bound / self.gridx
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
		if self.groove then -- Groove mode...
			self:sendGroovePanel()
		else -- Non-groove modes...
			if self.overview then -- Overview Mode...
				self:sendOverviewSeqButtons()
			else -- Not Overview Mode...
				self:sendVisibleSeqRows()
			end
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

	-- Send all buttons for the Groove Mode panel
	sendGroovePanel = function(self)
		self:sendGrooveBinRows()
		self:sendGrooveCommandKeys()
		self:sendGateCountButtons()
	end,

	-- Sen all binary-value rows for the Groove Mode view
	sendGrooveBinRows = function(self)

		local combine = deepCopy(self.g.chan)
		for _, v in ipairs(self.g.humanize) do
			combine[#combine + 1] = v
		end

		local pitchmod = deepCopy(self.g.pitch)
		local velomod = deepCopy(self.g.velo)
		pitchmod[self.gridx] = self.g.moveup
		velomod[self.gridx] = self.g.movedown

		self:sendBoolTabRow(self.gridy - 8, self.g.pitch)
		self:sendBoolTabRow(self.gridy - 7, self.g.velo)
		self:sendBoolTabRow(self.gridy - 6, self.g.dur)
		self:sendBoolTabRow(self.gridy - 5, combine)
		self:sendBoolTabRow(self.gridy - 4, self.g.len)
		self:sendBoolTabRow(self.gridy - 3, self.g.quant)
		self:sendBoolTabRow(self.gridy - 2, self.g.seq)

	end,

	-- Send all special command-keys for the Groove Mode view
	sendGrooveCommandKeys = function(self)

		-- 0-index the X and Y boundaries, for sendLED calls
		local x = self.gridx - 1
		local y = self.gridy - 1

		-- Send bottom-row buttons
		sendLED(0, y, (self.g.track and 1) or 0)
		sendLED(1, y, (self.g.rec and 1) or 0)
		sendLED(2, y, (self.g.chanerase and 1) or 0)
		sendLED(3, y, (self.g.erase and 1) or 0)

		-- Send top-right corner buttons
		sendLED(x, self.gridy - 8, (self.g.moveup and 1) or 0)
		sendLED(x, self.gridy - 7, (self.g.movedown and 1) or 0)

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

	-- Dummy version of the sendLED function, to strip off the 'self' call from updateGUI
	sendSelfLED = function(self, x, y, s)
		sendLED(x, y, s)
	end,

	-- Send the page-row a new set of button data
	sendPageRow = function(self)
		if not self.groove then -- If not in groove mode...
			if self.overview then
				self:sendSimpleRow(false, self.gridy - 2, true)
			else
				self:sendSimpleRow(self.page - 1, self.gridy - 2, false)
			end
		end
	end,

	-- Send a sequence's SCATTER row
	sendScatterRow = function(self, s)
		self:sendBoolRow(s, self.seq[s].stab)
	end,

	-- Send a sequence's PITCH row
	sendPitchRow = function(self, s)
		self:sendBoolRow(s, self.seq[s].ptab)
	end,

	-- Send a row containing a sequence's boolean pitch-values
	sendBoolRow = function(self, s, bools)
		local yrow = (s - 1) % (self.gridy - 2)
		self:sendBoolTabRow(yrow, bools)
	end,

	-- Send the Monome button-data for a single visible sequence-row
	sendSeqRow = function(self, s)
		local yrow = (s - 1) % (self.gridy - 2)
		local subpoint = self.seq[s].pointer and (math.ceil(self.seq[s].pointer / (self.seq[s].total / self.gridx)) - 1)
		self:sendSimpleRow(subpoint, yrow)
	end,

	-- Check whether a single sequence-row would be visible, before sending its Monome button-data
	sendSeqRowIfVisible = function(self, s)
		if rangeCheck((s - 1), (self.page - 1) * (self.gridy - 2), (self.page * (self.gridy - 2)) - 1) then -- If the sequence is upon a currently-visible page...
			self:sendSeqRow(s) -- Send the sequence's Monome GUI row
		end
	end,

	-- Send a row whose LED-bytes correspond to a table of booleans
	sendBoolTabRow = function(self, yrow, bools)

		local rowbytes = {0, yrow} -- These bytes mean: "this command is offset by 0 spaces, and affects row number yrow"
		if self.prefs.monome.osctype == 0 then
			rowbytes = {yrow} -- If in MonomeSerial communications mode, remove the X-offset value from the rowbytes table so that the byte sequence is properly formed
		end

		for b = 0, self.gridx - 8, 8 do
			local outbyte = 0
			for i = 1, 8 do
				local k = b + i
				if bools[k] then
					outbyte = outbyte + math.max(1, 2 ^ (i - 1))
				end
			end
			table.insert(rowbytes, outbyte)
		end
		
		pd.send("extrovert-monome-out-row", "list", rowbytes) -- Send the row-out command to the Puredata Monome-row apparatus
		
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
			if self.slice.pitch and self.slice.loop then
				self:sendScatterRow(i)
			elseif self.slice.pitch then
				self:sendPitchRow(i)
			else
				self:sendSeqRow(i)
			end
		end
	end,

}
