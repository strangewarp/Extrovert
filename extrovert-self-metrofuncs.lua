return {

	-- Start the Puredata [metro] apparatus
	startTempo = function(self)
		if self.clocktype == "master" then
			--pd.send("extrovert-clock-out", "float", {250}) -- Send a CLOCK START command
			--pd.send("extrovert-clock-out", "float", {248}) -- Send a dummy tick command, as per MIDI CLOCK spec
			pd.send("extrovert-metro-command", "initialize", {}) -- Send the [metro] a start-bang with a 1-ms delay, to give MIDI SLAVE devices a space to prepare for ticks
		elseif self.clocktype == "none" then
			pd.send("extrovert-metro-command", "bang", {}) -- Send the [metro] a normal start-bang
		end
	end,

	-- Stop the Puredata [metro] apparatus
	stopTempo = function(self)
		if self.clocktype == "master" then
			--pd.send("extrovert-clock-out", "float", {252}) -- Send a CLOCK END command
		elseif self.clocktype == "none" then
			pd.send("extrovert-metro-command", "stop", {}) -- Stop the [metro] from sending any more ticks
		end
	end,

	-- Propagate a beats-per-minute value to the Puredata tempo apparatus
	propagateBPM = function(self)
		local ms = 60000 / (self.bpm * self.tpq * 4) -- Convert BPM and TPQ into milliseconds
		pd.send("extrovert-metro-speed", "float", {ms})
	end,

	-- Initialize Extrovert's Puredata tempo apparatus
	startClock = function(self)

		if (self.clocktype == "master") then
			pd.send("extrovert-clock-type", "float", {1})
		elseif (self.clocktype == "slave") then
			pd.send("extrovert-clock-type", "float", {2})
		elseif (self.clocktype == "thru") then
			pd.send("extrovert-clock-type", "float", {3})
		elseif (self.clocktype == "none") then
			pd.send("extrovert-clock-type", "float", {4})
		end
		
		pd.post("Initialized clock type")
		
	end,

}