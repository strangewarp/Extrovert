
local Extrovert = pd.Class:new():register("extrovert-sequencer")

local MIDI = require('MIDI')



-- Check whether a value falls within a particular range; return true or false
local function rangeCheck(val, low, high)

	if high < low then
		low, high = high, low
	end

	if (val >= low)
	and (val <= high)
	then
		return true
	end
	
	return false

end

-- Recursively copy all sub-tables and sub-items, when copying from one table to another. Invoke as: newtable = deepCopy(oldtable, {})
local function deepCopy(t, t2)

	for k, v in pairs(t) do
	
		if type(v) ~= "table" then
			t2[k] = v
		else
			local temp = {}
			deepCopy(v, temp)
			t2[k] = temp
		end
		
	end
	
	return t2
	
end

-- Compare the contents of two tables of type <t = {v1 = v1, v2 = v2, ...}>, and return true only on an exact match.
local function crossCompare(t, t2)

	for v in pairs(t) do
		if t[v] ~= t2[v] then
			return false
		end
	end
	for v in pairs(t2) do
		if t[v] ~= t2[v] then
			return false
		end
	end

	return true

end



-- Build a properly-formatted list of object atoms, for passing into Pd
local function buildObject(xpos, ypos, xsize, ysize, stitle, rtitle, label, labelx, labely, fontnum, fontsize, bgcolor, labelcolor)

	local obj = {
		"obj", -- Object tag
		xpos or 1, -- X-position in pixels
		ypos or 1, -- Y-position in pixels
		"cnv", -- Canvas tag
		math.min(xsize, ysize), -- Selectable box size
		xsize or 20, -- Canvas object width in pixels
		ysize or 20, -- Canvas object height in pixels
		stitle or "empty", -- Name of another object that this object passes its messages onwards to
		rtitle or "empty", -- Object name
		label or "empty", -- Object label
		labelx or 1, -- Label X offset
		labely or 6, -- Label Y offset
		fontnum or 0, -- Label font number
		fontsize or 10, -- Label font size
		bgcolor or -233017, -- Background color
		labelcolor or -262144, -- Label color
		0 -- Not sure what this is for, but it seems to be essential
	}
	
	return obj
	
end

-- Build a grid of buttons out of a table of object names
local function buildGrid(names, sendto, x, absx, absy, width, height, mx, my, labelx, labely, fsize)

	for k, v in ipairs(names) do
	
		out = buildObject(
			absx + ((width + mx) * ((k - 1) % x)), -- X-position
			absy + ((height + my) * math.floor((k - 1) / x)), -- Y-position
			width, -- Width
			height, -- Height
			_,
			v, -- Addressable object name
			_,
			labelx,
			labely,
			_,
			fsize, -- Font size
			_,
			_,
			_
		)
		
		pd.send(sendto, "list", out)
		pd.post("Extrovert-GUI: Spawned object " .. v)
		
	end
	
end

function Extrovert:buildGUI()

	local seq = self.prefs.gui.seq
	local pg = self.prefs.gui.page
	local ed = self.prefs.gui.editor
	local bar = self.prefs.gui.sidebar
	
	local hotseats = #self.prefs.hotseatcmds
	
	local edleft = (seq.width * self.gridx) + (seq.xmargin * (self.gridx + 2))
	
	local segments = {
		{"tick", ed.width.tick},
		{"chan", ed.width.chan},
		{"cmd", ed.width.cmd},
		{"note", ed.width.note},
		{"velo", ed.width.velo},
		{"dur", ed.width.dur}
	}
	
	local edcolx = 0
	for _, v in pairs(segments) do
		edcolx = edcolx + v[2]
	end
	
	-- Generate background panel
	buildGrid(
		{"extrovert-background"},
		"extrovert-gui-object",
		1,
		0,
		0,
		edleft + math.max( -- Total width of all GUI elements
			(pg.width * self.gridx) + (pg.xmargin * self.gridx), -- Total width of page-summary panel
			(edcolx * ed.cols) + (ed.xmargin * ed.cols) + bar.width + (bar.xmargin * 2) -- Total width of editor panel, plus info/hotseat bars
		),
		math.max(
			(seq.height * ((self.gridy - 2) * self.gridx)) + (seq.ymargin * (((self.gridy - 2) * self.gridx) + 1)), -- Total height of sequence grid
			(pg.height * (self.gridy - 2)) + (pg.ymargin * 2) + ((self.gridy - 2) * 2) + (bar.height * (#bar.tiles + 1)) + (bar.ymargin * #bar.tiles), -- Total height of page summary plus sidebar
			(pg.height * (self.gridy - 2)) + (pg.ymargin * 2) + ((self.gridy - 2) * 2) + (ed.height * ed.rows) + (ed.ymargin * ed.rows) -- Total height of page summary plus editor
		),
		1,
		1,
		_,
		_,
		_
	)
	
	-- Generate sequence grid
	local seqnames = {}
	for y = 0, ((self.gridy - 2) * self.gridx) - 1 do
		for x = 0, self.gridx - 1 do
			table.insert(seqnames, "extrovert-seq-" .. y .. "-" .. x)
		end
	end
	
	buildGrid(
		seqnames, -- List of tile names
		"extrovert-gui-object", -- Pd object that will receive the GUI objects
		self.gridx, -- Number of X tiles
		seq.xmargin, -- Absolute left position
		seq.ymargin, -- Absolute top position
		seq.width, -- Tile width
		seq.height, -- Tile height
		seq.xmargin, -- Tile X margin
		seq.ymargin, -- Tile Y margin
		_,
		_,
		_
	)
	
	-- Generate page overview tiles
	for x = 0, self.gridx - 1 do
	
		local pagenames = {}
		
		for y = 0, self.gridy - 3 do
			table.insert(pagenames, "extrovert-page-" .. x .. "-" .. y)
		end
		
		buildGrid(
			pagenames,
			"extrovert-gui-object",
			1,
			edleft + (pg.width * x) + (pg.xmargin * x),
			pg.ymargin,
			pg.width,
			pg.height,
			pg.xmargin,
			2,
			_,
			_,
			_
		)
		
	end
	
	-- Generate editor columns
	for x = 0, ed.cols - 1 do
	
		for y = 0, ed.rows - 1 do
		
			local addleft = 0
			for k, v in ipairs(segments) do
				
				local objname = "extrovert-editor-" .. x .. "-" .. y .. "-" .. v[1]

				pd.send(
					"extrovert-gui-object",
					"list",
					buildObject(
						edleft + addleft + (edcolx * x) + (ed.xmargin * x),
						(pg.height * (self.gridy - 2)) + (pg.ymargin * 2) + ((self.gridy - 2) * 2) + (ed.height * y) + (ed.ymargin * y),
						v[2],
						ed.height,
						_,
						objname,
						_,
						2,
						7,
						_,
						ed.height,
						_,
						_
					)
				)
		
				pd.post("Extrovert-GUI: Spawned object " .. objname)

				addleft = addleft + v[2]
			
			end
		
		end
	
	end
	
	-- Generate side-panel tiles
	local sidenames = {}
	for _, v in ipairs(bar.tiles) do
		table.insert(sidenames, v[5])
	end
	buildGrid(
		sidenames,
		"extrovert-gui-object",
		1,
		edleft + (edcolx * ed.cols) + (ed.xmargin * (ed.cols + 1)),
		(pg.height * (self.gridy - 2)) + (pg.ymargin * 2) + ((self.gridy - 3) * 2) + bar.ymargin,
		bar.width,
		bar.height,
		bar.xmargin,
		bar.ymargin,
		2,
		7,
		bar.height
	)
	
	-- Generate hotseats, below side-panel
	local seatnames = {}
	for y = 0, hotseats - 1 do
		table.insert(seatnames, "extrovert-hotseat-" .. y)
	end
	buildGrid(
		seatnames,
		"extrovert-gui-object",
		1,
		edleft + (edcolx * ed.cols) + (ed.xmargin * (ed.cols + 1)),
		(pg.height * (self.gridy - 2)) + (pg.ymargin * 2) + ((self.gridy - 3) * 2) + (bar.height * (#bar.tiles + 1)) + (bar.ymargin * (#bar.tiles + 1)),
		bar.width,
		bar.height,
		bar.xmargin,
		bar.ymargin,
		2,
		7,
		bar.height
	)

end

-- Get a table of RGB values (0-255), and return a table of RGB-normal, RGB-dark, RGB-light
local function modColor(color)

	local colout = {color, {}, {}}
	
	for i = 1, 3 do
		colout[2][i] = math.max(0, color[i] - 30)
		colout[3][i] = math.min(255, color[i] + 30)
	end
	
	return colout

end

-- Arrange a send-name, a color table, and a message-color table into a flat list
local function rgbOutList(name, ctab, mtab)

	return {name, ctab[1], ctab[2], ctab[3], mtab[1], mtab[2], mtab[3]}

end

-- Translate a MIDI note byte into a readable note value
function Extrovert:readableNote(note)

	local key = (note % 12) + 1
	local octave = math.floor(note / 12)
	
	return self.notenames[key] .. string.rep("-", 2 - self.notenames[key]:len()) .. octave

end

-- Update a given row in the sequence-grid GUI
function Extrovert:updateSeqRow(y)

	for x = 1, self.gridx do
	
		local outname = "extrovert-seq-" .. (y - 1) .. "-" .. (x - 1)
		local outcol = self.color[9][1]
		
		if self.seq[y].active == true then -- Change the row's colors if it is currently active
			if self.seq[y].subdivide == x then -- Color the active cell uniquely
				outcol = self.color[8][1]
			else
				outcol = self.color[7][1]
			end
		end
		
		pd.send("extrovert-color-out", "list", rgbOutList(outname, outcol, outcol))
		
	end

end

-- Update the entire sequence-grid GUI
function Extrovert:updateSeqGrid()

	for y = 1, (self.gridy - 2) * self.gridx do
		self:updateSeqRow(y)
	end

end

-- Update the entire page summary panel GUI
function Extrovert:updatePagePanel()

	for x = 0, self.gridx - 1 do
	
		for y = 0, self.gridy - 3 do
		
			local outname = "extrovert-page-" .. x .. "-" .. y
			local outcol = self.color[7][2]
			
			local guikey = (x * (self.gridy - 2)) + y + 1 -- Convert the page-tile's x,y coords into a sequence key
		
			if guikey == self.key then -- Give the active key's overview tile an active color
				outcol = self.color[8][1]
			elseif (((guikey % #self.seq) + 1) == self.key)
			or ((((guikey - 2) % #self.seq) + 1) == self.key)
			then -- Give the adjacent keys' overview tiles a lighter color
				outcol = self.color[7][3]
			end
			
			pd.send("extrovert-color-out", "list", rgbOutList(outname, outcol, outcol))
		
		end
	
	end

end

-- Update an item's internal segments in the editor panel GUI
function Extrovert:updateEditorItem(x, y, tick, notekey, chan, cmd, note, velo, dur)

	local xcenter = math.ceil((self.prefs.gui.editor.cols - 1) / 2)
	local ycenter = math.floor((self.prefs.gui.editor.rows - 1) / 2)
	
	local itemname = "extrovert-editor-" .. x .. "-" .. y
	
	local bgcolor = self.color[4]
	local labelcolor = self.color[5]
	
	local bg = bgcolor[1]
	local bgalt = bgcolor[3]
	local label = labelcolor[1]
	
	if (type(cmd) == "number")
	and (type(note) == "number")
	then -- Color notes and commands differently from empty and skipped ticks
		if rangeCheck(cmd, 128, 159) then
			bgcolor = self.color[2]
		elseif rangeCheck(cmd, 160, 255)
		or (cmd == -10)
		then
			bgcolor = self.color[3]
		end
	else
		cmd = tostring(cmd)
	end
	
	-- If friendly-note-view is enabled, make certain data values more human-readable
	if self.friendlyview == true then
	
		if (type(note) == "number")
		and rangeCheck(cmd, 128, 159)
		then -- Convert a numerical MIDI-NOTE value into a more human-readable note
			note = self:readableNote(note)
		end
		
		-- Convert a numerical command value into a human-readable word
		for k, v in pairs(self.cmdnames) do
			if cmd == v[2] then
				cmd = v[1]
				break
			end
		end
		
	end
	
	-- Assign proper colors to any items covered by the copypaste range
	if self.copy.top
	and self.copy.bot
	and (x == xcenter)
	and (type(tick) == "number")
	then
	
		if (tick > self.copy.top)
		and (tick < self.copy.bot)
		then
		
			bgcolor = self.color[7]
			labelcolor = self.color[6]
		
		elseif (tick == self.copy.top)
		and (tick == self.copy.bot)
		then
		
			if (notekey == false)
			or rangeCheck(notekey, self.copy.notetop, self.copy.notebot)
			then
				bgcolor = self.color[7]
				labelcolor = self.color[6]
			end
		
		elseif tick == self.copy.top then
		
			if (notekey == false)
			or (notekey >= self.copy.notetop)
			then
				bgcolor = self.color[7]
				labelcolor = self.color[6]
			end
		
		elseif tick == self.copy.bot then
		
			if (notekey == false)
			or (notekey <= self.copy.notebot)
			then
				bgcolor = self.color[7]
				labelcolor = self.color[6]
			end
		
		end
	
	end
	
	if (type(tick) ~= "number")
	and (tonumber(cmd) > 0)
	then -- Give some color to skipped-tick rows that contain notes
		bgcolor = self.color[3]
	end
	
	if x == xcenter then -- Use regular-brightness colors in the active column
	
		if (type(tick) == "number")
		and ((tick % (#self.seq[self.key].tick / self.gridx)) == 1)
		then -- Highlight ticks that start a triggerable segment of the active sequence
			labelcolor = self.color[8]
			label = labelcolor[3]
			bg = bgcolor[3]
			bgalt = bgcolor[3]
		else -- Use regular shading for regular ticks
			label = labelcolor[1]
			bg = bgcolor[1]
			bgalt = bgcolor[3]
		end
		
	else -- Use darkened colors in the non-active columns
		label = labelcolor[2]
		bg = bgcolor[2]
		bgalt = bgcolor[1]
	end
	
	if y == ycenter then
		if x == xcenter then -- On the active editor item only, invert the background and label colors
			bg, label = label, bg
			bgalt = labelcolor[3]
		else -- Use brightened colors on the active row
			label = labelcolor[3]
			bg = bgcolor[1]
			bgalt = bgcolor[3]
		end
	end
	
	pd.send("extrovert-color-out", "list", rgbOutList(itemname .. "-tick", bg, label))
	pd.send(itemname .. "-tick", "label", {tostring(tick)})
	
	pd.send("extrovert-color-out", "list", rgbOutList(itemname .. "-chan", bgalt, label))
	pd.send(itemname .. "-chan", "label", {tostring(chan)})
	
	pd.send("extrovert-color-out", "list", rgbOutList(itemname .. "-cmd", bg, label))
	pd.send(itemname .. "-cmd", "label", {tostring(cmd)})
	
	pd.send("extrovert-color-out", "list", rgbOutList(itemname .. "-note", bgalt, label))
	pd.send(itemname .. "-note", "label", {tostring(note)})
	
	pd.send("extrovert-color-out", "list", rgbOutList(itemname .. "-velo", bg, label))
	pd.send(itemname .. "-velo", "label", {tostring(velo)})
	
	pd.send("extrovert-color-out", "list", rgbOutList(itemname .. "-dur", bgalt, label))
	pd.send(itemname .. "-dur", "label", {tostring(dur)})
	
end

-- Update a column of items in the editor panel GUI
function Extrovert:updateEditorColumn(x)

	local cols = self.prefs.gui.editor.cols
	local rows = self.prefs.gui.editor.rows

	local xcenter = math.ceil((self.prefs.gui.editor.cols - 1) / 2)
	local ycenter = math.floor((rows - 1) / 2)
	
	-- Offset the ticks table accordingly, for all visible-but-non-active sequences
	local ticks = self.seq[((((self.key + x) - xcenter) - 1) % #self.seq) + 1].tick

	local visibleitems = {}
	
	for q = self.pointer, #ticks + (self.pointer - 1), self.quant do -- Seek out and organize the values for a properly time-dilated column
	
		local qkey = ((q - 1) % #ticks) + 1
		local items = ticks[qkey]
		
		if (items[1] ~= nil)
		and (#items >= 1)
		then -- Insert all notes and commands that fall on uncollapsed ticks
			for k, v in ipairs(items) do
				table.insert(visibleitems, {qkey, k, unpack(v)})
			end
		else -- When an uncollapsed tick is empty, insert an empty item
			table.insert(visibleitems, {qkey, false, "--", "---", "------", "---", "----"})
		end
		
		if self.quant ~= 1 then -- If the quantization value isn't a single tick, insert collapsed items that display the number of notes skipped between editor items
		
			local skippeditems = 0
			
			for i = qkey + 1, qkey + (self.quant - 1) do
				local ikey = ((i - 1) % #ticks) + 1
				if ticks[ikey][1] ~= nil then
					skippeditems = skippeditems + #ticks[ikey]
				end
			end
			
			table.insert(visibleitems, {".....", false, "..", skippeditems, "skipped", "...", "...."})
			
		end
		
	end
	
	-- If the notepointer doesn't occupy the first item of a tick, cycle around the visible items until the proper item matches the active row
	if self.notepointer > 1 then
		for i = 1, self.notepointer - 1 do
			table.insert(visibleitems, table.remove(visibleitems, 1))
		end
	end

	local botkey = 1
	for y = ycenter, rows - 1 do -- Fill the items from the center-row to the end-row
		local v = visibleitems[botkey]
		self:updateEditorItem(x, y, unpack(v))
		botkey = (botkey % #visibleitems) + 1
	end
	
	local topkey = #visibleitems
	for y = ycenter - 1, 0, -1 do -- Fill the items from just above the center-row to the top-row
		local v = visibleitems[topkey]
		self:updateEditorItem(x, y, unpack(v))
		topkey = ((topkey - 2) % #visibleitems) + 1
	end

end

-- Update the main (central) editor column
function Extrovert:updateMainEditorColumn()

	self:updateEditorColumn(math.ceil(self.prefs.gui.editor.cols / 2) - 1)

end

-- Update the entire editor panel GUI
function Extrovert:updateEditorPanel()

	for x = 0, self.prefs.gui.editor.cols - 1 do
		self:updateEditorColumn(x)
	end

end

-- Update a single tile in the control bar
function Extrovert:updateControlTile(key)

	local outval = ""

	-- Select tile by its key, or its corresponding variable name
	local tile = false
	if type(key) == "number" then
		tile = self.prefs.gui.sidebar.tiles[key]
	elseif type(key) == "string" then
		for _, v in pairs(self.prefs.gui.sidebar.tiles) do
			if key == v[3] then
				tile = v
			end
		end
	end
	
	if not tile then
		pd.post("Control Tile Error!")
		return false
	end
	
	outval = self[tile[3]]
	
	if (tile[4] == "CMD")
	and self.friendlyview
	then -- Special case for COMMAND tile: in friendly mode, replace the command number with the command name
		for _, v in pairs(self.cmdnames) do
			if v[2] == self[tile[3]] then
				outval = v[1]
				break
			end
		end
	end
	
	pd.send("extrovert-color-out", "list", rgbOutList(tile[5], self.color[tile[1]][tile[2]], self.color[5][1]))
	pd.send(tile[5], "label", {tile[4] .. " " .. string.rep(".", 6 - tile[4]:len()) .. ": " .. tostring(outval)})

end

-- Update every tile in the control bar
function Extrovert:updateControlBar()

	for k, _ in pairs(self.prefs.gui.sidebar.tiles) do
		self:updateControlTile(k)
	end

end

-- Update the savefile hotseat tile GUI
function Extrovert:updateHotseatBar()

	for k, v in ipairs(self.hotseats) do
	
		local outname = "extrovert-hotseat-" .. (k - 1)
	
		if self.activeseat == k then
			pd.send("extrovert-color-out", "list", rgbOutList(outname, self.color[2][1], self.color[5][1]))
		else
			pd.send("extrovert-color-out", "list", rgbOutList(outname, self.color[3][1], self.color[5][1]))
		end
		
		pd.send(outname, "label", {k .. ". " .. v})
		
	end

end

-- Update the entire sidebar panel
function Extrovert:updateSidebarPanel()

	self:updateControlBar()
	
	self:updateHotseatBar()

end

-- Populate the sequencer's entire GUI with the relevant colors and data
function Extrovert:populateGUI()

	pd.send("extrovert-color-out", "list", rgbOutList("extrovert-background", self.color[9][2], self.color[9][2]))
	
	self:updateSeqGrid()
	
	self:updatePagePanel()
	
	self:updateEditorPanel()
	
	self:updateSidebarPanel()
	
end



-- Send an outgoing MIDI command, via the Puredata MIDI apparatus
function Extrovert:noteSend(note)

	

end

-- Parse an outgoing MIDI command, before actually sending it
function Extrovert:noteParse(note)

	local tarnote = self.sustain[note[2]][note[3]]

	if note[1] == 144 then -- Parse ON-commands
		tarnote.dur = math.max(note[5], tarnote.dur) -- Increase the note's global duration value by the incoming duration amount, if applicable
		tarnote.active = true
	elseif note[1] == 128 then -- Parse OFF-commands
		tarnote.dur = 0
		tarnote.active = false
	end
	
	self.sustain[note[2]][note[3]] = tarnote

	self:noteSend(note)
	
end

-- Send all notes within a given tick in a given sequence
function Extrovert:sendTickNotes(s, t)

	if self.seq[s].tick[t][1] ~= nil then
		for tick, note in ipairs(self.seq[s].tick[t]) do
			self:noteParse(note)
		end
	end

end

-- Convert flags in the "incoming" table into a sequence's internal states
function Extrovert:parseIncomingFlags(s)

	local flags = self.seq[s].incoming
	
	-- Go through all potential incoming flags, and apply their initial effects to the sequence's local variables
	-- (Note: strict comparisons, to check for the true boolean flag, rather than undefined values that might return true)
	if flags.off == true then
	
		self.seq[s].active = false
		
	else
	
		local bpoint = ((flags.button - 1) * (#self.seq[s].tick / self.gridx)) + 1 -- Calculate the tick that corresponds to the incoming button-position
		
		self.seq[s].active = true
		
		if flags.resume == true then
			self.seq[s].active = true
		end
	
		if flags.snap == true then
			self.seq[s].pointer = bpoint
		else
			self.seq[s].pointer = bpoint + (self.seq[s].pointer % (#self.seq[s].tick / self.gridx)) -- Transpose the previous pointer position into the incoming button's slice
		end
		
		if flags.reverse == true then
			self.seq[s].reverse = true
		else
			self.seq[s].reverse = false
		end
		
		if flags.loop == true then
			self.seq[s].loop = true
		else
			self.seq[s].loop = false
		end
		
		if flags.stutter == true then
			self.seq[s].stutter = true
		else
			self.seq[s].stutter = false
		end
		
		if flags.slow ~= nil then
			self.seq[s].slow = flags.slow
		else
			self.seq[s].slow = false
		end
	
	end
	
	-- Empty the incoming table
	self.seq[s].incoming = {}

end

-- Iterate through a sequence's incoming flags, increase its tick pointer under certain conditions, and send off all relevant notes
function Extrovert:iterateSequence(s)

	if self.seq[s].incoming ~= nil then -- If the sequence has incoming flags...
	
		if self.seq[s].incoming.gate ~= nil then -- If the GATE command is incoming...
			if (self.tick % self.bigchunk) == 0 then -- On global ticks that correspond to the first tick in the biggest chunk within all loaded sequences...
				self:parseIncomingFlags(s)
			end
		else
			self:parseIncomingFlags(s)
		end
		
	end

	if self.seq[s].active then -- If the sequence is active...
	
		local newpoint = (self.seq[s].pointer % #self.seq[s].tick) + 1
		if self.seq[s].reverse == true then -- If reverse is enabled in this sequence, change the target pointer value accordingly
			newpoint = ((self.seq[s].pointer - 2) % #self.seq[s].tick) + 1
		end
	
		if self.seq[s].slow ~= false then -- If the slow flag is active, only increment the pointer and send tick-notes on the appropriate global ticks
			if (self.tick % self.seq[s].slow) == 0 then
				self.seq[s].pointer = newpoint
				self:sendTickNotes(s, self.seq[s].pointer)
			end
		else -- Else, increment the pointer and send tick-notes on every global tick
			self.seq[s].pointer = newpoint
			self:sendTickNotes(s, self.seq[s].pointer)
		end
	
	end
	
	
	
end

-- Send automatic noteoffs for duration-based notes that have expired
function Extrovert:decayAllSustains()

	for chan, notes in pairs(self.sustain) do
		for note, params in pairs(notes) do
			if params.active then -- If the sustain is active...
			
				self.sustain[chan][note].dur = math.max(0, params.dur - 1) -- Decrease the relevant duration value
			
				if params.dur == 0 then -- If the duration has expired...
					self:noteParse({chan, 128, note, 127, 0}) -- Parse a noteoff for the relevant channel and note
				end
				
			end
		end
	end

end

-- Cycle through all MIDI commands on the active tick within every active sequence
function Extrovert:iterateAllSequences()

	self:decayAllSustains()
	
	-- Send all regular commands within all sequences
	for i = 1, (self.gridy - 2) * self.gridx do
		self:iterateSequence(i)
	end

end



-- Start the Puredata [metro] apparatus
function Extrovert:startTempo()

	if self.clocktype == "master" then
		pd.send("extrovert-clock-out", "float", {250}) -- Send a CLOCK START command
		pd.send("extrovert-clock-out", "float", {248}) -- Send a dummy tick command, as per MIDI CLOCK spec
		pd.send("extrovert-metro-command", "initialize", {}) -- Send the [metro] a start-bang with a 1-ms delay, to give MIDI SLAVE devices a space to prepare for ticks
	elseif self.clocktype == "none" then
		pd.send("extrovert-metro-command", "bang", {}) -- Send the [metro] a normal start-bang
	end
	
end

-- Stop the Puredata [metro] apparatus
function Extrovert:stopTempo()

	if self.clocktype == "master" then
		pd.send("extrovert-clock-out", "float", {252}) -- Send a CLOCK END command
	elseif self.clocktype == "none" then
		pd.send("extrovert-metro-command", "stop", {}) -- Stop the [metro] from sending any more ticks
	end

end

-- Propagate a beats-per-minute value to the Puredata tempo apparatus
function Extrovert:propagateBPM()

	local ms = 60000 / (self.bpm * 24) -- Convert BPM into milliseconds
	
	pd.send("extrovert-metro-speed", "float", {ms})

end

-- Initialize Extrovert's Puredata tempo apparatus
function Extrovert:initializeClock()

	if (self.clocktype == "master") then
		pd.send("extrovert-clock-type", "float", {1})
	elseif (self.clocktype == "slave") then
		pd.send("extrovert-clock-type", "float", {2})
	elseif (self.clocktype == "thru") then
		pd.send("extrovert-clock-type", "float", {3})
	elseif (self.clocktype == "none") then
		pd.send("extrovert-clock-type", "float", {4})
	end
	
end



-- Send a single LED's data to the Monome apparatus (x and y are 0-indexed!)
function Extrovert:sendLED(x, y, s)

	pd.send("extrovert-monome-out-led", "list", {x, y, s})

end

-- Send a row containing only one lit button to the Monome apparatus (incoming values should be 0-indexed!)
-- If xpoint is set to false, then a blank row is sent.
function Extrovert:sendSimpleRow(xpoint, yrow)

	local rowbytes = {0, yrow} -- These bytes mean: "this command is offset by 0 spaces, and affects row number yrow"
	
	-- Generate a series of bytes, each holding the on-off values for an 8-button slice of the relevant row
	for b = 0, self.gridx - 8, 8 do
	
		if (xpoint ~= false)
		and (xpoint - b) < self.gridx
		then -- If the row contains a lit button, and that button is within this byte-slice, insert the corresponding on-value
			table.insert(rowbytes, 2 ^ (xpoint - b))
		else -- Else, insert a byte corresponding to 8 darkened buttons
			table.insert(rowbytes, 0)
		end
	
	end
	
	pd.send("extrovert-monome-out-row", "list", rowbytes) -- Send the row-out command to the Puredata Monome-row apparatus

end

-- Send the page-command row a new set of button data
function Extrovert:sendPageRow()

	self:sendSimpleRow(self.page - 1, self.gridy - 2)
	
end

-- Send the Monome button-data for a single visible sequence-row
function Extrovert:sendSeqRow(s)

	local yrow = (s - 1) % (self.gridy - 2)
	
	if self.seq[s].active then -- Send a row wherein the sequence's active subsection-button is brightened
	
		local subpoint = math.ceil(self.seq[s].pointer / (#self.seq[s].tick / self.gridx)) - 1
		self:sendSimpleRow(subpoint, yrow)
		
	else -- Send a darkened sequence-row
		self:sendSimpleRow(false, yrow)
	end

end

-- Send the Monome button-data for all visible sequence-rows
function Extrovert:sendVisibleSeqRows()

	for i = ((self.gridy - 2) * (self.page - 1)) + 1, (self.gridy - 2) * self.page do
		self:sendSeqRow(i)
	end

end

-- Initialize the parameters of the Puredata Monome apparatus
function Extrovert:initializeMonome()

	pd.send("extrovert-osc-type", "float", {self.prefs.monome.osctype})
	pd.send("extrovert-osc-out-port", "float", {self.prefs.monome.oscsend})
	pd.send("extrovert-osc-in-port", "float", {self.prefs.monome.osclisten})
	
	pd.post("Initialized Monome settings")
	
end



-- Parse an incoming sequence-row command from the Monome
function Extrovert:parseSeqButton(x, y, s)

	if s == 1 then
	
		local cmdflag = false
		local target = ((self.page - 1) * (self.gridy - 2)) + y -- Convert y row, and page value, into a sequence-key
		
		-- Apply all active control-tags to the target sequence's "incoming" table
		for _, v in pairs(self.flagnames) do
			if self.ctrlflags[v[1]] ~= false then
				table.insert(self.seq[target].incoming, v[1])
			end
		end
		
		self.seq[target].incoming.active = true -- Flag that shows the sequence was just activated, and that it should therefore be treated slightly differently on its first tick
		self.seq[target].incoming.button = x -- Set the incoming button-value
		
	end

end

-- Parse an incoming page-row command from the Monome
function Extrovert:parsePageButton(x, s)

	if s == 1 then

		local cmdflag = false -- Gets toggled to true if any command buttons are being pressed
		
		-- Check all listed control-row flags
		for _, v in pairs(self.flagnames) do
			if self.ctrlflags[v[1]] ~= false then
				cmdflag = true
				-- Insert the active flags' corresponding commands into every sequence on the relevant page
				for i = ((self.gridy - 2) * (x - 1)) + 1, (self.gridy - 2) * x do
					table.insert(self.seq[i].incoming, v[1])
				end
			end
		end

		if (not cmdflag) -- If this is not being chorded with any command-buttons...
		and (x ~= self.page) -- And the page-button being pressed is not for the active page...
		then
		
			self.page = x -- Tab to the selected page
			
			self:sendPageRow()
			self:sendVisibleSeqRows()
			
		end
		
	end

end

-- Parse an incoming control-row command from the Monome
function Extrovert:parseCommandButton(x, s)

	local light = 1 -- Stays set to 1 if the button is to be lit; else will be set to 0
	local sendx = math.min(x, #self.flagnames) -- Reduce x, so that all slow-buttons are collapsed into the slow-flag
	
	if s == 1 then

		if sendx == #self.flagnames then -- Special action for slowbuttons:
			self.slowbutton = (x - sendx) + 2 -- Set the slow value to 2 or more, depending on which slow button is pressed
		else
			self.ctrlflags[self.flagnames[sendx]] = true -- Set the corresponding normal button var to true
		end
	
	else
		self.ctrlflags[self.flagnames[sendx]] = false -- Set the corresponding button var to false
		light = 0 -- The button will be darkened
	end
	
	self:sendLED(x - 1, self.gridy - 1, light) -- Light up or darken the corresponding Monome button

end



-- Save current table-data as a folder of MIDI files, via the MIDI.lua apparatus
function Extrovert:saveData()

	for i = 1, (self.gridy - 2) * self.gridx do
	
		local opus = {
			24, -- Ticks per beat (e.g. quarter note)
			{"set_tempo", 0, 60000000 / self.bpm}, -- Microseconds per beat
		}
		
		for tick, notes in ipairs(self.seq[i].tick) do
		
			for num, v in ipairs(notes) do
			
				-- Convert Extrovert tabes into their MIDIlua counterparts
				if v[1] == 144 then
					table.insert(opus, {"note", tick, v[5], v[2], v[3], v[4]})
				elseif v[1] == 160 then
					table.insert(opus, {"pitch_wheel_change", tick, v[2], v[3]})
				elseif v[1] == 176 then
					table.insert(opus, {"control_change", tick, v[2], v[3], v[4]})
				elseif v[1] == 192 then
					table.insert(opus, {"patch_change", tick, v[2], v[3]})
				elseif v[1] == 208 then
					table.insert(opus, {"key_after_touch", tick, v[2], v[3], v[4]})
				elseif v[1] == 224 then
					table.insert(opus, {"pitch_wheel_change", tick, v[2], v[3]})
				end
				
			end
			
		end
	
		-- Save the table into a MIDI file within the savefolder, using MIDI.lua functions
		local midifile = assert(io.open(self.savepath .. self.hotseats[self.activeseat] .. "/" .. i .. ".mid", 'w'))
		midifile:write(MIDI.score2midi(opus))
		midifile:close()
	
		pd.post("Saved sequence " .. i .. "!")
	
	end
	
	pd.post("Saved sequences to savefolder /" .. self.hotseats[self.activeseat] .. "/!")

end

-- Load a MIDI savefile folder, via the MIDI.lua apparatus
function Extrovert:loadData()

	self:stopTempo() -- Stop the tempo system, if applicable

	-- Translate all MIDI files in the savefolder into their corresponding MIDIlua-shaped tables, and then translate those tables into Extrovert Tables
	for i = 1, (self.gridy - 2) * self.gridx do
	
		local tab = {}
	
		-- Load the table from a MIDI file within the savefolder, using MIDI.lua functions
		local midifile = assert(io.open(self.savepath .. self.hotseats[self.activeseat] .. "/" .. i .. ".mid", 'r'))
		midifile:read(MIDI.midi2score(tab))
		midifile:close()
		
		local outtab = { {} }
		local stats = MIDI.score2stats(tab)
		local tpq = table.remove(tab, 1)
		if tpq ~= 24 then
			tpq = 24
			pd.post("Ticks Per Beat was not 24! Reformatted it to 24. This will affect playback speed.")
		end
		
		-- Insert items into the output table until it matches the number of ticks in the MIDIlua score table
		while #outtab < stats.nticks do
			table.insert(outtab, {})
		end
		
		for k, v in ipairs(tab) do
		
			-- Convert various values into their Extrovert counterparts
			if v[1] == "note" then
				table.insert(outtab[v[2]], {144, v[4], v[5], v[6], v[3]})
			elseif v[1] == "key_after_touch" then
				table.insert(outtab[v[2]], {208, v[3], v[4], v[5], 0})
			elseif v[1] == "control_change" then
				table.insert(outtab[v[2]], {176, v[3], v[4], v[5], 0})
			elseif v[1] == "patch_change" then
				table.insert(outtab[v[2]], {192, v[3], v[4], 0, 0})
			elseif v[1] == "channel_after_touch" then
				table.insert(outtab[v[2]], {160, v[3], v[4], 0, 0})
			elseif v[1] == "pitch_wheel_change" then
				table.insert(outtab[v[2]], {224, v[3], v[4], 0, 0})
			elseif v[1] == "set_tempo" then
				self.bpm = 60000000 / v[3]
			else
				pd.post("Discarded unsupported command: " .. v[1])
			end
			
		end
		
		-- Insert padding ticks at the end of the sequence, so that it fits the Monome without incurring button-based rounding errors
		while (#outtab % self.gridx) ~= 0 do
			table.insert(outtab, {})
		end
		
		self.seq[i].tick = outtab
		
		pd.post("Loaded sequence " .. i .. "!")
		
	end
	
	self:normalizePointers()
	
	self:propagateBPM()
	
	pd.post("Loaded savefolder /" .. self.hotseats[self.activeseat] .. "/!")

	self:makeCleanHistory() -- Reset undo history
	
	self:updateEditorPanel()
	
	self:startTempo() -- Start the tempo system again, if applicable

end

-- Toggle to a saveload filename within the hotseats list
function Extrovert:toggleToHotseat(seat)

	self.activeseat = seat
	
	pd.post("Saveload hotseat: " .. self.activeseat .. ": " .. self.hotseats[self.activeseat])
	
	self:updateHotseatBar()

end



-- Move the positions of all pointers to valid indexes
function Extrovert:normalizePointers()

	-- Normalize tick pointer
	if self.pointer > #self.seq[self.key].tick then
		self.pointer = math.max(1, (#self.seq[self.key].tick - self.quant) + 1) -- math.max compensates for cases where the quantization is larger than the sequence
	end
	
	-- Normalize note pointer
	if (self.seq[self.key].tick[self.pointer][1] == nil)
	or (self.notepointer > #self.seq[self.key].tick[self.pointer])
	then
		self.notepointer = 1
	end
	
	if self.copy.bot then
	
		-- Normalize bottom copypaste pointer
		if self.copy.bot > #self.seq[self.key].tick then
			self.copy.bot = #self.seq[self.key].tick
		end
		
		-- Normalize bottom copypaste notepointer
		if self.seq[self.key].tick[self.copy.bot][self.copy.notebot] == nil then
			self.copy.notebot = #self.seq[self.key].tick[self.copy.bot] or 1
		end
		
	end
	
	if self.copy.top then
	
		-- Normalize top copypaste pointer
		if self.copy.top > #self.seq[self.key].tick then
			self.copy.top = self.copy.bot or 1
		end
		
		-- Normalize top copypaste notepointer
		if self.seq[self.key].tick[self.copy.top][self.copy.notetop] == nil then
			self.copy.notetop = 1
		end
		
	end

end

-- Replace current data with data from a historical state
function Extrovert:reviveHistoryData()

	-- Ensure that tables are copied, rather than references
	local v = deepCopy(self.history[self.undopoint], {})
	
	if v[2] then
		if v[3] then
			if v[4] then
				self.seq[v[2]].tick[v[3]][v[4]] = v[1]
			else
				self.seq[v[2]].tick[v[3]] = v[1]
			end
		else
			self.seq[v[2]].tick = v[1]
		end
	else
		for k, s in pairs(v[1]) do
			self.seq[k].tick = s
		end
	end
	
end

-- Revert internal variables to the previous state in the self.history table, if any older states exist
function Extrovert:undo()

	if self.undopoint > 1 then
	
		self.undopoint = self.undopoint - 1
		self:reviveHistoryData()
	
		pd.post("Undo depth: " .. self.undopoint .. "/" .. #self.history .. " (" .. self.undodepth .. " max)")
		
		self:normalizePointers()
		
		self:updateEditorPanel()
	
	else
	
		pd.post("Cannot undo! Bottom of history table has been reached!")
	
	end

end

-- Change internal variables to the next state in the self.history table, if applicable
function Extrovert:redo()

	if self.undopoint < #self.history then
	
		self.undopoint = self.undopoint + 1
		self:reviveHistoryData()
		
		pd.post("Undo depth: " .. self.undopoint .. "/" .. #self.history .. " (" .. self.undodepth .. " max)")
		
		self:normalizePointers()
		
		self:updateEditorPanel()
	
	else
	
		pd.post("Cannot redo! Top of history table has been reached!")
	
	end

end

-- Insert a set of recently-changed variables into a new entry in the history table
function Extrovert:addStateToHistory(item, key, tick, note)

	-- If self.undopoint is less than the number of items in self.history, remove all items ahead of the self.undopoint index
	if self.undopoint < #self.history then
		for i = #self.history, self.undopoint + 1, -1 do
			table.remove(self.history, i)
		end
	end

	-- If the history table has reached the maximum undo depth, then remove the oldest item
	if #self.history == self.undodepth then
		table.remove(self.history, 1)
	end
	
	-- Copy over all given variables to the history table's most recent index
	self.history[#self.history + 1] = deepCopy({item, key or false, tick or false, note or false}, {})
	
	self.undopoint = #self.history -- Set self.undopoint to the most recent index
	
end

-- Add multiple sequences to a single history slot
function Extrovert:addSeqsToHistory(keys)

	local undoseqs = {}
	for _, v in pairs(keys) do
		undoseqs[v] = self.seq[v].tick
	end
	
	self:addStateToHistory(undoseqs)
	
end

-- Clear the history table, and insert initial dummy values
function Extrovert:makeCleanHistory()

	self.history = {}
	self.history[1] = deepCopy({self.seq[self.key].tick[self.pointer], self.key, self.pointer, false}, {})
	self.undopoint = 1
	
end



-- Set the upper copy pointers to the current tick and note pointer values
function Extrovert:setUpperCopyPoint()

	self.copy.top = self.pointer
	self.copy.notetop = self.notepointer
	
	-- Set the bottom copy-range variables equal to the top copy-range variables, if they are unset
	if self.copy.bot == false then
		self.copy.bot = self.copy.top
		self.copy.notebot = self.notepointer
	end
	
	-- Normalize the bottom-copy-pointer, if it is above the new top-copy-pointer value
	if self.copy.top > self.copy.bot then
		self.copy.bot = self.copy.top
	end
	
	-- If the top-copy-pointer and bottom-copy-pointer are upon the same tick, and the bottom-copy-notepointer is above the top-copy-notepointer, normalize the bottom-copy-notepointer
	if self.copy.top == self.copy.bot then
		if self.copy.notetop > self.copy.notebot then
			self.copy.notebot = self.copy.notetop
		end
	end
	
	pd.post("Copy range: " .. self.copy.top .. "(" .. self.copy.notetop .. ") - " .. self.copy.bot .. "(" .. self.copy.notebot .. ")")
	
	self:updateMainEditorColumn()

end

-- Set the lower copy pointers to the current tick and note pointer values
function Extrovert:setLowerCopyPoint()

	self.copy.bot = self.pointer
	self.copy.notebot = self.notepointer
	
	-- Set the top copy-range variables equal to the bottom copy-range variables, if they are unset
	if self.copy.top == false then
		self.copy.top = self.copy.bot
		self.copy.notetop = self.notepointer
	end
	
	-- Normalize the top-copy-pointer, if it is below the new bottom-copy-pointer value
	if self.copy.bot < self.copy.top then
		self.copy.top = self.copy.bot
	end
	
	-- If the bottom-copy-pointer and top-copy-pointer are upon the same tick, and the top-copy-notepointer is below the bottom-copy-notepointer, normalize the top-copy-notepointer
	if self.copy.top == self.copy.bot then
		if self.copy.notebot < self.copy.notetop then
			self.copy.notetop = self.copy.notebot
		end
	end
	
	pd.post("Copy range: " .. self.copy.top .. "(" .. self.copy.notetop .. ") - " .. self.copy.bot .. "(" .. self.copy.notebot .. ")")
	
	self:updateMainEditorColumn()

end

-- Unset all copy-pointers and copy-notepointers
function Extrovert:unsetCopyPoints()

	self.copy.top, self.copy.bot = false, false
	self.copy.notetop, self.copy.notebot = 1, 1
	
	pd.post("Copy points unset.")

	self:updateMainEditorColumn()

end

-- Move every note within the selection range into the self.copy.tab table
function Extrovert:cutSequence()

	self.copytab = {} -- Clear old copy data, if there was any
	
	local temptab = {}
	
	local i = 1
	for t = self.copy.top, self.copy.bot do -- Iterate from upper copy tick to lower copy tick
	
		temptab[i] = {}
		
		local deletions = 0
		
		while (self.seq[self.key].tick[t][self.copy.notetop] ~= nil) -- While the active notepointer isn't nil...
		and (
			(t ~= self.copy.bot) -- And "t" hasn't reached the tick-range's bottom...
			or (deletions < self.copy.notebot) -- OR the number of deletions hasn't exceeded the note-range's bottom...
		)
		do -- Insert the note into the temporary copytable, based on the position of notetop (because notetop may start out at a non-1 value on the initial tick)
			table.insert(temptab[i], table.remove(self.seq[self.key].tick[t], self.copy.notetop))
			deletions = deletions + 1
		end
		
		self.copy.notetop = 1
		i = i + 1
		
	end
	
	-- If the active sequence is left with too few ticks, fill it with empty ones
	if (#self.seq[self.key].tick == nil)
	or (#self.seq[self.key].tick < self.gridx)
	then
		for i = #self.seq[self.key].tick or 1, self.gridx do
			self.seq[self.key].tick[i] = {}
		end
	end
	
	self.copytab = deepCopy(temptab, {}) -- Copy the tables, rather than references, to prevent horrible reference stickiness
	
	self:unsetCopyPoints()
	
	self:normalizePointers()
	
	pd.post("Sequence " .. self.key .. ":")
	pd.post("Cut " .. #self.copytab .. " ticks.")
	
	self:addStateToHistory(self.seq[self.key].tick, self.key)
	
	self:updateControlTile("pointer")
	self:updateMainEditorColumn()

end

-- Copy every note within the selection range into the self.copy.tab table
function Extrovert:copySequence()

	self.copytab = {} -- Clear old copy data, if there was any
	
	local temptab = {}
	
	local i = 1
	for t = self.copy.top, self.copy.bot do -- Iterate from upper copy tick to lower copy tick
	
		temptab[i] = {}
		
		while (self.seq[self.key].tick[t][self.copy.notetop] ~= nil) -- While the active notepointer isn't nil...
		and (
			(t ~= self.copy.bot) -- And "t" hasn't reached the tick-range's bottom...
			or (self.notetop <= self.copy.notebot) -- OR the notetop point hasn't exceeded the note-range's bottom...
		)
		do -- Insert the note into the temporary copytable, based on the position of notetop (because notetop may start out at a non-1 value on the initial tick)
			table.insert(temptab[i], self.seq[self.key].tick[t][self.copy.notetop])
			self.notetop = self.notetop + 1
		end
		
		self.copy.notetop = 1
		i = i + 1
		
	end
	
	self.copytab = deepCopy(temptab, {}) -- Copy the tables, rather than references, to prevent horrible reference stickiness
	
	pd.post("Sequence " .. self.key .. ":")
	pd.post("Copied " .. #self.copytab .. " ticks.")
	
end

-- Paste every note in self.copy.tab to the current pointer location
function Extrovert:pasteSequence()

	for k, v in ipairs(self.copytab) do
		table.insert(self.seq[self.key].tick, (self.pointer + k) - 1, deepCopy(v, {}))
	end
	
	self.notepointer = 1
	
	pd.post("Sequence " .. self.key .. ":")
	pd.post("Pasted " .. #self.copytab .. " ticks.")
	pd.post("Ticks in sequence: " .. #self.seq[self.key].tick)
	
	self:updateMainEditorColumn()
	
end



-- Add a number of ticks to the active sequence equal to the current spacing*quantization values
function Extrovert:addSpaceToSequence()

	for i = 1, self.gridx * self.quant * math.min(1, self.spacing) do
		table.insert(self.seq[self.key].tick, self.pointer, {})
	end
	
	self:normalizePointers()
	
	pd.post("Tick " .. self.pointer)
	pd.post("Inserted " .. (self.gridx * self.quant * math.min(1, self.spacing)) .. " empty ticks")
	
	self:addStateToHistory(self.seq[self.key].tick, self.key)
	
	self:updateMainEditorColumn()

end

-- Remove a number of ticks from the active sequence equal to the current spacing*quantization values, provided the result isn't smaller than the Monome's width
function Extrovert:deleteSpaceFromSequence()

	if (#self.seq[self.key].tick - (self.gridx * self.quant * math.min(1, self.spacing))) >= self.gridx then
	
		-- Compensate for cases where the pointer is far along enough in the sequence that ticks from the sequence's start will be removed as well
		if self.pointer > (#self.seq[self.key].tick - (self.gridx * self.quant * math.min(1, self.spacing))) then
		
			for i = 1, self.pointer - (#self.seq[self.key].tick - (self.gridx * self.quant * math.min(1, self.spacing))) do
				table.insert(self.seq[self.key].tick, #self.seq[self.key].tick, table.remove(self.seq[self.key].tick, 1))
				self.pointer = self.pointer - 1
			end
			
		end
		
		-- Remove the ticks from the active sequence
		for i = 1, self.gridx * self.quant * math.min(1, self.spacing) do
			table.remove(self.seq[self.key].tick, self.pointer)
		end
		
		self:normalizePointers()
		
		pd.post("Tick " .. self.pointer)
		pd.post("Removed " .. (self.gridx * self.quant * math.min(1, self.spacing)) .. " ticks")
		
		self:addStateToHistory(self.seq[self.key].tick, self.key)

		self:updateControlTile("pointer")
		self:updateMainEditorColumn()

	else
	
		pd.post("Sequence must always contain at least " .. self.gridx .. " ticks!")
		pd.post("Could not delete " .. (self.gridx * self.quant * math.min(1, self.spacing)) .. " ticks from the sequence.")
	
	end
	
end

-- Delete the note at the current notepointer, in the current tick, within the current sequence, if applicable
function Extrovert:deleteCurrentNote()

	if self.seq[self.key].tick[self.pointer][self.notepointer] ~= nil then
	
		local reportnote = table.remove(self.seq[self.key].tick[self.pointer], self.notepointer)
		local oldpoint = self.notepointer
		
		if (self.seq[self.key].tick[self.pointer][self.notepointer] == nil)
		and (self.notepointer > 1)
		then
			self.notepointer = self.notepointer - 1
		end
	
		self:normalizePointers()
	
		pd.post("Tick " .. self.pointer .. " - Point " .. oldpoint)
		pd.post("Removed note: " .. table.concat(reportnote, " "))
		
		self:addStateToHistory(self.seq[self.key].tick, self.key)

		self:updateMainEditorColumn()
		
	else
	
		pd.post("Tick " .. self.pointer .. " - Point " .. self.notepointer)
		pd.post("No notes to delete!")
		
	end

end

-- Toggle between "friendly" and "hacker" depictions of MIDI data values
function Extrovert:toggleFriendlyMode()

	self.friendlyview = not self.friendlyview
	
	pd.post("Friendly Note View toggle: " .. tostring(self.friendlyview))
	
	self:updateEditorPanel()

end

-- Move the editor's pointer to a given point in the active sequence
function Extrovert:moveToPoint(p)

	if self.seq[self.key].tick[p] ~= nil then
		self.pointer = p
	end
	
	if (self.seq[self.key].tick[self.pointer][1] == nil)
	or (not rangeCheck(self.notepointer, 1, #self.seq[self.key].tick[self.pointer]))
	then
		self.notepointer = 1
	end

	pd.post("Tick " .. self.pointer .. " - Point " .. self.notepointer)
	
	self:updateControlTile("pointer")
	self:updateMainEditorColumn()
	
end

-- Move the editor's pointer to the inverse tick of the active sequence, bounded by the current quantization value
function Extrovert:moveToInversePoint()

	local ticks = #self.seq[self.key].tick
	local inv = math.floor(ticks / 2)
	local qt = math.floor(inv / self.quant)
	local offset = qt * self.quant
	
	self.pointer = (((self.pointer + offset) - 1) % #self.seq[self.key].tick) + 1
	self.notepointer = 1

	pd.post("Tick " .. self.pointer .. " - Point " .. self.notepointer)
	
	self:updateControlTile("pointer")
	self:updateMainEditorColumn()
	
end

-- Move the editor's notepointer and tickpointer to a different note or tick in the active sequence, based on a relative direction from the current note
function Extrovert:moveToRelativePoint(spaces)

	local direction = math.min(1, math.max(-1, spaces))
	
	for i = self.notepointer, self.notepointer + (spaces - direction), direction do
	
		self.notepointer = self.notepointer + direction
		
		if (self.seq[self.key].tick[self.pointer][1] == nil)
		or (not rangeCheck(self.notepointer, 1, #self.seq[self.key].tick[self.pointer]))
		then
		
			self.pointer = (((self.pointer + (self.quant * direction)) - 1) % #self.seq[self.key].tick) + 1
			
			if self.notepointer == 0 then
				self.notepointer = #self.seq[self.key].tick[self.pointer]
			else
				self.notepointer = 1
			end
			
		end
		
		if self.notepointer == 0 then
			self.notepointer = 1
		end
		
	end
	
	pd.post("Tick " .. self.pointer .. " - Point " .. self.notepointer)
	
	self:updateControlTile("pointer")
	self:updateMainEditorColumn()
	
end

-- Move to an adjacent page of the active sequence
function Extrovert:moveByPage(dir)

	dir = math.max(-1, math.min(1, dir))

	local visibleskip = 2
	if self.quant == 1 then
		visibleskip = 1
	end

	local contents = (math.floor(self.prefs.gui.editor.rows / 2) * self.quant) / visibleskip
	local dist = 0
	
	for i = self.pointer, self.pointer + (contents * dir), self.quant * dir do
	
		dist = dist + 1
		
		local adjpoint = ((i - 1) % #self.seq[self.key].tick) + 1
		
		if (self.seq[self.key].tick[adjpoint][1] ~= nil) -- If there are notes in the tick...
		and (#self.seq[self.key].tick[adjpoint] > 1) -- And the number of notes is greater than 1...
		then
			dist = dist - (#self.seq[self.key].tick[adjpoint] - 1) -- Decrease tick-dist-tracking by the number of extra ticks
		end
		
	end

	self.pointer = (((self.pointer - 1) + ((dist * self.quant) * dir)) % #self.seq[self.key].tick) + 1
	
	self:normalizePointers()
	
	pd.post("Tick " .. self.pointer .. " - Point " .. self.notepointer)
	
	self:updateControlTile("pointer")
	self:updateMainEditorColumn()
	
end

-- Move the editor's sequence-pointer to a different sequence, based on relative direction from the current sequence
function Extrovert:moveToRelativeKey(spaces)

	self.key = (((self.key - 1) + spaces) % #self.seq) + 1
	
	self:normalizePointers()
	
	pd.post("Sequence " .. self.key)
	pd.post("Tick " .. self.pointer .. " - Point " .. self.notepointer)
	
	self:updateControlTile("pointer")
	self:updateControlTile("key")
	self:updatePagePanel()
	self:updateEditorPanel()
	
end

-- Move the key across, to its equivalent sequence on a different page
function Extrovert:moveKeyAcross(spaces)

	self:moveToRelativeKey(((((self.gridy - 2) * spaces) - 1) % #self.seq) + 1)
	
end

-- Shift the active sequence to an adjacent slot, switching it with the sequence in its destination
function Extrovert:moveSequence(spaces)

	local dest = (((self.key - 1) + spaces) % #self.seq) + 1
	local oldkey = self.key
	
	local s1 = deepCopy(self.seq[self.key], {})
	local s2 = deepCopy(self.seq[dest], {})
	
	self.seq[self.key] = s2
	self.seq[dest] = s1
	
	self.key = dest
	
	pd.post("Switched sequences " .. oldkey .. " and " .. dest)
	pd.post("Active sequence: " .. self.key)
	
	self:addSeqsToHistory({oldkey, dest})

	self:updateControlTile("key")
	self:updatePagePanel()
	self:updateEditorPanel()
	
end

-- Shift the active sequence to the same slot in a different page, switching it with the sequence in its destination
function Extrovert:moveSequenceAcross(spaces)

	self:moveSequence(((((self.gridy - 2) * spaces) - 1) % #self.seq) + 1)

end

-- Shift self.spacing by a given amount
function Extrovert:shiftSpacing(dist)

	self.spacing = math.max(0, self.spacing + (self.quant * dist))
	
	pd.post("Spacing: " .. self.spacing)
	
	self:updateControlTile("spacing")

end

-- Shift self.quant by a given amount
function Extrovert:shiftQuant(dist)

	if dist < 0 then
		dist = 1 / (math.abs(dist) + 1)
	else
		dist = dist + 1
	end

	if (self.quant * dist) >= 3 then
		self.quant = self.quant * dist
	elseif (self.quant * dist) == 1.5 then
		self.quant = 1
	elseif (self.quant * dist) >= 2 then
		self.quant = 3
		self.quant = self.quant * (dist - 1)
	end
	
	pd.post("Quantization: " .. self.quant .. " (" .. math.max(1, self.quant / 96) .. "/" .. math.max(1, 96 / self.quant) .. " note)")
	
	self:updateControlTile("quant")
	self:updateEditorPanel()

end

-- Shift self.duration by a given amount
function Extrovert:shiftDuration(dist)

	self.duration = math.max(1, self.duration + (self.quant * dist))

	pd.post("Duration: " .. self.duration)
	
	self:updateControlTile("duration")

end

-- Shift self.command by a given amount
function Extrovert:shiftCommand(dist)

	for k, v in pairs(self.cmdnames) do
		if v[2] == self.command then
			self.command = self.cmdnames[(((k + dist) - 1) % #self.cmdnames) + 1][2]
			break
		end
	end
	
	pd.post("Command: " .. self.command)
	
	self:updateControlTile("command")

end

-- Shift self.channel by a given amount
function Extrovert:shiftChannel(dist)

	self.channel = (self.channel + dist) % 16
	
	pd.post("Channel: " .. self.channel)
	
	self:updateControlTile("channel")

end

-- Shift self.velocity by a given amount
function Extrovert:shiftVelocity(dist)

	self.velocity = (self.velocity + dist) % 128
	
	pd.post("Velocity: " .. self.velocity)
	
	self:updateControlTile("velocity")

end

-- Shift self.octave by a given amount
function Extrovert:shiftOctave(dist)

	self.octave = (self.octave + dist) % 12
	
	pd.post("Octave: " .. self.octave)
	
	self:updateControlTile("octave")

end

-- Change the value of a given byte, in the active note, at the active pointer
function Extrovert:moveByte(bname, bytepoint, dist, index, limit, point, notepoint)

	bname = bname or "Byte"
	point = point or self.pointer
	notepoint = notepoint or self.notepointer

	local notes = self.seq[self.key].tick[point]
	if notes[notepoint] ~= nil then
	
		local byte = notes[notepoint][bytepoint]
		byte = (((byte - index) + dist) % limit) + index
		
		self.seq[self.key].tick[point][notepoint][bytepoint] = byte
	
		pd.post(bname .. " shifted to: " .. pitch)
		
	end
	
end

-- Change the values of all given bytes of a certain type, within the active sequence
function Extrovert:moveAllBytes(bname, bytepoint, dist, index, limit)

	for k, v in pairs(self.seq[self.key].tick) do
	
		if v[1] ~= nil then
		
			for kk, vv in pairs(v) do
				moveByte(bname, bytepoint, dist, index, limit, k, kk)
			end
		
		end
	
	end

	pd.post("Sequence " .. self.key)
	pd.post("Shifted all " .. bname .. " values by " .. dist)

	self:addStateToHistory(self.seq[self.key].tick[self.pointer], self.key)

	self:updateMainEditorColumn()

end

-- Change the channel-value within the active notepointer
function Extrovert:moveChannel(dist)

	self:moveByte("Channel", 1, dist, 0, 16, self.pointer, self.notepointer)

	self:addStateToHistory(self.seq[self.key].tick[self.pointer], self.key, self.pointer, self.notepointer)

	self:updateMainEditorColumn()

end

-- Change the pitch-value within the active notepointer
function Extrovert:movePitch(dist)

	self:moveByte("Pitch", 3, dist * self.velocity, 0, 128, self.pointer, self.notepointer)

	self:addStateToHistory(self.seq[self.key].tick[self.pointer], self.key, self.pointer, self.notepointer)

	self:updateMainEditorColumn()

end

-- Chage the velocity value within the active notepointer
function Extrovert:moveVelocity(dist)

	self:moveByte("Velocity", 4, dist * self.velocity, 0, 128, self.pointer, self.notepointer)
	
	self:addStateToHistory(self.seq[self.key].tick[self.pointer], self.key, self.pointer, self.notepointer)

	self:updateMainEditorColumn()

end

-- Change the duration value within the active notepointer
function Extrovert:moveDuration(dist)

	self:moveByte("Duration", 5, dist * self.quant, 1, #self.seq[self.key].tick, self.pointer, self.notepointer)
	
	self:addStateToHistory(self.seq[self.key].tick[self.pointer], self.key, self.pointer, self.notepointer)

	self:updateMainEditorColumn()

end

-- Change all channel-values within the active sequence
function Extrovert:moveAllChannels(dist)

	self:moveAllBytes("Channel", 1, dist, 0, 16)

end

-- Change all pitch-values within the active sequence
function Extrovert:moveAllPitches(dist)

	self:moveAllBytes("Pitch", 3, dist * self.velocity, 0, 128)

end

-- Change all velocity values within the active sequence
function Extrovert:moveAllVelocities(dist)

	self:moveAllBytes("Velocity", 4, dist * self.velocity, 0, 128)

end

-- Change all duration values within the active sequence
function Extrovert:moveAllDurations(dist)

	self:moveAllBytes("Duration", 5, dist * self.quant, 1, #self.seq[self.key].tick)

end

-- Shift the position of a note to an adjacent pointer
function Extrovert:moveNote(spaces)

	local direction = math.min(1, math.max(-1, spaces))
	
	for i = self.pointer, self.pointer + (spaces - direction), direction do
	
		local rem = ((i - 1) % #self.seq[self.key].tick) + 1
		local ins = (((rem + direction) - 1) % #self.seq[self.key].tick) + 1
		
		table.insert(self.seq[self.key].tick, ins, table.remove(self.seq[self.key].tick, rem))
	
	end

	pd.post("Sequence " .. self.key)
	pd.post("Moved note by " .. spaces .. " ticks")

	self:addStateToHistory(self.seq[self.key].tick[self.pointer], self.key)

	self:updateControlTile("pointer")
	self:updateMainEditorColumn()

end

-- Shift the positions of all notes to adjacent pointers
function Extrovert:moveAllNotes(spaces)

	local direction = math.min(1, math.max(-1, spaces))
	local rem = 1
	local ins = #self.seq[self.key].tick
	if direction == -1 then
		rem, ins = ins, rem
	end

	for i = direction, spaces, direction do
		table.insert(self.seq[self.key].tick, ins, table.remove(self.seq[self.key].tick, rem))
	end
	
	pd.post("Sequence " .. self.key)
	pd.post("Moved all notes by " .. spaces .. " ticks")

	self:addStateToHistory(self.seq[self.key].tick[self.pointer], self.key)

	self:updateControlTile("pointer")
	self:updateMainEditorColumn()

end

-- Toggle whether or not keyboard-piano notes are recorded
function Extrovert:togglePianoRecording()

	self.acceptpiano = not self.acceptpiano
	
	pd.post("Keyboard-piano recording: " .. tostring(self.acceptpiano))
	
	self:updateControlTile("acceptpiano")
	
end

-- Send a note from the computer-keyboard-piano to the relevant sequence
function Extrovert:parsePianoNote(note)

	note = note + (self.octave * 12)
	while note > 127 do -- Cull back out-of-bounds note values to a valid octave
		note = note - 12
	end
	
	-- Send an example note, regardless of whether notes are being recorded
	pd.send("extrovert-examplenote", "list", {note, self.velocity, self.channel})
	
	if self.acceptpiano == true then -- Only record a piano-key command if piano-key recording is enabled
	
		if self.command == -20 then -- On Global BPM command: translate the note+velocity into the global BPM value
			self.bpm = note + self.velocity
		elseif self.command == -10 then -- On Local BPM command: translate the note+velocity into a local BPM value
			table.insert(self.seq[self.key].tick[self.pointer], self.notepointer, {self.channel, self.command, note + self.velocity, 0, 0})
		else -- Insert the note into the active tick of the active sequence
			table.insert(self.seq[self.key].tick[self.pointer], self.notepointer, {self.channel, self.command, note, self.velocity, self.duration})
		end
		
		-- Move the pointer forward by the current spacing value
		self.pointer = (((self.pointer - 1) + self.spacing) % #self.seq[self.key].tick) + 1

		self:normalizePointers()
		
		pd.post("Sequence " .. self.key .. ", Tick " .. self.pointer .. ", Point " .. self.notepointer)
		pd.post("Inserted note " .. note)
		
		self:addStateToHistory(self.seq[self.key].tick[self.pointer], self.key, self.pointer)

		self:updateMainEditorColumn()
		
	end
	
end

-- Analyze an incoming command name, and invoke its corresponding function and arguments
function Extrovert:parseEditorCommand(cmd)

	-- Check the incoming command name against the command-to-function hash table
	for k, v in pairs(self.cmdfuncs) do
	
		if cmd == k then -- If the command name matches a command-to-function hash entry, invoke the function and its args dynamically
			
			local passargs = {}
			for i = 2, #v do
				table.insert(passargs, v[i])
			end
			
			self[v[1]](self, unpack(passargs)) -- Call the dynamic function name with its entry's corresponding args
			
			break
		
		end
	
	end

end

-- Assign computer-piano-keyboard commands to the keycommand and function-hash tables
function Extrovert:assignPianoKeysToCmds()

	for k, v in ipairs(self.keynames) do
		if type(v) == "table" then
			for kk, vv in pairs(v) do
				self.commands["PIANO_KEY_" .. vv .. "_" .. kk] = {vv}
				self.cmdfuncs["PIANO_KEY_" .. vv .. "_" .. kk] = {"parsePianoNote", k - 1}
			end
		else
			self.commands["PIANO_KEY_" .. v] = {v}
			self.cmdfuncs["PIANO_KEY_" .. v] = {"parsePianoNote", k - 1}
		end
	end
	
end

-- Assign hotseat commands to the keycommand and function-hash tables
function Extrovert:assignHotseatsToCmds()
	
	for k, _ in pairs(self.hotseats) do
	
		if self.hotseatcmds[k] ~= nil then
	
			local cmdname = "HOTSEAT_" .. k
			self.commands[cmdname] = self.hotseatcmds[k]
			self.cmdfuncs[cmdname] = {"toggleToHotseat", k}
			
		end
		
	end
	
end



-- Reset a single sequence of IDI data to an empty, default state
function Extrovert:resetSequence(i)

	self.seq[i] = {}
	
	self.seq[i].pointer = 1
	self.seq[i].active = false
	
	self.seq[i].loop = false
	self.seq[i].reverse = false
	self.seq[i].stutter = false
	self.seq[i].slow = false
	
	self.seq[i].incoming = {} -- Holds all flag changes that will occur upon the next tick, or the next button-gate if a "gate" flag is present
	
	self.seq[i].tick = {}
	for t = 1, self.gridx * 24 do -- Insert dummy ticks
		self.seq[i].tick[t] = {}
	end
	
	pd.post("Reset all flags and notes in sequence " .. i)

end

-- Reset all sequences of MIDI data to an empty, default state
function Extrovert:resetAllSequences()

	-- Iterate through all sequence positions, refilling them with default settings
	for i = 1, self.gridx * (self.gridy - 2) do
		self:resetSequence(i)
	end

end




function Extrovert:initialize(sel, atoms)

	-- 1. Key commands
	-- 2. Monome button
	-- 3. Monome ADC
	-- 4. MIDI CLOCK IN
	self.inlets = 4
	
	-- No outlets. Everything is done through pd.send() instead.
	self.outlets = 0
	
	self.prefs = self:dofile("extrovert-prefs.lua") -- Get user prefs to reflect the user's particular setup
	
	self.cmdnames = self.prefs.cmdnames -- Holds the command-types that the user toggles between, and their corresponding MIDI command values
	self.notenames = self.prefs.notenames -- Table of user-readable note values, indexed appropriately
	self.keynames = self.prefs.keynames -- Get the names of keys used in the editor's computer-piano-keyboard
	
	self.ctrlflags = {} -- Holds all control-flags, which correspond to the control-buttons on the Monome
	self.flagnames = self.prefs.flagnames -- Names that correspond to both control buttons and sequence flags
	for _, v in pairs(self.flagnames) do
		self.ctrlflags[v] = false -- Initialize all control-button flag variables
	end
	
	self.commands = self.prefs.commands -- Get the user-defined list of computer-keychord commands
	self.cmdfuncs = self.prefs.cmdfunctions -- Get the hash that joins command-names to function-names and args
	
	self.savepath = self.prefs.dirs.saves -- User-defined absolute path that contains all savefolders
	if self.savepath:sub(-1) ~= "/" then
		self.savepath = self.savepath .. "/"
	end
	
	self.hotseats = self.prefs.hotseats -- List of savefile hotseats
	self.hotseatcmds = self.prefs.hotseatcmds -- List of hotseat keycommands
	self.activeseat = 1 -- Currently active hotseat
	
	self.color = {}
	for k, v in ipairs(self.prefs.gui.color) do -- Split the user-defined colors into regular, light, and dark variants
		table.insert(self.color, modColor(v))
	end
	
	self.gridx = self.prefs.monome.width -- Monome X buttons
	self.gridy = self.prefs.monome.height -- Monome Y buttons
	
	self.history = {} -- Tracks all changes, for the undo/redo functions to act upon
	self.undodepth = self.prefs.undo.depth -- Number of undo-steps the self.history table will hold.
	self.undopoint = 1 -- Current point in the history table (advanced by redo, decreased by undo)
	
	self.copy = {
		tab = {}, -- Table to hold the active cut/copy/paste data
		top = false, -- Top tick-pointer; false when not active
		bot = false, -- Bottom tick-pointer; false when not active
		notetop = 1, -- Top note-pointer
		notebot = 1, -- Bottom note-pointer
	}
	
	self.kb = {} -- Keeps track of which keys are currently pressed on the computer-keyboard
	
	self.key = 1 -- Current active phrase in the editor panel
	self.pointer = 1 -- Current active tick in the editor panel
	self.notepointer = 1 -- Current active note within the active tick in the editor panel
	
	self.bpm = 120 -- Internal BPM value, for when MIDI CLOCK is not slaved to an external source
	
	self.channel = 0 -- Current MIDI channel in the editor
	self.command = 144 -- Current command type in the editor
	self.octave = 3 -- Current octave in the editor
	self.velocity = 127 -- Current velocity in the editor
	self.duration = 24 -- Current duration in the editor
	
	self.spacing = 12 -- Spacing between notes, in ticks, when notes are entered
	self.quant = 24 -- Current quantization value (1 = tick, 3 = thirtysecond note, 6 = sixteenth note, 12 = eighth note, 24 = quarter note, 48 = half note, 96 = whole note, etc.)
	
	self.friendlyview = true -- Track friendly-note-view mode in the editor: true for friendly view; false for hacker view
	
	self.acceptpiano = true -- Track piano-note-accepting mode in the editor: true to record and play piano notes; false to play without recording
	
	self.clocktype = self.prefs.midi.clocktype -- User-defined MIDI CLOCK type.
	self.acceptpulse = false -- Tracks whether to accept MIDI CLOCK pulses
	
	self.tick = 1 -- Current clock tick in the sequencer (wraps around at 268435456, the largest possible tick value)
	
	self.page = 1 -- Active page, for tabbing between pages of sequences in performance
	
	self.pressed = {} -- Track the button-press status of all buttons on the Monome grid
	for i = 1, self.gridx * self.gridy do
		pressed[i] = false
	end
	
	self.seq = {} -- Holds all MIDI sequence data, and all sequences' performance-related flags
	
	self:assignHotseatsToCmds()
	
	self:assignPianoKeysToCmds()
	
	self:resetAllSequences() -- Populate the self.seq table with default data
	
	self:makeCleanHistory() -- Put default values in the history table, so the undo/redo code doesn't wig out
	
	self:buildGUI()
	
	self:populateGUI()
	
	self:initializeMonome()
	
	self:initializeClock()
	
	self:propagateBPM()
	
	self:startTempo()
	
	return true

end



-- Parse incoming commands from the computer-keyboard
function Extrovert:in_1_list(key)

	-- Chop the "_L" and "_R" off incoming Shift keystrokes
	if key[2]:sub(1, 5) == "Shift" then
		key[2] = "Shift"
	end
	
	if key[1] == 1 then -- On key-down...
	
		if self.kb[key[2]] == nil then -- If the key isn't already set, set it
			self.kb[key[2]] = key[2]
		end
		
		-- Compare the current pressed keys with the list of command keychords
		for k, v in pairs(self.commands) do
		
			-- Organize the command-list data properly for comparison
			local compare = {}
			for _, vv in pairs(v) do
				compare[vv] = vv
			end
			
			if crossCompare(self.kb, compare) then -- If the current keypresses match a command's keychord, clear the non-chorded keys and activate the command
			
				-- Unset all non-chording keys
				for k, _ in pairs(self.kb) do
					if (k ~= "Shift")
					and (k ~= "Tab")
					then
						self.kb[k] = nil
					end
				end
				
				self:parseEditorCommand(k)
				
				break -- Break from the outer for loop, after finding the correct command
				
			end
		
		end
		
	else -- On key-up...
	
		self.kb[key[2]] = nil -- Unset the key
		
	end

end



-- Parse Monome button commands
function Extrovert:in_2_list(t)

	local x = t[1] + 1
	local y = t[2] + 1
	
	if y == (self.gridy - 1) then -- Parse page-row commands
	
		self:parsePageButton(x)
	
	elseif y == self.gridy then -- Parse control-row commands
	
		self:parseCommandButton(x, t[3])
	
	else -- Parse sequence-button commands
	
		self:parseSeqButton(x, y, s)
	
	end
	
	pd.post("Monome cmd: " .. table.concat(t, " "))
	
end



-- Parse Monome ADC commands
function Extrovert:in_3_list(t)

end



-- Parse incoming tempo ticks or MIDI CLOCK commands
function Extrovert:in_4(sel, m)

	if sel == "bang" then -- Accept [metro]-based tempo ticks
	
		if self.clocktype == "master" then
			pd.send("extrovert-clock-out", "float", {248})
		end

		self.tick = (self.tick % 268435456) + 1
		
		self:iterateAllSequences()
	
	elseif sel == "float" then -- Accept MIDI CLOCK tempo commands
	
		if m == 248 then -- MIDI CLOCK PULSE
		
			if self.tick == 0 then -- Compensate for the initial dummy tick
				self.tick = 1
			else -- Accept regular clock ticks
			
				self.tick = (self.tick % 268435456) + 1
				
				self:iterateAllSequences()
			
			end
		
		elseif m == 250 then -- MIDI CLOCK START
		
			if not self.acceptpulse then
				self.tick = 0 -- Set tick to 0 instead of 1, in order to compensate for the initial dummy downbeat
				self.acceptpulse = true
			end
			
			pd.post("Received MIDI CLOCK START")
			
		elseif m == 251 then -- MIDI CLOCK CONTINUE
		
			if not self.acceptpulse then
				self.acceptpulse = true
			end
			
			pd.post("Received MIDI CLOCK CONTINUE")
		
		elseif m == 252 then -- MIDI CLOCK END
		
			if self.acceptpulse then
				self.acceptpulse = false
			end
			
			pd.post("Received MIDI CLOCK END")
		
		end
		
		if self.clocktype == "thru" then -- Send the MIDI CLOCK messages onward, if the clocktype is set to THRU
			pd.send("extrovert-clock-out", "float", {m})
		end
		
	end

end
