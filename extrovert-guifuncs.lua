return {
	
	-- Build a properly-formatted list of object atoms, for passing into Pd
	buildObject = function(xpos, ypos, xsize, ysize, stitle, rtitle, label, labelx, labely, fontnum, fontsize, bgcolor, labelcolor)

		local obj = {
			"obj", -- Object tag
			xpos or 1, -- X-position in pixels
			ypos or 1, -- Y-position in pixels
			"cnv", -- Canvas tag
			math.min(xsize or 20, ysize or 20), -- Selectable box size
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
		
	end,

	-- Build a grid of buttons out of a table of object names
	buildGrid = function(names, sendto, x, absx, absy, width, height, mx, my, labelx, labely, fsize)

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
			pd.post("Extrovert-GUI: Spawned object \"" .. v .. "\"")
			
		end
		
	end,

	-- Get a table of RGB values (0-255), and return a table of RGB-normal, RGB-dark, RGB-light
	modColor = function(color)
		local colout = {color, {}, {}}
		for i = 1, 3 do
			colout[2][i] = math.max(0, color[i] - 30)
			colout[3][i] = math.min(255, color[i] + 30)
		end
		return colout
	end,

	-- Arrange a send-name, a color table, and a message-color table into a flat list
	rgbOutList = function(name, ctab, mtab)
		return {name, ctab[1], ctab[2], ctab[3], mtab[1], mtab[2], mtab[3]}
	end,

}