
return {

	-- Interpret a table of booleans like a binary value, convert that value to a decimal number,
	-- with each bit's value multiplied by "multi" (must be a multiple of 2, or defaults to 1), and bound it between "low" and "high".	
	boolsToNum = function(bools, bigend, multi, low, high)

		bigend = bigend ~= false
		multi = ((multi and (multi >= 2) and ((multi % 2) == 0)) and multi) or 1
		low = low or 0
		high = high or math.huge

		local bits = #bools
		local total = 0

		for k, v in pairs(bools) do
			if v then
				local key = (bigend and (bits - k)) or (k - 1)
				total = total + (math.max(1, 2 ^ key) * multi)
			end
		end

		total = math.max(low, math.min(high, total))

		pd.post("BOOLCAP: "..#bools)--debugging
		local testbools = deepCopy(bools)--debugging
		for k, v in pairs(testbools) do--debugging
			testbools[k] = tostring(v)--debugging
		end
		pd.post("BOOLS: "..table.concat(testbools, ", "))--debugging
		pd.post("BOOL-TO-NUM: "..total)--debugging

		return total

	end,

	-- Convert a number to a table of booleans
	numToBools = function(num, bigend, multi, size)

		num = num or 0

		local bools = {}

		if num == 0 then
			for i = 1, size do
				bools[i] = false
			end
			return bools
		end

		bigend = bigend ~= false
		multi = ((multi and (multi >= 2) and ((multi % 2) == 0)) and multi) or 1
		size = size or 8

		for i = (bigend and 1) or size, (bigend and size) or 1, (bigend and 1) or -1 do
			local index = (bigend and (#bools + 1)) or 1
			local key = (bigend and (size - i)) or (i - 1)
			local val = math.max(1, 2 ^ key) * multi
			if val <= num then
				table.insert(bools, index, true)
				num = num - val
			else
				table.insert(bools, index, false)
			end
		end

		local testbools = deepCopy(bools)--debugging
		for k, v in pairs(testbools) do--debugging
			testbools[k] = tostring(v)--debugging
		end
		pd.post("NEW-BOOLS: "..table.concat(testbools, ", "))--debugging

		return bools

	end,

	-- Compare the contents of two tables of type <t = {v1 = v1, v2 = v2, ...}>, and return true only on an exact match.
	crossCompare = function(t, t2)

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

	end,

	-- Recursively copy all sub-tables and sub-items, when copying from one table to another. Invoke as: newtable = deepCopy(oldtable, {})
	deepCopy = function(t, t2)

		t2 = t2 or {}

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
		
	end,

	-- Move a given table of functions into a different namespace
	funcsToNewContext = function(tab, context)
		for k, v in pairs(tab) do
			context[k] = v
		end
	end,

	-- Check whether a value falls within a particular range; return true or false
	rangeCheck = function(val, low, high)

		if high < low then
			low, high = high, low
		end

		if (val >= low)
		and (val <= high)
		then
			return true
		end
		
		return false

	end,

	-- Round number num, at decimal place dec
	roundNum = function(num, dec)
		local mult = 10 ^ dec
		return math.floor((num * mult) + 0.5) / mult
	end,

}
