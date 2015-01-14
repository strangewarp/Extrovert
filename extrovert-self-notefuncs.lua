
return {
	
	-- Send automatic noteoffs for duration-based notes that have expired
	decayAllSustains = function(self)

		for chan, notes in pairs(self.sustain) do
			if next(notes) ~= nil then -- Check for active note-sustains within the channel before trying to act upon them
				for note, tab in pairs(notes) do
				
					local dur = tab.sust

					self.sustain[chan][note].sust = math.max(0, dur - 1) -- Decrease the relevant duration value
				
					if dur == 0 then -- If the duration has expired...
						self:noteParse({chan, 128, note, 127, 0}) -- Parse a noteoff for the relevant channel and note
					end
					
				end
			end
		end

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
						note[4] = math.max(1, math.min(127, note[4] + v.bottom + math.floor(v.breadth * self.dial[k])))
					end
				end
			end
		
		end

		if rangeCheck(note[2], 128, 159) then -- If this is a NOTE-ON or NOTE-OFF command, modify the contents of the MIDI-sustain table
		
			-- If the corresponding sustain value isn't nil, copy it to sust; else leave sust set to -1
			local sust = -1
			if self.sustain[note[1]][note[3]] ~= nil then
				sust = self.sustain[note[1]][note[3]].sust
			end
		
			if note[2] == 144 then -- For ON-commands, increase the note's global duration value by the incoming duration amount, if applicable
				sust = math.max(note[5], sust)
			else -- For OFF-commands, set sust to -1, so that the corresponding sustain value is nilled out
				sust = -1
			end
			
			if sust == -1 then -- If the sustain was nil and a note-ON didn't occur, or if a note-off occurred, set the sustain to nil

				-- If multiple note-ons are being represented by the same sustain, then send multiple note-offs to compensate.
				-- Some MIDI devices require this, or else get sticky notes.
				while self.sustain[note[1]][note[3]].count > 1 do
					self.sustain[note[1]][note[3]].count = self.sustain[note[1]][note[3]].count - 1
					self:noteSend(note)
				end

				self.sustain[note[1]][note[3]] = nil

			else -- If a note-ON occurred, set the relevant sustain to the note's duration value, and increase the sustain-count
				self.sustain[note[1]][note[3]] = self.sustain[note[1]][note[3]] or {sust = 0, count = 0}
				self.sustain[note[1]][note[3]].sust = sust
				self.sustain[note[1]][note[3]].count = self.sustain[note[1]][note[3]].count + 1
			end
			
		end
		
		self:noteSend(note)
		
	end,

	-- Send all notes within a given tick in a given sequence
	sendTickNotes = function(self, s, t)
		if self.seq[s].tick[t] ~= nil then
			for tick, note in ipairs(self.seq[s].tick[t]) do
				self:noteParse(note)
			end
		end
	end,

}
