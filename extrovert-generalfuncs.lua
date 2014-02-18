return {
	
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

	-- Round number num, at decimal place idp
	roundNum = function(num, idp)
		mult = 10 ^ idp
		return math.floor((num * mult) + 0.5) / mult
	end,

	-- Recursively copy all sub-tables and sub-items, when copying from one table to another. Invoke as: newtable = deepCopy(oldtable, {})
	deepCopy = function(t, t2)

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

	-- Add more sub-tables to a table, up to a given numeric index
	extendTable = function(t, limit)

		if (next(t) == nil) then
			t[1] = {}
		end

		if limit > #t then
			for i = #t + 1, limit do
				t[i] = {}
			end
		end

		return t

	end,

	-- Move a given table of functions into a different namespace
	funcsToNewContext = function(tab, context)
		for k, v in pairs(tab) do
			context[k] = v
		end
	end,

}