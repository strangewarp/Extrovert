
return {

	-- Parse a Monome button press
	parseButtonPress = function(self, x, y, s)

		if self.groove then -- In Groove Mode...

			self:parseGrooveButton(x, y, s) -- Parse the groove-mode buttons

		else -- In Slice Mode and Overview Mode...

			if y == (self.gridy - 1) then -- Parse page-row commands
				self:parsePageButton(x, s)
			elseif y == self.gridy then -- Parse control-row commands
				self:parseCommandButton(x, s) -- Toggle global command flags
			else -- Parse sequence-button commands
				self:parseSeqButton(x, y, s)
			end

		end
		
	end,

	-- Parse an incoming Groove Mode button from the Monome
	parseGrooveButton = function(self, x, y, s)

		if s == 1 then -- If this is a down-keypress...

			if y == (self.gridy - 7) then -- Modify PITCH bits
				self.g.pitch[x] = not self.g.pitch[x]
				self.g.pitchnum = boolsToNum(self.g.pitch, false, 1, 0, 127)
				self.g.pitch = numToBools(self.g.pitchnum, false, 1, 8)
			elseif y == (self.gridy - 6) then -- Modify VELOCITY bits
				self.g.velo[x] = not self.g.velo[x]
				self.g.velonum = boolsToNum(self.g.velo, false, 1, 1, 127)
				self.g.velo = numToBools(self.g.velonum, false, 1, 8)
			elseif y == (self.gridy - 5) then -- Modify DURATION bits
				self.g.dur[x] = not self.g.dur[x]
				self.g.durnum = boolsToNum(self.g.dur, false, 1, 1, 255)
				self.g.dur = numToBools(self.g.durnum, false, 1, 8)
			elseif y == (self.gridy - 4) then -- Modify either MIDI CHANNEL or HUMANIZE bits
				local xhalf = math.floor(self.gridx / 2)
				if x <= xhalf then -- Modify MIDI CHANNEL bits
					self.g.chan[x] = not self.g.chan[x]
					self.g.channum = boolsToNum(self.g.chan, true, 1, 0, 15)
					self.g.chan = numToBools(self.g.channum, true, 1, 4)
				else -- Modify HUMANIZE bits
					local xmod = x - xhalf
					self.g.humanize[xmod] = not self.g.humanize[xmod]
					self.g.humanizenum = boolsToNum(self.g.humanize, false, 16, 0, 128)
					self.g.humanize = numToBools(self.g.humanizenum, false, 16, 4)
				end
			elseif y == (self.gridy - 3) then -- Modify SEQUENCE LENGTH bits
				self.g.len[x] = not self.g.len[x]
				self.g.lennum = boolsToNum(self.g.len, false, 1, 1, 128)
				self.g.len = numToBools(self.g.lennum, false, 1, 8)
			elseif y == (self.gridy - 2) then -- Modify QUANTIZE bits
				self.g.quant[x] = not self.g.quant[x]
				self.g.quantnum = boolsToNum(self.g.quant, false, 1, 1, 255)
				self.g.quant = numToBools(self.g.quantnum, false, 1, 8)
			elseif y == (self.gridy - 1) then -- Modify ACTIVE SEQUENCE bits
				self.g.seq[x] = not self.g.seq[x]
				self.g.seqnum = boolsToNum(self.g.seq, false, 1, 1, (self.gridy - 2) * self.gridx)
				self.g.seq = numToBools(self.g.seqnum, false, 1, self.gridx)
				self.g.lennum = math.max(1, math.min(128, math.floor(self.seq[self.g.seqnum].total / (self.tpq * 4)))) -- Set length, in beats
				self.seq[self.g.seqnum].total = self.g.lennum * (self.tpq * 4) -- Tweak the total ticks in seqs that don't match the TPQ*4 beat-size regime
				self.g.len = numToBools(self.g.lennum, false, 1, 128)
			end

			pd.post("PITCH: "..self.g.pitchnum)--debugging

			self:queueGUI("sendGrooveBinRows")

		end

		if y == self.gridy then -- If this is a control-row keypress...
			if x == 1 then -- Parse a TEST/TRACK command, for either an up or down keypress
				self.g.track = ((s == 1) and (not self.g.track)) or self.g.track
				if self.g.track and self.g.rec and self.g.gate then -- If TOGGLE GROOVE keychord is hit, then toggle out of Groove Mode
					self:toggleGrooveMode()
					return nil
				end
				if s == 1 then -- If this is a down-keystroke, play an example-note
					self:insertGrooveNote()
				end
			elseif x == 2 then -- Parse a RECORD-TOGGLE command
				if s == 1 then -- If this is a down-keystroke, change the toggle's status
					self.g.rec = not self.g.rec
					if self.g.track and self.g.rec and self.g.gate then -- If TOGGLE GROOVE keychord is hit, then toggle out of Groove Mode
						self:toggleGrooveMode()
						return nil
					end
				end
			elseif x == 3 then -- Parse a CHANNEL-ERASE command
				self.g.chanerase = ((s == 1) and (not self.g.chanerase)) or self.g.chanerase
			elseif x == 4 then -- Parse an ERASE command
				self.g.erase = ((s == 1) and (not self.g.erase)) or self.g.erase
			else -- Parse a GATE command
				local gval = math.max(1, 2 ^ (x - 5))
				self.g.gate = (self.g.gate or 0) + (gval * ((s * 2) - 1))
				self.g.gate = (self.g.gate ~= 0) and self.g.gate
				if self.g.track and self.g.rec and self.g.gate then -- If TOGGLE GROOVE keychord is hit, then toggle out of Groove Mode
					self:toggleGrooveMode()
					return nil
				end
			end
		end

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
			self.slice.off = flagbool
		elseif x == 2 then -- Parse PITCH-SHIFT button
			self.slice.pitch = flagbool
			self:queueGUI("sendVisibleSeqRows")
		elseif x == 3 then -- Parse LOOP button
			self.slice.loop = flagbool
			if self.slice.pitch then
				self:queueGUI("sendVisibleSeqRows")
			end
		elseif x == 4 then -- Parse SWAP button
			self.slice.swap = flagbool
		elseif rangeCheck(x, 5, self.gridx) then -- Parse GATE buttons

			-- Left to right on 8 width: 1, 2, 4, 8
			-- Left to right on 16 width: 1, 2, 4, 8, 16, 16, 16, etc

			-- If this is a down keystroke...
			if flagbool then

				local key = math.min(self.gridx, math.max(1, (2 ^ (x - 4)) / 2))

				-- If a "change global gate" command is given, advance the global gate-value by the gate-button value.
				if self.slice.off and self.slice.swap then
					self.tick = (((self.tick + ((self.longticks / self.gridx) * key)) - 1) % self.longticks) + 1
				else -- Else, if this is a regular gate-button-press...
					self.slice.gate = key -- Set the GATE command to the corresponding key-value
					for i = 5, self.gridx do -- Turn LEDs on and off, based on which button is held
						self:queueGUI("sendSelfLED", i - 1, self.gridy - 1, ((x == i) and 1) or 0)
					end
				end

			else -- Else, if this is an up keystroke...

				-- Unset the GATE value
				self.slice.gate = false

				-- Revert to displaying the GATE counter
				self:queueGUI("sendGateCountButtons")

			end

		end

		-- If this wasn't a GATE button, send the LED straightforwardly
		if x < 5 then
			self:queueGUI("sendSelfLED", x - 1, self.gridy - 1, light)
		end

	end,

	-- Parse an incoming page-row command from the Monome
	parsePageButton = function(self, x, s)

		if s == 1 then -- On down-keystrokes...

			if self.slice.off and self.slice.pitch and self.slice.loop then -- If OFF, PITCH, and LOOP are held...

				-- Reset all SCATTER values for every sequence on the page
				self:ctrlPageOffScatter(x)
				self:queueGUI("sendVisibleSeqRows")

			elseif self.slice.pitch and self.slice.loop then -- If both PITCH and LOOP are held...

				-- Set a scatter-bit for every sequence on the page
				self:ctrlPageScatter(self.page, x)
				self:queueGUI("sendVisibleSeqRows")

			elseif self.slice.off and self.slice.pitch then -- If both OFF and PITCH are held...

				-- Reset all PITCH values for every sequence on the page
				self:ctrlPageOffPitch(x)
				self:queueGUI("sendVisibleSeqRows")

			elseif self.slice.off then -- If OFF is held...

				-- If GATE is also held, send PAGE-GATE-OFF command. Else send PAGE-OFF command.
				if self.slice.gate then
					self:ctrlPageGateOff(x)
				else
					self:ctrlPageOff(x)
				end

			elseif self.slice.pitch then -- If PITCH is held...

				-- Set a pitch-bit for every sequence on the active page
				self:ctrlPagePitch(self.page, x)
				self:queueGUI("sendVisibleSeqRows")

			elseif self.slice.swap then -- If OFF is not held, but SWAP is held...

				-- If GATE is also held, send PAGE-GATE-SWAP command. Else send PAGE-SWAP command.
				if self.slice.gate then
					self:ctrlPageGateSwap(x)
					self:queueGUI("updateSeqPage", x)
				else
					self:ctrlPageSwap(x)
				end

			elseif self.slice.gate then -- If neither OFF nor SWAP is held, but GATE is held, then send PAGE-GATE command.

				self:ctrlPageGate(x)

			else -- If neither OFF, SWAP, nor GATE are held...

				-- If the page was double-clicked, tab into overview mode. Else, set overview mode to false, and tab to the given page.
				if self.page == x then
					self.overview = not self.overview
				else
					self.overview = false
					self.page = x
				end

				self:queueGUI("sendPageRow") -- Queue a command to send the page-row buttons to the Monome.

			end

			self:queueGUI("sendMetaGrid") -- Send the seq-rows to the Monome, for any mode.

			if self.slice.gate then
				self:queueGUI("updateSeqPage", x) -- Queue an update to the on-screen GUI to reflect a pending GATE command
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

		if self.slice.off and self.slice.pitch and self.slice.loop then -- If OFF, PITCH, and LOOP are held, send OFF-SCATTER command.
			self:ctrlPressOffScatter(snum)
			self:queueGUI("sendScatterRow", snum)
		elseif self.slice.pitch and self.slice.swap then -- If PITCH and SWAP are held, toggle into Groove Mode for that sequence
			self:toggleGrooveMode(snum)
			self:queueGUI("sendMetaGrid")
			return nil
		elseif self.slice.pitch and self.slice.loop then -- If PITCH and LOOP are held, send SCATTER command.
			self:ctrlPressScatter(snum, col)
			self:queueGUI("sendScatterRow", snum)
		elseif self.slice.off and self.slice.pitch then -- If OFF and PITCH are held, send PRESS-OFF-PITCH command.
			self:ctrlPressOffPitch(snum)
			self:queueGUI("sendPitchRow", snum)
		elseif self.slice.pitch then -- Else if PITCH is held, send PRESS-PITCH command.
			self:ctrlPressPitch(snum, col)
			self:queueGUI("sendPitchRow", snum)
		elseif self.slice.loop then -- Else if LOOP is held, send PRESS-LOOP command.
			self:ctrlPressLoop(snum, col)
		else -- Else, check for commands that interact with GATE
			self:ctrlGate(snum) -- Apply the global gate-value to the sequence, whatever the global gate-value is
			if self.slice.off then -- Else if OFF is held, send PRESS-OFF command.
				self:ctrlPressOff(snum)
			elseif self.slice.swap then -- Else if SWAP is held, send PRESS-SWAP command.
				self:ctrlPressSwap(snum)
			else -- Else, if no control-buttons are held (aside from GATE, optionally), send a PRESS command.
				if self.slice.gate then -- If GATE is held, send the PRESS as a TRIG command, to prevent accidental offsets
					self:ctrlPressTrig(snum, col)
				else -- Else, if GATE isn't held, send a regular PRESS command
					self:ctrlPress(snum, col)
				end
			end
		end

		if self.slice.gate then
			self:queueGUI("updateSeqButton", snum) -- Queue an update to the on-screen GUI to reflect pending GATE
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
