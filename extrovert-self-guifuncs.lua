
return {

	-- Update all sequences in the GUI that have been listed as needing updates
	updateGUI = function(self)
		for k, v in pairs(self.guiqueue) do
			local c = table.remove(v, 1)
			self[c](self, unpack(v))
		end
		self.guiqueue = {}
	end,

	-- Put a deconstructed rendering function into the GUI-rendering queue
	queueGUI = function(self, ...)
		local args = {...}
		table.insert(self.guiqueue, args)
	end,
	
	-- Build the canvas GUI in Extrovert's GUI window
	buildGUI = function(self)

		local seq = self.prefs.gui.seq
		local pg = self.prefs.gui.page
		local bar = self.prefs.gui.sidebar
		
		local hotseats = #self.prefs.hotseatcmds
		
		local barleft = (seq.width * self.gridx) + (seq.xmargin * (self.gridx + 2))
		
		-- Generate background panel
		buildGrid(
			{"extrovert-background"},
			"extrovert-gui-object",
			1,
			0,
			0,
			barleft + bar.width + (bar.xmargin * 2), -- Total width of hotseats bar
			math.max(
				seq.keyheight + (seq.height * (self.gridy - 2)) + (seq.ymargin * self.gridy), -- Total height of sequence grid
				bar.ymargin * (#self.hotseats + 1) -- Total height of hotseats bar
			),
			1,
			1,
			_,
			_,
			_
		)
		
		-- Generate page-label cells
		local keynames = {}
		for x = 0, self.gridx - 1 do
			table.insert(keynames, "extrovert-seq-key-" .. x)
		end
		buildGrid(
			keynames, -- List of tile names
			"extrovert-gui-object", -- Pd object that will receive the GUI objects
			self.gridx, -- Number of X tiles
			seq.xmargin, -- Absolute left position
			seq.ymargin, -- Absolute top position
			seq.width, -- Tile width
			seq.keyheight, -- Tile height
			seq.xmargin, -- Tile X margin
			seq.ymargin, -- Tile Y margin
			_,
			_,
			_
		)
		
		-- Generate sequence-activity grid
		local seqnames = {}
		for y = 0, self.gridy - 3 do
			for x = 0, self.gridx - 1 do
				table.insert(seqnames, "extrovert-seq-" .. (((x * (self.gridy - 2)) + y) + 1))
			end
		end
		buildGrid(
			seqnames, -- List of tile names
			"extrovert-gui-object", -- Pd object that will receive the GUI objects
			self.gridx, -- Number of X tiles
			seq.xmargin, -- Absolute left position
			seq.keyheight + (seq.ymargin * 2), -- Absolute top position
			seq.width, -- Tile width
			seq.height, -- Tile height
			seq.xmargin, -- Tile X margin
			seq.ymargin, -- Tile Y margin
			_,
			_,
			_
		)
		
		-- Generate hotseat tiles
		local seatnames = {}
		for y = 0, hotseats - 1 do
			table.insert(seatnames, "extrovert-hotseat-" .. y)
		end
		buildGrid(
			seatnames,
			"extrovert-gui-object",
			1,
			barleft,
			bar.ymargin,
			bar.width,
			bar.height,
			bar.xmargin,
			bar.ymargin,
			2,
			7,
			bar.height
		)

	end,

	-- Update a given button in the sequence-activity-grid GUI
	updateSeqButton = function(self, k)

		local outname = "extrovert-seq-" .. k
		local outcolor = self.color[9][1]
		
		if self.seq[k].pointer then
			if self.seq[k].incoming.cmd then -- If the sequence is active AND has incoming commands, change to an active-and-pending-color
				outcolor = self.color[6][2]
			else -- If the sequence is active AND has NO incoming commands, change to an active-color
				outcolor = self.color[8][1]
			end
		elseif self.seq[k].incoming.cmd then -- If the sequence has incoming commands AND is NOT active, change to a pending-color
			outcolor = self.color[7][1]
		end
		
		pd.send("extrovert-color-out", "list", rgbOutList(outname, outcolor, outcolor))

	end,

	-- Update all of a single page's activity-buttons in the sequence-activity-grid GUI
	updateSeqPage = function(self, i)
		for k = 1, self.gridy - 2 do
			self:updateSeqButton(k + ((i - 1) * (self.gridy - 2)))
		end
	end,

	-- Update the entire sequence-activity-grid GUI
	updateSeqGrid = function(self)
		for k = 1, (self.gridy - 2) * self.gridx do
			self:updateSeqButton(k)
		end
	end,

	-- Update the savefile hotseat tile GUI
	updateHotseatBar = function(self)

		for k, v in ipairs(self.hotseats) do
		
			local outname = "extrovert-hotseat-" .. (k - 1)
			
			if k == self.activeseat then
				pd.send("extrovert-color-out", "list", rgbOutList(outname, self.color[2][1], self.color[5][1]))
			else
				pd.send("extrovert-color-out", "list", rgbOutList(outname, self.color[3][1], self.color[5][1]))
			end
			
			pd.send(outname, "label", {k .. ". " .. v})
			
		end

	end,

	-- Populate the page-label tiles
	populateLabels = function(self)
		for i = 0, self.gridx - 1 do -- Colorize and label the page-label cells
			pd.send("extrovert-color-out", "list", rgbOutList("extrovert-seq-key-" .. i, self.color[7][1], self.color[5][1]))
			pd.send("extrovert-seq-key-" .. i, "label", {"P" .. (i + 1)})
		end
	end,

	-- Populate the sequencer's entire GUI with the relevant colors and data
	populateGUI = function(self)
		pd.send("extrovert-color-out", "list", rgbOutList("extrovert-background", self.color[9][2], self.color[9][2]))
		self:populateLabels()
		self:updateSeqGrid()
		self:updateHotseatBar()
	end,

}
