return {
	
	-- Propagate the user-defined OSC port whereby API commands will be received
	startAPI = function(self)
		pd.send("extrovert-api-port", "list", {self.prefs.api.port})
	end,

	-- Parse an incoming OSC command from the API
	parseOSC = function(self, t)

		-- Get the incoming command-name
		local cmdname = table.remove(t, 1)

		if cmdname == 'note' then -- Parse an example-note command
			pd.send("extrovert-examplenote", "list", t)
		elseif cmdname == 'loadmidi' then -- Parse a load-file command
			self:loadMidiFile(t[1])
		elseif cmdname == 'monomebutton' then -- Parse a spoof-monome-button command
			self:parseVirtualButtonPress(t)
		end

	end,

}