--# selene: allow(divide_by_zero, multiple_statements)

-- 8ch_32bit was here

--!native
--!optimize 2

local string = string;
local bit32 = bit32;
local table = table;

local Byte = string.byte;
local Sub = string.sub;
local Match = string.match;
local Rshift = bit32.rshift;
local Lshift = bit32.lshift;
local Band = bit32.band;
local Unpack = table.unpack;
local IsFrozen = table.isfrozen;

local _2p23 = 2 ^ 23;
local _2p24 = 2 ^ 24;
local _2p32 = 2 ^ 32;
local _2p40 = 2 ^ 40;
local _2p48 = 2 ^ 48;
local _2p52 = 2 ^ 52;

local stm_lua_bytecode
local wrap_lua_func
local stm_lua_func

-- SETLIST config
local FIELDS_PER_FLUSH = 50

-- remap for better lookup
local OPCODE_RM = {
	-- level 1
	[22] = 18, -- JMP
	[31] = 8, -- FORLOOP
	[33] = 28, -- TFORLOOP
	-- level 2
	[0] = 3, -- MOVE
	[1] = 13, -- LOADK
	[2] = 23, -- LOADBOOL
	[26] = 33, -- TEST
	-- level 3
	[12] = 1, -- ADD
	[13] = 6, -- SUB
	[14] = 10, -- MUL
	[15] = 16, -- DIV
	[16] = 20, -- MOD
	[17] = 26, -- POW
	[18] = 30, -- UNM
	[19] = 36, -- NOT
	-- level 4
	[3] = 0, -- LOADNIL
	[4] = 2, -- GETUPVAL
	[5] = 4, -- GETGLOBAL
	[6] = 7, -- GETTABLE
	[7] = 9, -- SETGLOBAL
	[8] = 12, -- SETUPVAL
	[9] = 14, -- SETTABLE
	[10] = 17, -- NEWTABLE
	[20] = 19, -- LEN
	[21] = 22, -- CONCAT
	[23] = 24, -- EQ
	[24] = 27, -- LT
	[25] = 29, -- LE
	[27] = 32, -- TESTSET
	[32] = 34, -- FORPREP
	[34] = 37, -- SETLIST
	-- level 5
	[11] = 5, -- SELF
	[28] = 11, -- CALL
	[29] = 15, -- TAILCALL
	[30] = 21, -- RETURN
	[35] = 25, -- CLOSE
	[36] = 31, -- CLOSURE
	[37] = 35, -- VARARG
}

-- opcode types for getting values
local OPCODE_T = {
	[0] = 'ABC',
	'ABx',
	'ABC',
	'ABC',
	'ABC',
	'ABx',
	'ABC',
	'ABx',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'AsBx',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'AsBx',
	'AsBx',
	'ABC',
	'ABC',
	'ABC',
	'ABx',
	'ABC',
}

local OPCODE_M = {
	[0] = {b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgR', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgR'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgR', c = 'OpArgU'},
	{b = 'OpArgR', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgN', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgN', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
};

-- int rd_int_basic(string src, int s, int e, int d)
-- @src - Source binary string
-- @s - Start index of a little endian integer
-- @e - End index of the integer
-- @d - Direction of the loop
local function rd_int_basic(src, s, e, d)
	local num = 0

	for i = s, e, d do num = num + Byte(src, i, i) * 256 ^ (i - s) end

	return num
end

-- float rd_flt_basic(byte f1..8)
-- @f1..4 - The 4 bytes composing a little endian float
local function rd_flt_basic(f1, f2, f3, f4)
	local sign = (-1) ^ Rshift(f4, 7)
	local exp = Rshift(f3, 7) + Lshift(Band(f4, 127), 1)
	local frac = f1 + Lshift(f2, 8) + Lshift(Band(f3, 127), 16)
	local normal = 1

	if exp == 0 then
		if frac == 0 then
			return 0;
		end;

		normal = 0
		exp = 1
	elseif exp == 127 then
		return sign * if frac == 0 then 1 / 0 else 0 / 0;
	end;

	return sign * 2 ^ (exp - 127) * (1 + normal / _2p23);
end

-- double rd_dbl_basic(byte f1..8)
-- @f1..8 - The 8 bytes composing a little endian double
local function rd_dbl_basic(f1, f2, f3, f4, f5, f6, f7, f8)
	local sign = (-1) ^ Rshift(f8, 7)
	local exp = Lshift(Band(f8, 127), 4) + Rshift(f7, 4)
	local frac = Band(f7, 15) * 2 ^ 48
	local normal = 1

	frac = frac + (f6 * _2p40) + (f5 * _2p32) + (f4 * _2p24) + (f3 * 65536) + (f2 * 256) + f1 -- help

	if exp == 0 then
		if frac == 0 then
			return sign * 0
		end;

		normal = 0
		exp = 1
	elseif exp == 2047 then
		return sign * if frac == 0 then 1 / 0 else 0 / 0;
	end;

	return sign * 2 ^ (exp - 1023) * (normal + frac / _2p52)
end

-- int rd_int_le(string src, int s, int e)
-- @src - Source binary string
-- @s - Start index of a little endian integer
-- @e - End index of the integer
local function rd_int_le(src, s, e) return rd_int_basic(src, s, e - 1, 1) end

-- int rd_int_be(string src, int s, int e)
-- @src - Source binary string
-- @s - Start index of a big endian integer
-- @e - End index of the integer
local function rd_int_be(src, s, e) return rd_int_basic(src, e - 1, s, -1) end

-- float rd_flt_le(string src, int s)
-- @src - Source binary string
-- @s - Start index of little endian float
local function rd_flt_le(src, s) return rd_flt_basic(Byte(src, s, s + 3)) end

-- float rd_flt_be(string src, int s)
-- @src - Source binary string
-- @s - Start index of big endian float
local function rd_flt_be(src, s)
	local f1, f2, f3, f4 = Byte(src, s, s + 3)
	return rd_flt_basic(f4, f3, f2, f1)
end

-- double rd_dbl_le(string src, int s)
-- @src - Source binary string
-- @s - Start index of little endian double
local function rd_dbl_le(src, s) return rd_dbl_basic(Byte(src, s, s + 7)) end

-- double rd_dbl_be(string src, int s)
-- @src - Source binary string
-- @s - Start index of big endian double
local function rd_dbl_be(src, s)
	local f1, f2, f3, f4, f5, f6, f7, f8 = Byte(src, s, s + 7) -- same
	return rd_dbl_basic(f8, f7, f6, f5, f4, f3, f2, f1)
end

-- to avoid nested ifs in deserializing
local float_types = {
	[4] = {little = rd_flt_le, big = rd_flt_be},
	[8] = {little = rd_dbl_le, big = rd_dbl_be},
}

-- byte stm_byte(Stream S)
-- @S - Stream object to read from
local function stm_byte(S)
	local idx = S.index
	local bt = Byte(S.source, idx, idx)

	S.index = idx + 1
	return bt
end

-- string stm_string(Stream S, int len)
-- @S - Stream object to read from
-- @len - Length of string being read
local function stm_string(S, len)
	local pos = S.index + len
	local str = Sub(S.source, S.index, pos - 1)

	S.index = pos
	return str
end

-- string stm_lstring(Stream S)
-- @S - Stream object to read from
local function stm_lstring(S)
	local len = S:s_szt()
	local str

	if len ~= 0 then str = Sub(stm_string(S, len), 1, -2) end

	return str
end

-- fn cst_int_rdr(string src, int len, fn func)
-- @len - Length of type for reader
-- @func - Reader callback
local function cst_int_rdr(len, func)
	return function(S)
		local pos = S.index + len
		local int = func(S.source, S.index, pos)
		S.index = pos

		return int
	end
end

-- fn cst_flt_rdr(string src, int len, fn func)
-- @len - Length of type for reader
-- @func - Reader callback
local function cst_flt_rdr(len, func)
	return function(S)
		local flt = func(S.source, S.index)
		S.index = S.index + len

		return flt
	end
end

local function stm_instructions(S)
	local size = S:s_int()
	local code = {}

	for Idx = 1, size do
		local ins = S:s_ins()
		local op = Band(ins, 63)
		local args = OPCODE_T[op]
		local mode = OPCODE_M[op]
		local data = { value = ins, op = OPCODE_RM[op], A = Band(Rshift(ins, 6), 255) }

		if args == 'ABC' then
			local B = Band(Rshift(ins, 23), 511);
			local C = Band(Rshift(ins, 14), 511);

			data.B = B;
			data.C = C;

			data.is_KB = mode.b == 'OpArgK' and B > 255;
			data.is_KC = mode.c == 'OpArgK' and C > 255;
		elseif args == 'ABx' then
			data.Bx = Band(Rshift(ins, 14), 262143)
			data.is_K = mode.b == 'OpArgK'
		elseif args == 'AsBx' then
			data.sBx = Band(Rshift(ins, 14), 262143) - 131071
		end;

		code[Idx] = data
	end;

	return code
end

local function stm_constants(S)
	local size = S:s_int();
	local consts = {};

	for Idx = 1, size do
		local tt = stm_byte(S);
		local k;

		if tt == 1 then
			k = stm_byte(S) ~= 0;
		elseif tt == 3 then
			k = S:s_num();
		elseif tt == 4 then
			k = stm_lstring(S);
		end

		consts[Idx] = k; -- offset +1 during instruction decode
	end;

	return consts;
end

local function stm_subfuncs(S, src)
	local size = S:s_int()
	local sub = {}

	for i = 1, size do
		sub[i] = stm_lua_func(S, src) -- offset +1 in CLOSURE
	end

	return sub
end

local function stm_lineinfo(S)
	local size = S:s_int()
	local lines = {}

	for i = 1, size do lines[i] = S:s_int() end

	return lines
end

local function stm_locvars(S)
	local size = S:s_int()
	local locvars = {}

	for i = 1, size do locvars[i] = {varname = stm_lstring(S), startpc = S:s_int(), endpc = S:s_int()} end

	return locvars
end

local function stm_upvals(S)
	local size = S:s_int()
	local upvals = {}

	for i = 1, size do upvals[i] = stm_lstring(S) end

	return upvals
end

function stm_lua_func(S, psrc)
	local proto = {}
	local src = stm_lstring(S) or psrc -- source is propagated

	proto.source = src -- source name

	S:s_int() -- line defined
	S:s_int() -- last line defined

	proto.numupvals = stm_byte(S) -- num upvalues
	proto.numparams = stm_byte(S) -- num params

	stm_byte(S) -- vararg flag
	stm_byte(S) -- max stack size

	proto.code = stm_instructions(S)
	proto.const = stm_constants(S)
	proto.subs = stm_subfuncs(S, src)
	proto.lines = stm_lineinfo(S)

	stm_locvars(S)
	stm_upvals(S)

	local Const = proto.const;

	-- post process optimization
	for _, code in proto.code do
		if code.is_K then
			code.const = Const[code.Bx + 1] -- offset for 1 based index

			continue;
		end;

		if code.is_KB then 
			code.const_B = Const[code.B - 0xFF];
		end;

		if code.is_KC then
			code.const_C = Const[code.C - 0xFF];
		end;
	end;

	return proto
end

function stm_lua_bytecode(src)
	-- func reader
	local rdr_func

	-- header flags
	local little
	local size_int
	local size_szt
	local size_ins
	local size_num
	local flag_int

	-- stream object
	local stream = {
		-- data
		index = 1,
		source = src,
	}

	assert(stm_string(stream, 4) == '\27Lua', 'invalid Lua signature')
	assert(stm_byte(stream) == 81, 'invalid Lua version')
	assert(stm_byte(stream) == 0, 'invalid Lua format')

	little = stm_byte(stream) ~= 0
	size_int = stm_byte(stream)
	size_szt = stm_byte(stream)
	size_ins = stm_byte(stream)
	size_num = stm_byte(stream)
	flag_int = stm_byte(stream) ~= 0

	rdr_func = little and rd_int_le or rd_int_be
	stream.s_int = cst_int_rdr(size_int, rdr_func)
	stream.s_szt = cst_int_rdr(size_szt, rdr_func)
	stream.s_ins = cst_int_rdr(size_ins, rdr_func)

	if flag_int then
		stream.s_num = cst_int_rdr(size_num, rdr_func)
	elseif float_types[size_num] then
		stream.s_num = cst_flt_rdr(size_num, float_types[size_num][little and 'little' or 'big'])
	else
		error('unsupported float size');
	end;

	return stm_lua_func(stream, '@virtual')
end

local function close_lua_upvalues(list, index)
	for Idx, Upval in list do
		local Index = Upval.index;

		if Index >= index then
			Upval.value = Upval.store[Index] -- store value
			Upval.store = Upval;
			Upval.index = 'value' -- self reference

			list[Idx] = nil
		end;
	end;
end;

local function open_lua_upvalue(list, index, stack)
	local prev = list[index]

	if not prev then
		prev = {index = index, store = stack}
		list[index] = prev
	end

	return prev
end

-- Who uses select lol
local function wrap_lua_variadic(...)
	local Args = { ... };

	return #Args, Args;
end;

local function on_lua_error(exst, err)
	local line = exst.lines[exst.pc - 1];
	local psrc, pline, pmsg = Match(err or '', '^(.-):(%d+):%s+(.+)');

	error(`{exst.source}:{line or '0'}: [{psrc or '?'}:{pline or '0'}] {pmsg or err or ''}`, 0);
end;

local function exec_lua_func(exst)
	-- localize for easy lookup
	local code = exst.code
	local subs = exst.subs
	local env = exst.env
	local upvs = exst.upvals
	local vargs = exst.varargs

	-- state variables
	local stktop = -1
	local openupvs = {}
	local stack = exst.stack
	local pc = exst.pc

	while true do
		local inst = code[pc];
		local op = inst.op;

		pc = pc + 1

		if op < 18 then
			if op < 8 then
				if op < 3 then
					if op < 1 then
						--[[LOADNIL]]
						for i = inst.A, inst.B do stack[i] = nil end
					elseif op > 1 then
						--[[GETUPVAL]]
						local uv = upvs[inst.B]

						stack[inst.A] = uv.store[uv.index]
					else
						--[[ADD]]
						local lhs = if inst.is_KB then inst.const_B else stack[inst.B];
						local rhs = if inst.is_KC then inst.const_C else stack[inst.C];

						stack[inst.A] = lhs + rhs;
					end
				elseif op > 3 then
					if op < 6 then
						if op > 4 then
							--[[SELF]]
							local A = inst.A;
							local B = stack[inst.B];

							stack[A + 1] = B;
							stack[A] = B[if inst.is_KC then inst.const_C else stack[inst.C]];
						else
							--[[GETGLOBAL]]
							stack[inst.A] = env[inst.const]
						end
					elseif op > 6 then
						--[[GETTABLE]]

						stack[inst.A] = stack[inst.B][if inst.is_KC then inst.const_C else stack[inst.C]]
					else
						--[[SUB]]
						local lhs = if inst.is_KB then inst.const_B else stack[inst.B];
						local rhs = if inst.is_KC then inst.const_C else stack[inst.C];

						stack[inst.A] = lhs - rhs
					end
				else --[[MOVE]]
					stack[inst.A] = stack[inst.B]
				end
			elseif op > 8 then
				if op < 13 then
					if op < 10 then
						--[[SETGLOBAL]]
						env[inst.const] = stack[inst.A]
					elseif op > 10 then
						if op < 12 then
							--[[CALL]]
							local A = inst.A;
							local B = inst.B;
							local C = inst.C;

							local params
							local sz_vals, l_vals

							if B == 0 then
								params = stktop - A
							else
								params = B - 1
							end

							sz_vals, l_vals = wrap_lua_variadic(stack[A](Unpack(stack, A + 1, A + params)))

							if C == 0 then
								stktop = A + sz_vals - 1
							else
								sz_vals = C - 1
							end

							for i = 1, sz_vals do stack[A + i - 1] = l_vals[i] end
						else
							--[[SETUPVAL]]
							local uv = upvs[inst.B]

							uv.store[uv.index] = stack[inst.A]
						end
					else
						--[[MUL]]
						local lhs = if inst.is_KB then inst.const_B else stack[inst.B];
						local rhs = if inst.is_KC then inst.const_C else stack[inst.C];

						stack[inst.A] = lhs * rhs;
					end
				elseif op > 13 then
					if op < 16 then
						if op > 14 then
							--[[TAILCALL]]
							local A = inst.A
							local B = inst.B
							local params

							if B == 0 then
								params = stktop - A;
							else
								params = B - 1;
							end;

							close_lua_upvalues(openupvs, 0);

							return wrap_lua_variadic(stack[A](Unpack(stack, A + 1, A + params)));
						else
							--[[SETTABLE]]

							stack[inst.A][if inst.is_KB then inst.const_B else stack[inst.B]] = if inst.is_KC then inst.const_C else stack[inst.C]
						end
					elseif op > 16 then
						--[[NEWTABLE]]
						stack[inst.A] = {}
					else
						--[[DIV]]
						local lhs = if inst.is_KB then inst.const_B else stack[inst.B];
						local rhs = if inst.is_KC then inst.const_C else stack[inst.C];

						stack[inst.A] = lhs / rhs;
					end
				else
					--[[LOADK]]
					stack[inst.A] = inst.const
				end
			else
				--[[FORLOOP]]
				local A = inst.A
				local step = stack[A + 2]
				local index = stack[A] + step
				local limit = stack[A + 1]
				local loops = if step == (step ^ 2) ^ 0.5 then index <= limit else index >= limit;

				if loops then
					stack[A] = index
					stack[A + 3] = index

					pc += inst.sBx
				end
			end
		elseif op > 18 then
			if op < 28 then
				if op < 23 then
					if op < 20 then
						--[[LEN]]
						stack[inst.A] = #stack[inst.B]
					elseif op > 20 then
						if op < 22 then
							--[[RETURN]]
							local A = inst.A
							local B = inst.B
							local vals = {}
							local size

							if B == 0 then
								size = stktop - A + 1
							else
								size = B - 1
							end

							for i = 1, size do vals[i] = stack[A + i - 1] end

							close_lua_upvalues(openupvs, 0)
							return size, vals
						else
							--[[CONCAT]]
							local B = inst.B;
							local str = stack[B]

							for i = B + 1, inst.C do
								str ..= stack[i]
							end

							stack[inst.A] = str
						end
					else
						--[[MOD]]
						local lhs = if inst.is_KB then inst.const_B else stack[inst.B];
						local rhs = if inst.is_KC then inst.const_C else stack[inst.C];

						stack[inst.A] = lhs % rhs;
					end
				elseif op > 23 then
					if op < 26 then
						if op > 24 then
							--[[CLOSE]]
							close_lua_upvalues(openupvs, inst.A)
						else
							--[[EQ]]
							local lhs = if inst.is_KB then inst.const_B else stack[inst.B];
							local rhs = if inst.is_KC then inst.const_C else stack[inst.C];

							if (lhs == rhs) == (inst.A ~= 0) then
								pc += inst.sBx
							end;

							pc += 1;
						end
					elseif op > 26 then
						--[[LT]]
						local lhs = if inst.is_KB then inst.const_B else stack[inst.B];
						local rhs = if inst.is_KC then inst.const_C else stack[inst.C];

						if (lhs < rhs) == (inst.A ~= 0) then
							pc += inst.sBx;
						end;

						pc += 1;
					else
						--[[POW]]
						local lhs = if inst.is_KB then inst.const_B else stack[inst.B];
						local rhs = if inst.is_KC then inst.const_C else stack[inst.C];

						stack[inst.A] = lhs ^ rhs;
					end
				else
					--[[LOADBOOL]]
					stack[inst.A] = inst.B ~= 0;

					if inst.C ~= 0 then
						pc += 1
					end;
				end;
			elseif op > 28 then
				if op < 33 then
					if op < 30 then
						--[[LE]]
						local lhs = if inst.is_KB then inst.const_B else stack[inst.B];
						local rhs = if inst.is_KC then inst.const_C else stack[inst.C];

						if (lhs <= rhs) == (inst.A ~= 0) then
							pc += inst.sBx;
						end;

						pc += 1;
					elseif op > 30 then
						if op < 32 then
							--[[CLOSURE]]
							local sub = subs[inst.Bx + 1] -- offset for 1 based index
							local nups = sub.numupvals
							local uvlist

							if nups ~= 0 then
								uvlist = {}

								local Remap0 = OPCODE_RM[0]; -- @MOVE
								local Remap4 = OPCODE_RM[4]; -- @GETUPVAL

								for i = 0, nups - 1 do
									local pseudo = code[pc + i];
									local psOp = pseudo.op;

									if psOp == Remap0 then -- @MOVE
										uvlist[i] = open_lua_upvalue(openupvs, pseudo.B, stack)
									elseif psOp == Remap4 then -- @GETUPVAL
										uvlist[i] = upvs[pseudo.B]
									end;
								end;

								pc += nups;
							end;

							stack[inst.A] = wrap_lua_func(sub, env, uvlist)
						else
							--[[TESTSET]]
							local A = inst.A
							local B = stack[inst.B];

							if (not B) == (inst.C ~= 0) then
								pc += 1;
							else
								stack[A] = B;
							end;
						end;
					else
						--[[UNM]]
						stack[inst.A] = -stack[inst.B];
					end;
				elseif op > 33 then
					if op < 36 then
						if op > 34 then
							--[[VARARG]]
							local A = inst.A
							local size = inst.B

							if size == 0 then
								size = vargs.size
								stktop = A + size - 1
							end;

							local list = vargs.list;

							for i = 1, size do stack[A + i - 1] = list[i]; end
						else
							--[[FORPREP]]
							local A = inst.A;
							local init, limit, step;

							init = assert(tonumber(stack[A]), '`for` initial value must be a number');
							limit = assert(tonumber(stack[A + 1]), '`for` limit must be a number');
							step = assert(tonumber(stack[A + 2]), '`for` step must be a number');

							stack[A] = init - step;
							stack[A + 1] = limit;
							stack[A + 2] = step;

							pc += inst.sBx;
						end
					elseif op > 36 then
						--[[SETLIST]]
						local A = inst.A;
						local C = inst.C;
						local size = inst.B;
						local tab = stack[A];
						local offset;

						if size == 0 then size = stktop - A end

						if C == 0 then
							C = inst[pc].value
							pc += 1
						end

						offset = (C - 1) * FIELDS_PER_FLUSH;

						for i = 1, size do
							tab[i + offset] = stack[A + i];
						end;
					else
						--[[NOT]]
						stack[inst.A] = not stack[inst.B];
					end
				else
					--[[TEST]]
					if (not stack[inst.A]) == (inst.C ~= 0) then pc += 1 end
				end
			else
				--[[TFORLOOP]]
				local A = inst.A
				local func = stack[A]
				local state = stack[A + 1]
				local index = stack[A + 2]
				local base = A + 3
				local vals

				-- === Luau compatibility - General iteration begin ===
				-- // ccuser44 added support for generic iteration
				-- (Please don't use general iteration in vanilla Lua code)
				if not index and not state and type(func) == "table" then
					-- Hacky check to see if __metatable is locked
					local canGetMt = pcall(getmetatable, func);
					local isMtLocked = canGetMt and not pcall(setmetatable, func, getmetatable(func)) or not canGetMt
					local metatable = canGetMt and getmetatable(func)

					if not IsFrozen(func) and isMtLocked and not metatable then
						warn("[FiOne]: The table has a metatable buts it's hidden, __iter and __call won't work in forloop.")
					end

					if not (typeof(metatable) == "table" and rawget(metatable, "__call")) then
						func, state, index = (type(metatable) == "table" and rawget(metatable, "__iter") or next), func, nil;

						stack[A], stack[A + 1], stack[A + 2] = func, state, index;
					end;
				end;

				-- === Luau compatibility - General iteration end ===

				stack[base + 2] = index;
				stack[base + 1] = state;
				stack[base] = func;

				vals = { func(state, index) };

				for i = 1, inst.C do stack[base + i - 1] = vals[i] end;

				if stack[base] ~= nil then
					stack[A + 2] = stack[base];
				else
					pc += 1;
				end;
			end;
		else
			--[[JMP]]
			pc += inst.sBx
		end

		exst.pc = pc
	end
end

function wrap_lua_func(state, env, upvals)
	local st_code = state.code
	local st_subs = state.subs
	local st_lines = state.lines
	local st_source = state.source
	local st_numparams = state.numparams

	local function exec_wrap(...)
		local stack = {};
		local varargs = {};
		local sizevarg = 0;

		local sz_args, l_args;

		l_args = { ... };
		sz_args = #l_args;

		local exst
		local ok, err, vals

		for i = 1, st_numparams do stack[i - 1] = l_args[i] end

		if st_numparams < sz_args then
			sizevarg = sz_args - st_numparams
			for i = 1, sizevarg do varargs[i] = l_args[st_numparams + i] end
		end

		exst = {
			varargs = {list = varargs, size = sizevarg},
			code = st_code,
			subs = st_subs,
			lines = st_lines,
			source = st_source,
			env = env,
			upvals = upvals,
			stack = stack,
			pc = 1,
		}

		ok, err, vals = pcall(exec_lua_func, exst, ...)

		if ok then
			return Unpack(vals, 1, err);
		else
			on_lua_error(exst, err);
		end;

		return; -- explicit "return nothing"
	end

	return exec_wrap;
end;

return function(BCode, Env)
	return wrap_lua_func(stm_lua_bytecode(BCode), Env or {})
end
