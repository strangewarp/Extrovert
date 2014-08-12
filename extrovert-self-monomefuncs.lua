
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
		
		if s == 0 then -- On down-keystrokes...
			light = 0 -- The button will be darkened
			flagbool = false -- The flag will be set to false
		end
		
		if x == 1 then -- Parse OFF button
			self.ctrlflags.off = flagbool
		elseif x == 2 then -- Parse RESUME button
			self.ctrlflags.resume = flagbool
		elseif x == 3 then -- Parse LOOP button
			self.ctrlflags.loop = flagbool
		elseif x == 4 then -- Parse SWAP button
			self.ctrlflags.swap = flagbool
		elseif rangeCheck(x, 5, self.gridx) then -- Parse GATE buttons

			-- Left to right on 8 width: 1, 2, 4, 8
			-- Left to right on 16 width: 1, 2, 4, 8, 16, 16, 16, etc

			-- Get the new GATE value
			local newgate = math.min(self.gridx, math.max(1, (2 ^ (x - 4)) / 2))

			-- If this is a down keystroke...
			if flagbool then

				-- Put the key's GATE value into the gateheld table
				self.gateheld[x - 4] = newgate

				-- Turn LEDs on and off, based on held-button activity
				for i = 5, self.gridx do
					sendLED(i - 1, self.gridy - 1, (self.gateheld[i - 4] and 1) or 0)
				end

			else -- Else, if this is an up keystroke...

				-- Remove the gate's gateheld entry
				self.gateheld[x - 4] = nil

				-- If any gatebuttons are still held, simply darken the released button
				if next(self.gateheld) ~= nil then
					sendLED(x - 1, self.gridy - 1, 0)
				else -- Else, if no gatebuttons are held, revert to displaying the GATE counter
					self:sendGateCountButtons()
				end

			end

			-- Add together all held-down GATE values, ignoring duplicates, and bounded to grid width
			self.ctrlflags.gate = false
			local foundkeys = {}
			for _, v in pairs(self.gateheld) do
				if not foundkeys[v] then
					self.ctrlflags.gate = (self.ctrlflags.gate or 0) + v
				end
				foundkeys[v] = true
			end
			self.ctrlflags.gate = self.ctrlflags.gate and math.min(self.gridx, self.ctrlflags.gate)

		end

		-- If this wasn't a GATE button, send the LED straightforwardly
		if x < 5 then
			sendLED(x - 1, self.gridy - 1, light)
		end

	end,

	-- Parse an incoming page-row command from the Monome
	parsePageButton = function(self, x, s)

		if s == 1 then -- On down-keystrokes...

			-- If any command-buttons are being pressed, set cmdflag to true
			local cmdflag = false
			for k, v in pairs(self.ctrlflags) do
				if v and (k ~= 'gate') then
					cmdflag = true
				end
			end

			-- If a GATE button is being held, give every seq in the page a GATE flag
			local held = self.gateheld[#self.gateheld]
			if held then
				if not self.ctrlflags.swap then
					for i = ((self.gridy - 2) * (x - 1)) + 1, (self.gridy - 1) * x do
						self.seq[i].incoming.gate = held
						self:updateSeqButton(i) -- Reflect this keystroke in the on-screen GUI
					end
				end
			end

			if self.ctrlflags.off then -- If OFF is flagged...

				-- Give every seq in the page an OFF flag
				for i = ((self.gridy - 2) * (x - 1)) + 1, (self.gridy - 1) * x do
					self.seq[i].incoming.off = true
				end

			elseif self.ctrlflags.resume then -- Else, if RESUME is flagged...

				-- Give every seq in the page a RESUME flag
				for i = ((self.gridy - 2) * (x - 1)) + 1, (self.gridy - 1) * x do
					self.seq[i].incoming.resume = true
				end

			elseif self.ctrlflags.swap then -- Else, if SWAP is flagged...

				-- If the page is already within the pageswap table, remove its old entry
				for k, v in pairs(self.pageswap) do
					if v == x then
						table.remove(self.pageswap, k)
						break
					end
				end

				-- Insert the page into the pageswap table
				table.insert(self.pageswap, x)

				-- If the pageswap table has more than two entries, remove the oldest one
				if #self.pageswap > 2 then
					table.remove(self.pageswap, 1)
				end

				pd.post(table.concat(self.pageswap, " ")) -- debugging

			end

			-- If this is not being chorded with any command-buttons...
			if not cmdflag then

				-- If the page-button was double-clicked, toggle overview mode
				if x == self.page then
					self.overview = not self.overview
				else -- Else, if the page button is new, tab out of overview mode and tab to the selected page
					self.overview = false
					self.page = x
				end

				self:sendPageRow() -- Send the row of page-buttons to the Monome

			end
			
			self:sendMetaGrid() -- Send the sequence-grid to the Monome

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
		
		-- If GATE is flagged, set incoming gate
		if self.ctrlflags.gate then
			self.seq[snum].incoming.gate = self.ctrlflags.gate
			self:updateSeqButton(snum) -- Reflect this keystroke in the on-screen GUI
		end

		-- If OFF is flagged, set incoming deactivation
		if self.ctrlflags.off then

			self.seq[snum].incoming.off = true

		else -- Else, if OFF isn't flagged...

			-- If RESUME is flagged, set seq to resume from previous position
			if self.ctrlflags.resume then
				self.seq[snum].incoming.resume = true
			end

			-- If LOOP is flagged, set one of the seq's loop points
			if self.ctrlflags.loop then

				-- If incoming.range is nil, build it
				self.seq[snum].incoming.range = self.seq[snum].incoming.range or {}

				-- Insert the column value into the target sequence's range-button table
				table.insert(self.seq[snum].incoming.range, col)

				-- If the number of incoming loop-bounds is more than 2, remove the oldest one
				if #self.seq[snum].incoming.range > 2 then
					table.remove(self.seq[snum].incoming.range, 1)
				end

			end

			-- If SWAP is flagged, table the sequence for swapping
			if self.ctrlflags.swap then

				-- If no swap-pairs already exist, or the active swap-pair is full, insert a new-swap pair
				if (next(self.swap) == nil)
				or (#self.swap[#self.swap] == 2)
				then
					table.insert(self.swap, {})
				end

				-- Put the sequence into the top swap-pair
				table.insert(self.swap[#self.swap], snum)

			end

		end

		-- If not in SWAP-mode...
		if not self.ctrlflags.swap then

			-- Set the incoming button to the given subsection-button
			self.seq[snum].incoming.button = x

			-- If the sequence isn't already active...
			if not self.seq[snum].active then

				-- Show that the sequence was newly activated, and that it should therefore be treated slightly differently on its first tick
				self.seq[snum].incoming.activated = true

			end

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
			(self.seq[s].active and 1) or 0 -- Grab activity value, translated from boolean to 0/1
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
		if self.seq[s].active then -- Send a row wherein the sequence's active subsection-button is brightened
			local subpoint = math.ceil(self.seq[s].pointer / (#self.seq[s].tick / self.gridx)) - 1
			self:sendSimpleRow(subpoint, yrow)
		else -- Send a darkened sequence-row
			self:sendSimpleRow(false, yrow)
		end
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
