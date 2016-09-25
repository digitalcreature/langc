require "util"

token = {}
token.patterns = {}

function token.patterns:string(c)

end

function token:tokenize(file)
	local l = 1 -- line count
	local c = 1 -- column count
	local next = file:read(1)
	while next do
		if c == 1 then
			io.write(string.format("#bD%d:# #b", l))
		end
		if next == "\r" then next = file:read(1) end
		if next == "\n" then
			io.writef("# #bD%d#", c)
			c = 1
			l = l + 1
		else
			c = c + 1
		end
		io.write(next)
		next = file:read(1)
	end
end
