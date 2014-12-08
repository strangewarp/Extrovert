
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

}
