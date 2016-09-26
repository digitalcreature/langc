require "util"

token = {}
token.patterns = {}

token.type = setmetatable({}, {
	__call = function(self, name, value, finalpattern)
		local t = {}
		t.__index = t
		function t:__tostring()
			return string.format("#Rtoken#[#G%s# (#B%s#)]", tostring(self.value), self.type.name)
		end
		t.type = t
		t.name = name
		t.finalpattern = finalpattern
		t.value = value
		return setmetatable(t, self)
	end
}) do

	local tt = token.type

	tt.__index = tt

	tt.finalpattern = "[^%w_]"

	--prepare to start matching this token type
	function tt:startmatching()
		if self.iscustom then
			self.value = nil
		else
			self.i = 0
		end
	end

	--process next character. return nothing if the character is valid for this token type,
	-- true if it is invalid and has therefore disqualified this token type,
	-- or a table representing the fully parsed token if the next character finalizes it
	function tt:nextchar(char)
		if self.i == #self.value then
			if char:match(self.finalpattern) then
				return self()
			else
				return true
			end
		else
			if char == self.value:sub(self.i + 1, self.i + 1) then
				self.i = self.i + 1
			else
				return true
			end
		end
	end

	function tt:__tostring()
		return string.format("#ftokentype#[%s (%s)]", self.name, self.value)
	end

	--initialize a new token instance of this token type, with the passed value as that token's value.
	function tt:__call(value)
		local token = setmetatable({
			value = value
		}, self)
		return token
	end

end

token.types = setmetatable({}, {
	__newindex = function(self, k, v)
		if type(k) == "string" then
			local tokentype
			if type(v) == "string" then
				if v == "keyword" then
					tokentype = token.type(v, k)
					rawset(self, k, tokentype)
				else
					tokentype = token.type(v, k, ".")
					rawset(self, v, tokentype)
				end
			elseif type(v) == "function" then
				tokentype = token.type(k, "")
				tokentype.nextchar = v
				tokentype.iscustom = true
				rawset(self, k, tokentype)
			end
			if tokentype then
				rawset(self, #self + 1, tokentype)
			end
		else
			rawset(self, k, v)
		end
	end
})

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
		local candidates = {}
		local remaining = 0
		for i, type in ipairs(token.types) do
			type:startmatching()
			candidates[type] = true
			remaining = remaining + 1
		end
		local lastmatch, lastsl, lastsc, lastl, lastc
		while next do
			fragment = fragment..next
			for _, type in ipairs(token.types) do
				if candidates[type] then
					local result = type:nextchar(next)
					if result == true then
						candidates[type] = nil
						remaining = remaining - 1
					else
						if result then
							if remaining == 1 then
								return result, sl, sc, l, c
							else
								candidates[type] = nil
								remaining = remaining - 1
								lastmatch, lastsl, lastsc, lastl, lastc
									= result, sl, sc, l, c
							end
						end
					end
				end
			end
			getnext()
			if remaining == 0 then
				if lastmatch then
					return lastmatch, lastsl, lastsc, lastl, lastc
				else
					return string.format("could not parse token \'%s\'", fragment), sl, sc, l, c
				end
			end
		end
	end
end
