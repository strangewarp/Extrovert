return {
	
	-- Send an outgoing MIDI command, via the Puredata MIDI apparatus
	noteSend = function(self, n)

		if n[2] == 128 then
			pd.send("extrovert-midiout-note", "list", {n[3], 0, n[1]})
			--pd.post("NOTE-OFF: " .. n[1] + n[2] .. " " .. n[3] .. " 0") -- DEBUGGING
		elseif n[2] == 144 then
			pd.send("extrovert-midiout-note", "list", {n[3], n[4], n[1]})
			--pd.post("NOTE-ON: " .. n[1] + n[2] .. " " .. n[3] .. " " .. n[4]) -- DEBUGGING
		elseif n[2] == 160 then
			pd.send("extrovert-midiout-poly", "list", {n[3], n[4], n[1]})
			--pd.post("POLY-TOUCH: " .. n[1] + n[2] .. " " .. n[3] .. " " .. n[4]) -- DEBUGGING
		elseif n[2] == 176 then
			pd.send("extrovert-midiout-control", "list", {n[3], n[4], n[1]})
			--pd.post("CONTROL-CHANGE: " .. n[1] + n[2] .. " " .. n[3] .. " " .. n[4]) -- DEBUGGING
		elseif n[2] == 192 then
			pd.send("extrovert-midiout-program", "list", {n[3], n[1]})
			--pd.post("PROGRAM-CHANGE: " .. n[1] + n[2] .. " " .. n[3]) -- DEBUGGING
		elseif n[2] == 208 then
			pd.send("extrovert-midiout-press", "list", {n[3], n[1]})
			--pd.post("MONO-TOUCH: " .. n[1] + n[2] .. " " .. n[3]) -- DEBUGGING
		elseif n[2] == 224 then
			pd.send("extrovert-midiout-bend", "list", {n[3], n[1]})
			--pd.post("PITCH-BEND: " .. n[1] + n[2] .. " " .. n[3]) -- DEBUGGING
		elseif n[2] == -10 then -- Local TEMPO command
			self.bpm = n[3]
			self:propagateBPM() -- Propagate new tick speed
			self:updateControlTile("bpm") -- Update BPM tile in GUI
		end
		
	end,

	-- Parse an outgoing MIDI command, before actually sending it
	noteParse = function(self, note)

		if note[2] == 144 then -- If this is a NOTE-ON command, filter the note's contents through all applicable ADC values

			for k, v in ipairs(self.adc) do -- For all ADCs...
				if v.channel == note[1] then -- If the ADC applies to this note's MIDI channel...
					if v.target == "note" then -- If the target is NOTE, modify the NOTE value based on the dial's position
						note[3] = math.max(0, math.min(127, note[3] + v.bottom + math.floor(v.breadth * self.dial[k])))
					elseif v.target == "velocity" then -- If the target is VELOCITY, modify the VELOCITY value based on the dial's position
						note[4] = math.max(0, math.min(127, note[4] + v.bottom + math.floor(v.breadth * self.dial[k])))
					end
				end
			end
		
		end

		if rangeCheck(note[2], 128, 159) then -- If this is a NOTE-ON or NOTE-OFF command, modify the contents of the MIDI-sustain table
		
			local sust = self.sustain[note[1]][note[3]] or -1 -- If the corresponding sustain value isn't nil, copy it to sust; else set sust to -1
		
			if note[2] == 144 then -- For ON-commands, increase the note's global duration value by the incoming duration amount, if applicable
				sust = math.max(note[5], sust)
			else -- For OFF-commands, set sust to -1, so that the corresponding sustain value is nilled out
				sust = -1
			end
			
			if sust == -1 then -- If the sustain was nil and a note-ON didn't occur, or if a note-off occurred, set the sustain to nil
				self.sustain[note[1]][note[3]] = nil
			else -- If a note-ON occurred, set the relevant sustain to the note's duration value
				self.sustain[note[1]][note[3]] = sust
			end
			
		end
		
		self:noteSend(note)
		
	end,

	-- Send NOTE-OFFs for all presently playing notes
	haltAllSustains = function(self)
		for chan, susts in pairs(self.sustain) do
			if next(susts) ~= nil then
				for note, _ in pairs(susts) do
					self:noteParse({128 + chan, note, 127})
				end
			end
		end
	end,

	-- Send all notes within a given tick in a given sequence
	sendTickNotes = function(self, s, t)
		if self.seq[s].tick[t] ~= nil then
			for tick, note in ipairs(self.seq[s].tick[t]) do
				self:noteParse(note)
			end
		end
	end,

	-- Convert flags in the "incoming" table into a sequence's internal states
	parseIncomingFlags = function(self, s)

		self:swapAllSeqFlags() -- Swap all sequences and pages in the self.swap and self.pageswap tabs

		-- If there's an incoming OFF flag...
		if self.seq[s].incoming.off then

			-- Deactivate the sequence
			self.seq[s].active = false

		else -- Else, if there isn't an incoming OFF flag...
		
			self.seq[s].active = true -- Flag the sequence as active
			
			if self.seq[s].incoming.range == nil then -- If the incoming range boundaries are unset, set them to the default values
				self.seq[s].loop.low = 1
				self.seq[s].loop.high = self.gridx
			else
				local r = self.seq[s].incoming.range
				if #r == 1 then -- If there is only one range boundary, set it to both low and high
					self.seq[s].loop.low = r[1]
					self.seq[s].loop.high = r[1]
				else -- Else, if there are 2 or more range points, set low and high to the two most-recently-entered ones
					local low = r[#r - 1]
					local high = r[#r]
					if low > high then -- If low is greater than high, switch their values
						low, high = high, low
					end
					self.seq[s].loop.low, self.seq[s].loop.high = low, high
				end
			end
			
			local chunksize = #self.seq[s].tick / self.gridx -- Calculate the size of each subsection
			local bpoint = ((self.seq[s].loop.low - 1) * chunksize) + 1 -- Calculate the tick that corresponds to the incoming button-position
			
			-- If RESUME is true...
			if self.seq[s].incoming.resume then
				-- If the seq's old tick-pointer doesn't fall between the ticks corresponding to low/high, resume it on the low subsection. Otherwise leave it alone
				if not rangeCheck(self.seq[s].pointer, (self.seq[s].loop.low - 1) * chunksize, (self.seq[s].loop.high - 1) * chunksize) then
					self.seq[s].pointer = ((self.seq[s].pointer - 1) % chunksize) + bpoint -- Transpose the previous pointer position into the incoming button's subsection
				end
			else -- Else, change the pointer position to reflect the button-press position
				self.seq[s].pointer = (chunksize * (self.seq[s].incoming.button - 1)) + 1
			end
			
		end

		-- Empty the incoming table
		self.seq[s].incoming = {}
		
		self:sendMetaSeqRow(s) -- Send Monome sequence rows through the meta apparatus
		
		self:updateSeqButton(s) -- Update the sequence's on-screen GUI button

	end,

	-- Iterate through a sequence's incoming flags, increase its tick pointer under certain conditions, and send off all relevant notes
	iterateSequence = function(self, s)

		if next(self.seq[s].incoming) ~= nil then -- If the sequence has incoming flags...
		
			if self.seq[s].incoming.gate then -- If the GATE flag is active...
				if ((self.tick - 1) % math.floor(self.longticks / self.seq[s].incoming.gate)) == 0 then -- On global ticks that correspond to the gate-tick amount...
					self:parseIncomingFlags(s)
				end
			else -- If the GATE flag is false, process the flags on the soonest tick
				self:parseIncomingFlags(s)
			end
			
		end

		if self.seq[s].active then -- If the sequence is active...

			-- Get subsection size
			local subsize = #self.seq[s].tick / self.gridx

			-- Get current subsection, and previous subsection
			local newsub = math.ceil(self.gridx * (self.seq[s].pointer / #self.seq[s].tick))
			local oldsub = math.ceil(self.gridx * ((((self.seq[s].pointer - 2) % #self.seq[s].tick) + 1) / #self.seq[s].tick))

			-- Bound newsub and oldsub to subsections within the sequence's loop
			if newsub > self.seq[s].loop.high then
				newsub = self.seq[s].loop.low
			end
			if oldsub < self.seq[s].loop.low then
				oldsub = self.seq[s].loop.high
			end

			-- Increment the pointer within loop boundaries, and then send tick-notes, on every global tick
			local oldpoint = self.seq[s].pointer
			self.seq[s].pointer = (self.seq[s].pointer % (self.seq[s].loop.high * subsize)) + 1
			if self.seq[s].pointer < oldpoint then
				self.seq[s].pointer = ((self.seq[s].loop.low - 1) * subsize) + 1
			end
			self:sendTickNotes(s, self.seq[s].pointer)
		
			if newsub ~= oldsub then -- If the new subsection corresponds to a different button than the previous subsection...
				self:sendMetaSeqRow(s) -- Send Monome sequence rows through the meta apparatus
			end

		end
		
	end,

	-- Send automatic noteoffs for duration-based notes that have expired
	decayAllSustains = function(self)

		for chan, notes in pairs(self.sustain) do
			if next(notes) ~= nil then -- Check for active note-sustains within the channel before trying to act upon them
				for note, dur in pairs(notes) do
				
					self.sustain[chan][note] = math.max(0, dur - 1) -- Decrease the relevant duration value
				
					if dur == 0 then -- If the duration has expired...
						self:noteParse({chan, 128, note, 127, 0}) -- Parse a noteoff for the relevant channel and note
					end
					
				end
			end
		end

	end,

	-- Swap the activity and flags of two sequences
	swapSeqFlags = function(self, s1, s2)

		-- Unset SWAP flags
		self.seq[s1].incoming.swap = nil
		self.seq[s2].incoming.swap = nil

		-- Swap range boundaries
		self.seq[s1].incoming.range = {self.seq[s2].loop.low, self.seq[s2].loop.high}
		self.seq[s2].incoming.range = {self.seq[s1].loop.low, self.seq[s1].loop.high}

		-- Swap pointer positions, adjusted against one another's concrete size
		self.seq[s1].pointer, self.seq[s2].pointer =
			math.floor(self.seq[s2].pointer / (#self.seq[s2].tick / #self.seq[s1].tick)),
			math.floor(self.seq[s1].pointer / (#self.seq[s1].tick / #self.seq[s2].tick))

	end,

	-- Swap the LOOP and INCOMING flags, and comparable pointer positions, of every sequence in the SWAP queue, if applicable
	swapAllSeqFlags = function(self)

		-- Swap the activity of two pages' worth of sequences
		if next(self.pageswap) ~= nil
		and ((#self.pageswap) > 1)
		then
			for i = 1, self.gridy - 2 do
				local s = i + ((self.gridy - 2) * (self.pageswap[1] - 1))
				local s2 = i + ((self.gridy - 2) * (self.pageswap[2] - 1))
				self:swapSeqFlags(s, s2)
			end
		end

		-- Swap the activity of all swap-pairs
		if (next(self.swap) ~= nil)
		and (#self.swap[1] > 1)
		then
			for k, v in ipairs(self.swap) do
				if #v == 2 then
					self:swapSeqFlags(v[1], v[2])
				end
			end
		end

		-- Clear the SWAP and PAGESWAP tables only when this function is activated
		self.swap = {}
		self.pageswap = {}

	end,

	-- Cycle through all MIDI commands on the active tick within every active sequence
	iterateAllSequences = function(self)

		-- Increment global tick, bounded by global gate-size
		self.tick = (self.tick % self.longticks) + 1
		
		self:decayAllSustains()

		-- Send all regular commands within all sequences, and check against longseqs
		for i = 1, (self.gridy - 2) * self.gridx do
			self:iterateSequence(i)
		end

		self:checkForLongestLoop()

	end,

	-- Set a sequence's incoming control-flags, based on the active global control-flags
	setIncomingFlags = function(self, s, button)

		-- Put all control-flag states into the sequence's incoming-commands table
		for k, v in pairs(self.ctrlflags) do
			self.seq[s].incoming[k] = v
		end

		if self.ctrlflags.swap then -- If the SWAP command is active...

			-- If no swap-pairs already exist, or the active swap-pair is full, insert a new-swap pair
			if (next(self.swap) == nil)
			or (#self.swap[#self.swap] == 2)
			then
				table.insert(self.swap, {})
			end

			-- Put the sequence into the top swap-pair
			table.insert(self.swap[#self.swap], s)

		end
		
		if self.ctrlflags.loop then -- If the LOOP command is active...
			self.seq[s].incoming.range = self.seq[s].incoming.range or {} -- If incoming.range is nil, build it
			table.insert(self.seq[s].incoming.range, button) -- Insert the x value into the target sequence's range-button table
		end
		
		-- Set the incoming button to the given subsection-button
		self.seq[s].incoming.button = button

		if not self.seq[s].active then -- If the sequence isn't already active...
			self.seq[s].incoming.activated = true -- Show that the sequence was newly activated, and that it should therefore be treated slightly differently on its first tick
		end
		
	end,

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