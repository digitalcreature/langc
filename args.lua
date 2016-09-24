require "util"

args = {}

function args:printhelp()
	if args.printhelpheader then args:printhelpheader() end
	print("available options are:")
	for _, option in ipairs(options) do
		print(option.name:setlen(12)..option.shortname:setlen(4)..option.usage:setlen(16)..option.desc:setlen(32))
	end
end

options = setmetatable({}, {
	__metatable = {
		__index = {
			argc = 0,
			desc = "",
			usage = "",
			init = function(self, desc, argc, usage)
				self.desc = desc or self.desc
				self.argc = argc or self.argc
				self.usage = usage or self.usage
			end,
		},
		__call = function(self, ...)
			self:exec(...)
		end
	},
	__newindex = function(self, k, v)
		if type(k) == "string" and type(v) == "function" then
			v = setmetatable({exec = v}, getmetatable(self))
			v.name = "--"..k
			v.shortname = "-"..k:sub(1, 1)
			rawset(self, #self + 1, v)
			rawset(self, k:sub(1, 1), v)
		end
		rawset(self, k, v)
	end
})

args.options = options


function args:parse(args)
	local function notenoughargsforoption(option, arg, given)
		printf("not enough args for option \'%s\':", arg)
		printf("given %d args, need %d", given, option.argc)
		printf("usage: %s %s", arg, option.usage)
	end
	local i = 1
	local params = {}
	while args[i] do
		local arg = args[i]
		if arg:sub(1, 1) == "-" then
			-- option
			if arg:sub(2, 2) == "-" then
				-- long option
				local option = options[arg:sub(3)]
				if option then
					local argc = option.argc
					if args[i + argc] then
						if argc > 0 then
							option(args[i + 1], args[i + argc])
						else
							option()
						end
						i = i + argc
					else
						notenoughargsforoption(option, arg, #args - i)
						return
					end
				else
					printf("unrecognized option \'%s\'", arg)
					self:printhelp()
					return
				end
			else
				-- short options(s)
				local j = 2
				for o in arg:gmatch("([^-])") do
					local option = options[o]
					if option then
						local argc = option.argc
						if argc > 0 and j < #arg then
							printf("can't parse args for short option \'%s\' in option cluster \'%s\':", "-"..o, arg)
							print("short option must be last in cluster")
							return
						end
						if args[i + argc] then
							if argc > 0 then
								option(args[i + 1], args[i + argc])
							else
								option()
							end
							i = i + argc
						else
							notenoughargsforoption(option, "-"..arg, #args - i)
						end
					else
						printf("unrecognized short option \'%s\'", "-"..o)
						self:printhelp()
						return
					end
					j = j + 1
				end
			end
		else
			-- param
			table.insert(params, arg)
		end
		i = i + 1
	end
	return params
end
