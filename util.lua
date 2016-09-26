util = {}

local function writeasstring(v, flags, depth)
	v = tostring(v)
	if depth then
		local len
		if depth < 0 then
			len = flags.keylen
		else
			len = flags.valuelen
		end
		v = v:setlen(len)
	end
	io.write(v)
end

local _write = io.write

io.write = setmetatable({
	number = writeasstring,
	boolean = writeasstring,
	thread = writeasstring,
	userdata = writeasstring,
	["nil"] = writeasstring,
	["function"] = writeasstring,
	string = function(v, flags, depth)
		writeasstring("\""..v.."\"", flags, depth)
	end,
},
{
	__call = function(_, ...)
		_write(...)
	end
})

function io.write.table(t, flags, depth)
	depth = depth or 1
	if depth < 0 then
		writeasstring(t, flags, depth)
		return
	end
	flags = flags or {}
	flags.history = flags.history or {}
	flags.tabstr = flags.tabstr or "  "
	if not flags.history[t] and (not flags.maxdepth or depth <= flags.maxdepth) then
		flags.history[t] = true
		writeasstring(tostring(t)..":", flags, depth)
		if flags.showmetatables then
			local mt = getmetatable(t)
			if mt then
				print()
				io.write(string.rep(flags.tabstr, depth))
				io.write(("metatable"):setlen(flags.keylen).. " = ")
				io.write[type(mt)](mt, flags, depth + 1)
			end
		end
		for k, v in ipairs(t) do
			print()
			io.write(string.rep(flags.tabstr, depth))
			io.write("<")
			io.write[type(k)](k, flags, -1)
			io.write("> = ")
			io.write[type(v)](v, flags, depth + 1)
		end
		for k, v in pairs(t) do
			if type(k) ~= "number" or k < 1 or k > #t then
				print()
				io.write(string.rep(flags.tabstr, depth))
				io.write("[")
				io.write[type(k)](k, flags, -1)
				io.write("] = ")
				io.write[type(v)](v, flags, depth + 1)
			end
		end
	else
		writeasstring(t, flags, depth)
	end
end

function table.print(t, flags)
	io.write.table(t, flags)
	print()
end

function unpackfunc(iter, ...)
	local i = iter(...)
	if i then
		return i, unpackfunc(iter, ...)
	end
	return nil
end

function string:setlen(newlen, pad)
	self = tostring(self)
	if not newlen then return self end
	pad = pad or " "
	local len = #self
	if len > newlen then
		return self:sub(1, newlen)
	else
		if #pad ~= 0 then
			return self..(pad:rep(math.ceil(newlen - len) / #pad):sub(1, newlen - len))
		else
			return self
		end
	end
end

util.mt_recordkeyorder = {
	__newindex = function(self, k, v)
		rawset(self, k, v)
		if type(k) ~= "number" then
			rawset(self, #self + 1, k)
		end
	end
}

function printf(format, ...)
	print(format:format(...))
end

local _format = string.format

local modes = {
	b = "1",
	f = "2",
	i = "3",
	u = "4",
	n = "7",
	h = "8",
	s = "9",
}

local fgcolors = {
	[""] = "39",
	D = "30",
	R = "31",
	G = "32",
	Y = "33",
	B = "34",
	M = "35",
	C = "36",
	W = "37",
}

local bgcolors = {
	[""] = "49",
	D = "40",
	R = "41",
	G = "42",
	Y = "44",
	B = "44",
	M = "45",
	C = "46",
	W = "47",
}

local function sequence(mode, fg, bg)
	local args
	if mode == "" and fg == "" and bg == "" then
		args = "0"
	else
		if mode == "#" then
			return "#"
		end
		mode = modes[mode]
		fg = fgcolors[fg]
		bg = bgcolors[bg]
		if mode then args = mode end
		if fg then args = args and args..";"..fg or fg end
		if bg then args = args and args..";"..bg or bg end
	end
	return "\x1B["..args.."m"
end

function string:format(...)
	return _format(string.gsub(self, "#([#_bfiunhs]?)([_DRGYBMCW]?)([_DRGYBMCW]?)$?", sequence), ...)
end

function io.writef(f, ...)
	return io.write(tostring(f):format(...))
end
