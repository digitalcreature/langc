require "token"

token.types["local"] = "keyword"
token.types["do"] = "keyword"
token.types["end"] = "keyword"
token.types["if"] = "keyword"
token.types["then"] = "keyword"
token.types["else"] = "keyword"
token.types["elseif"] = "keyword"
token.types["for"] = "keyword"
token.types["while"] = "keyword"
token.types["repeat"] = "keyword"
token.types["until"] = "keyword"

token.types["="] = "assign"
for op, name in pairs({
	["+"] = "add",
	["-"] = "subtract",
	["*"] = "multiply",
	["/"] = "divide",
	["%"] = "modulus",
	[".."] = "concat"
}) do
	token.types[op.."="] = name.." assign"
	token.types[op] = name
end

token.types["["] = "lbracket"
token.types["]"] = "rbracket"
token.types["{"] = "lbrace"
token.types["}"] = "rbrace"
token.types["("] = "lparen"
token.types[")"] = "rparen"

token.types["."] = "dot"
token.types[":"] = "colon"
token.types[";"] = "semicolon"
token.types[","] = "comma"

function token.types:identifier(c)
	if not self.value then
		if c:match("[%a_]") then
			self.value = c
		else
			return true
		end
	else
		if c:match("[%w_]") then
			self.value = self.value..c
		else
			return self()
		end
	end
end

token.types.identifier.color = "#C"

local digits = {}
digits["0"] = 0
digits["1"] = 1
digits["2"] = 2
digits["3"] = 3
digits["4"] = 4
digits["5"] = 5
digits["6"] = 6
digits["7"] = 7
digits["8"] = 8
digits["9"] = 9

function token.types:intliteral(c)
	if not self.value then
		if c:match("[%+%-]") then
			self.value = c;
		else
			self.value = digits[c]
			if not self.value then
				return true
			end
		end
		return
	end
	local digit = digits[c]
	if digit then
		if type(self.value) == "number" then
			self.value = self.value * 10 + digit
		else
			if digit > 0 then
				self.value = digit * (self.value == "-" and -1 or 1)
			end
		end
	else
		if type(self.value) == "number" then
			return self()
		else
			return true
		end
	end
end
token.types.intliteral.color = "#Y"

local escapechars = {
	n = "\n",
	r = "\r",
	t = "\t",
	["\\"] = "\\",
	["\""] = "\"",
	["\'"] = "\'",
}

function token.types:stringliteral(c)
	if not self.value then
		if c:match("[\"\']") then
			self.mode = c
			self.value = ""
			return
		else
			return true
		end
	end
	if self.mode == "done" then
		self.mode = nil
		self.escape = nil
		return self()
	end
	if (not self.escape) and c == self.mode then
		self.mode = "done"
	else
		if c == "\n" then return true end
		if self.escape then
			c = escapechars[c]
			self.escape = false
			if not c then return true end
		else
			if c == "\\" then
				self.escape = true
				return
			end
		end
		self.value = self.value..c
	end
end
token.types.stringliteral.color = "#Y"
