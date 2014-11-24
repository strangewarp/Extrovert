
return {

	-- Start the Puredata [metro] apparatus
	startTempo = function(self)
		pd.send("extrovert-metro-command", "bang", {}) -- Send the [metro] a start-bang
	end,

	-- Stop the Puredata [metro] apparatus
	stopTempo = function(self)
		pd.send("extrovert-metro-command", "stop", {}) -- Stop the [metro] from sending any more ticks
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
		else
			pd.send("extrovert-clock-type", "float", {2})
		end
		
		pd.post("Initialized clock type")
		
	end,

}
