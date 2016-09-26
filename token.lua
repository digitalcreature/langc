require "util"

token = {}
token.patterns = {}

token.type = setmetatable({}, {
	__call = function(self, name, text, finalpattern)
		local t = {}
		t.__index = t
		function t:__tostring()
			return string.format("token[%s (%s)]", self.text, self.type.name)
		end
		t.type = t
		t.name = name
		t.finalpattern = finalpattern
		t.text = text
		token.types[name] = t
		table.insert(token.types, t)
		return setmetatable(t, self)
	end
}) do

	local tt = token.type

	tt.__index = tt

	tt.finalpattern = "[^%w]"

	--prepare to start matching this token type
	function tt:startmatching()
		self.i = 0
	end

	--process next character. return nothing if the character is valid for this token type,
	-- true if it is invalid and has therefore disqualified this token type,
	-- or a table representing the fully parsed token if the next character finalizes it
	function tt:nextchar(char)
		if self.i == #self.text then
			if char:match(self.finalpattern) then
				return self()
			else
				return true
			end
		else
			if char == self.text:sub(self.i + 1, self.i + 1) then
				self.i = self.i + 1
			else
				return true
			end
		end
	end

	function tt:__tostring()
		return string.format("tokentype[%s (%s)]", self.name, self.text)
	end

	--initialize a new token instance of this token type, with the passed text as that token's text.
	function tt:__call(text)
		local token = setmetatable({
			text = text
		}, self)
		return token
	end

end

token.types = {}

--returns an iterator that scans through a file and returns individual token objects
-- iterator also returns line, column count after each successful token
--	iterator returns error string if token could not be parsed

function token.tokenize(file)
	local l = 1 -- line count
	local c = 0 -- column count
	local next
	local function getnext()
		next = file:read(1)
		if next == "\r" then next = file:read(1) end
		if next == "\n" then
			c = 0
			l = l + 1
		else
			c = c + 1
		end
		return next
	end
	getnext()
	return function()
		while next and next:match("%s") do getnext() end
		if not next then return end
		local sl, sc = l, c	--line and column start counts for this token
		local fragment = ""
		local candididates = #token.types
		for _, type in ipairs(token.types) do
			type:startmatching()
		end
		local failures = {}
		while next do
			fragment = fragment..next
			for _, type in ipairs(token.types) do
				if not failures[type] then
					local result = type:nextchar(next)
					if result == true then
						failures[type] = true
						candididates = candididates - 1
					else
						if result then
							return result, sl, sc, l, c
						end
					end
				end
			end
			getnext()
			if candididates == 0 then
				return string.format("could not parse token \'%s\'", fragment), sl, sc, l, c
			end
		end
	end
end
