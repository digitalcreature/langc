require "token"

local digits = {}

for i = 0, 9 do
	digits[tostring(i)] = i
end


function token.types:identifier(c)
	if not self.value then
		if c:match("[%a_]") then
			self.value = c
		else
			return nil, true
		end
	else
		if c:match("[%w_]") then
			self.value = self.value..c
		else
			return self.value
		end
	end
end

token.types.identifier.color = "#C"

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

function token.types:intliteral(c)
	local digit = digits[c]
	if digit then
		if self.value then
			self.value = self.value * 10 + digit
		else
			self.value = digit
		end
	else
		if self.value then
			return self.value
		else
			return nil, true
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
			return nil, true
		end
	end
	if self.mode == "done" then
		return self.value
	end
	if (not self.escape) and c == self.mode then
		self.mode = "done"
	else
		if c == "\n" then return nil, "invalid multiline string" end
		if self.escape then
			self.escape = false
			if not escapechars[c] then
				return nil, string.format("invalid escape sequence\'\\%s\'", c)
			end
			c = escapechars[c]
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
token.types["=="] = "equal"
token.types["!="] = "not equal"
for op, name in pairs({
	["<"] = "less than",
	[">"] = "greater than",
}) do
	token.types[op] = name
	local assignop = op.."="
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

token.types["#!"] = "shebang"
