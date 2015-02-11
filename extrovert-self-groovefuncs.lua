
return {

	-- Toggle/untoggle Groove Mode	
	toggleGrooveMode = function(self, s)

		if self.groove then

			self.page = math.ceil(self.g.seqnum / (self.gridy * 2))

			-- Untoggle all command-buttons, if any are being pressed
			self.g.track = false
			self.g.rec = false
			self.g.chanerase = false
			self.g.erase = false
			self.g.gate = false

		else

			self.g.seqnum = s

		end

		self.groove = not self.groove

	end,

	-- Play the current Groove Mode note
	playGrooveNote = function(self)



	end,

	-- Insert the current Groove Mode note
	insertGrooveNote = function(self)



	end,

}
