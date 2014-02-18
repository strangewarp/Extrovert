return {
	
	-- Send a single LED's data to the Monome apparatus (x and y are 0-indexed!)
	sendLED = function(x, y, s)
		pd.send("extrovert-monome-out-led", "list", {x, y, s})
	end,

	-- Send commands through the Monome apparatus to darken every button's LED
	darkenAllButtons = function()
		pd.send("extrovert-monome-out-all", "list", {0}) -- Send darkness to the Puredata Monome-grid apparatus
	end,

}