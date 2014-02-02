return {
	
	-- Swap the LOOP and INCOMING flags of a given two sequences, and switch the comparable positions of their two pointers
	swapSeqFlags = function(s, s2)
		s.loop, s2.loop = s2.loop, s.loop
		s.incoming, s2.incoming = s2.incoming, s.incoming
		s.pointer, s2.pointer = math.floor(s2.pointer / (#s2.tick / #s.tick)), math.floor(s.pointer / (#s.tick / #s2.tick))
		return s, s2
	end,

}