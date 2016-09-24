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
local colors = {
	["#"] = "#",
	[""] = "\x1B[0m",
	R = "\x1B[31m",
	G = "\x1B[32m",
	Y = "\x1B[33m",
	B = "\x1B[34m",
	M = "\x1B[35m",
	C = "\x1B[36m",
	W = "\x1B[37m",
}
function string:format(...)
	return _format(string.gsub(self, "#([#RGYBMCW]?)", colors), ...)
end

function io.writef(f, ...)
	return io.write(tostring(f):format(...))
end
