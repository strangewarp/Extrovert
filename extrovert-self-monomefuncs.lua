return {
	
	-- Send a row containing only one lit button to the Monome apparatus (incoming values should be 0-indexed!)
	-- If xpoint is set to false, then a blank row is sent.
	sendSimpleRow = function(self, xpoint, yrow)

		local rowbytes = {0, yrow} -- These bytes mean: "this command is offset by 0 spaces, and affects row number yrow"
		
		if self.prefs.monome.osctype == 0 then
			rowbytes = {yrow} -- If in MonomeSerial communications mode, remove the X-offset value from the rowbytes table so that the byte sequence is properly formed
		end
		
		-- Generate a series of bytes, each holding the on-off values for an 8-button slice of the relevant row
		for b = 0, self.gridx - 8, 8 do
		
			if (xpoint ~= false)
			and rangeCheck(xpoint, b, b + 7)
			then -- If the row contains a lit button, and that button is within this byte-slice, insert the corresponding bitwise on-value
				table.insert(rowbytes, math.max(1, 2 ^ (xpoint - b)))
			else -- Else, insert a byte corresponding to 8 darkened buttons
				table.insert(rowbytes, 0)
			end
		
		end
		
		pd.send("extrovert-monome-out-row", "list", rowbytes) -- Send the row-out command to the Puredata Monome-row apparatus
		
	end,

	-- Send the page-command row a new set of button data
	sendPageRow = function(self)
		self:sendSimpleRow(self.page - 1, self.gridy - 2)
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

	-- Send the Monome button-data for all visible sequence-rows
	sendVisibleSeqRows = function(self)
		for i = ((self.page - 1) * (self.gridy - 2)) + 1, self.page * (self.gridy - 2) do
			self:sendSeqRow(i)
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

	-- Send all sequences to the Monome's buttons in overview mode
	sendOverviewSeqButtons = function(self)
		for i = 1, self.gridx * (self.gridy - 2) do
			self:sendOverviewSeqLED(i)
		end
	end,

	-- Send the Monome LED state for the overview-mode's control-button
	sendOverviewButton = function(self)
		sendLED(0, self.gridy - 1, (self.overview and 1) or 0)
	end,

	-- Refresh a sequence's buttons, in different ways depending on self.overview
	sendMetaSeqRow = function(self, s)
		if self.overview then -- Overview Mode...
			self:sendOverviewSeqLED(s)
		else -- Not Overview Mode...
			self:sendSeqRowIfVisible(s)
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
		sendLED(0, self.gridy - 1, s) -- Update the overview-button, to the left of the control-buttons
	end,

	-- Initialize the parameters of the Puredata Monome apparatus
	startMonome = function(self)
		pd.send("extrovert-osc-type", "float", {self.prefs.monome.osctype})
		pd.send("extrovert-osc-in-port", "float", {self.prefs.monome.osclisten})
		pd.send("extrovert-osc-out-port", "float", {self.prefs.monome.oscsend})
		pd.post("Initialized Monome settings")
	end,

	-- Parse an incoming sequence-row command from the Monome
	parseSeqButton = function(self, x, y, s)

		if s == 1 then -- On down-keystrokes...
		
			local target = 1 -- Target sequence
			local section = 1 -- Section column is 1, by default
		
			if self.overview then -- In overview mode...
				target = y + ((x - 1) * (self.gridy - 2)) -- Convert an overview button into its target sequence
			else -- In beatslice-view mode...
				target = y + ((self.page - 1) * (self.gridy - 2)) -- Convert y row, and page value, into a sequence-key
				section = x -- Match the section-value to the column of the button that has been pressed
			end
			
			self:setIncomingFlags(target, section) -- Apply whatever control-flags are currently active to the sequence
			
			if self.seq[target].incoming.gate then -- If the sequence is gated to a later tick...
				self:updateSeqButton(target) -- Reflect this keystroke in the on-screen GUI
			end
		
		end

	end,

	-- Parse an incoming page-row command from the Monome
	parsePageButton = function(self, x, s)

		if s == 1 then -- On down-keystrokes...

			local cmdflag = false -- Gets toggled to true if any command buttons are being pressed
			
			-- Check all control-row flags
			for k, v in pairs(self.ctrlflags) do
				if v
				and (k ~= "swap")
				then
					cmdflag = true
					for i = ((self.gridy - 2) * (x - 1)) + 1, (self.gridy - 2) * x do -- For every sequence on the relevant page...
						self:setIncomingFlags(i, 1) -- Apply whatever control-flags are currently active to the sequence
					end
					self:updateSeqPage(x) -- Reflect this change in the on-screen GUI
				end
			end

			if self.ctrlflags.swap then
				table.insert(self.pageswap, x)
			end

			if not cmdflag then -- If this is not being chorded with any command-buttons...
				self.page = x -- Tab to the selected page
				self:sendPageRow()
			end
			
			self:sendMetaGrid() -- Send the sequence grid to the Monome, via the meta apparatus

		end

	end,

	-- Parse an incoming control-row command from the Monome
	parseCommandButton = function(self, x, s)

		local light = 1 -- Stays set to 1 if the button is to be lit; else will be set to 0
		local flagbool = true -- Sets flags to true if the key is pressed; sets them to false if they are unpressed
		
		if s == 0 then -- On down-keystrokes...
			light = 0 -- The button will be darkened
			flagbool = false -- The flag will be set to false
		end
		
		if x == 2 then -- Parse OFF button
			self.ctrlflags.off = flagbool
		elseif x == 3 then -- Parse RESUME button
			self.ctrlflags.resume = flagbool
		elseif x == 4 then -- Parse LOOP button
			self.ctrlflags.loop = flagbool
		elseif x == 5 then -- Parse SWAP button
			self.ctrlflags.swap = flagbool
		elseif rangeCheck(x, 6, self.gridx) then -- Parse GATE buttons
			self.ctrlflags.gate = flagbool and math.min(self.gridx, math.max(1, 2 ^ (x - 6))) -- From left to right: 1, 2, 4 (that's all if width=8), 8, 16, 16, 16, etc
		end

		sendLED(x - 1, self.gridy - 1, light) -- Light up or darken the corresponding Monome button

	end,

	-- Parse an overview-button command from the Monome
	parseOverviewButton = function(self, s)
		if s == 1 then
			self.overview = not self.overview
			self:sendOverviewButton()
			self:sendMetaGrid()
		end
	end,

	-- Parse a Monome button press
	parseButtonPress = function(self, x, y, s)

		if y == (self.gridy - 1) then -- Parse page-row commands
			self:parsePageButton(x, s)
		elseif y == self.gridy then -- Parse control-row commands
			if x == 1 then
				self:parseOverviewButton(s) -- Toggle Overview Mode
			else
				self:parseCommandButton(x, s) -- Toggle global command flags
			end
		else -- Parse sequence-button commands
			self:parseSeqButton(x, y, s)
		end
		
		pd.post("Monome cmd: " .. x .. " " .. y .. " " .. s)

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
	
}