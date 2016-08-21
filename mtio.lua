mtio.serialize = function(o, f)
	if type(o) == 'number' then
		f:write(o)
	elseif type(o) == 'string' then
		f:write(string.format('%q', o))
	elseif type(o) == 'table' then
		f:write('{')
		local first = true
		for k,v in pairs(o) do
			if first then
				first = false
			else
				f:write(', ')
			end
			f:write('[')
			mtio.serialize(k, f)
			f:write('] = ')
			mtio.serialize(v, f)
		end
		f:write('}')
	else
		error('cannot serialize a ' .. type(o))
	end
end

function exists(name)
	if type(name)~="string" then return false end
	return os.rename(name,name) and true or false
end

mtio.write_auth = function(world_path, players)
	local k = assert(io.open(world_path .. '/auth.txt', 'w'))
	local r = assert(io.open(world_path .. '/auth.pruned', 'a'))
	r:write('------------------------------------------\n')
	r:write('Players pruned on '..os.date()..'\n')
	r:write('------------------------------------------\n')
	for _, name in ipairs(players) do
		if players[name].keep then
			p = players[name]
			k:write(p.name..':'..p.hash..':'..p.privs..':'..p.last_login..'\n')
		else
			p = players[name]
			r:write(p.name..':'..p.hash..':'..p.privs..':'..p.last_login..'\n')
		end
		
	end
	k:close()
	r:close()
end

mtio.prune_player_files = function(world_path, players)
	local dir_path = world_path..'/players/'
	local filepath = 'pruned/'

	if not exists(dir_path..filepath) then
		os.execute('mkdir '..dir_path..filepath)
	end

	for _, name in ipairs(players) do
		if not players[name].keep then
			if exists(dir_path..name) then
				assert(os.rename(dir_path..name,
				                 dir_path..filepath..name))
			end
		end
	end
end

mtio.rewrite_beds_spawns = function(world_path, players)
	local filename = world_path..'/beds_spawns'
	local f = assert(io.open(filename, 'r'))
	local data = f:read('*all')
	f:close()

	local f = assert(io.open(filename, 'w'))
	for line in string.gmatch(data, '([^\n]*)\n') do
		local pattern = '([%S]*)%s([%S]*)%s([%S]*)%s([%S]*)'
		for x, y, z, n in string.gmatch(line, pattern) do
			if players[n].keep then
				f:write(x..' '..y..' '..z..' '..n..'\n')
			end
		end
	end
	f:close()
end

mtio.rewrite_homes = function(world_path, players)
	local filename = world_path..'/homes'
	local f = assert(io.open(filename, 'r'))
	local data = f:read('*all')
	f:close()

	local f = assert(io.open(filename, 'w'))
	for line in string.gmatch(data, '([^\n]*)\n') do
		local pattern = '([%S]*)%s([%S]*)%s([%S]*)%s([%S]*)'
		for x, y, z, n in string.gmatch(line, pattern) do
			if players[n].keep then
				f:write(x..' '..y..' '..z..' '..n..'\n')
			end
		end
	end
	f:close()
end

mtio.rewrite_unified_inventory_home = function(world_path, players)
	local filename = world_path..'/unified_inventory_home.home'
	local f = assert(io.open(filename, 'r'))
	local data = f:read('*all')
	f:close()

	local f = assert(io.open(filename, 'w'))
	for line in string.gmatch(data, '([^\n]*)\n') do
		local pattern = '([%S]*)%s([%S]*)%s([%S]*)%s([%S]*)'
		for x, y, z, n in string.gmatch(line, pattern) do
			if players[n].keep then
				f:write(x..' '..y..' '..z..' '..n..'\n')
			end
		end
	end
	f:close()
end

mtio.rewrite_u_skins = function(world_path, players)
	local filename = world_path..'/u_skins.mt'
	local f = assert(io.open(filename, 'r'))
	local data = f:read('*all')
	f:close()

	local f = assert(io.open(filename, 'w'))
	for line in string.gmatch(data, '([^\n]*)\n') do
		local pattern = '([%S]*)%s([%S]*)'
		for n, c in string.gmatch(line, pattern) do
			if players[n].keep then
				f:write(n..' '..c..'\n')
			end
		end
	end
	f:close()
end

mtio.rewrite_chat_next = function(world_path, players)
	local filename = world_path..'/chat_next.mt'
	local data_in = dofile(filename)
	local data_out = {}

	for name, v in pairs(data_in) do
		if players[name].keep then
			data_out[name] = v
		end
	end

	local f = assert(io.open(filename, 'w'))
	f:write('return ')
	mtio.serialize(data_out, f)
	f:close()
end

mtio.rewrite_news_stamps = function(world_path, players)
	local filename = world_path..'/news/news_stamps.mt'
	local data_in = dofile(filename)
	local data_out = {}

	for name, v in pairs(data_in) do
		if players[name].keep then
			data_out[name] = v
		end
	end

	local f = assert(io.open(filename, 'w'))
	f:write('return ')
	mtio.serialize(data_out, f)
	f:close()
end

mtio.rewrite_justice_records = function(world_path, players)
	local filename = world_path..'/justice/data.mt'
	local data_in  = dofile(filename)
	local data_out = {
		['inmates'] = {
			['inactive'] = {},
			['active'] = {}},
		['records'] = {}}

	for name, v in pairs(data_in.inmates.inactive) do
		if players[name].keep then
			data_out.inmates.inactive[name] = v
		end
	end

	for name, v in pairs(data_in.inmates.active) do
		if players[name].keep then
			data_out.inmates.active[name] = v
		end
	end

	for name, v in pairs(data_in.records) do
		if players[name].keep then
			data_out.records[name] = v
		end
	end

	local f = assert(io.open(filename, 'w'))
	f:write('return ')
	mtio.serialize(data_out, f)
	f:close()
end

mtio.rewrite_stats = function(world_path, players)
	local filename = world_path..'stats.mt'
	local data_in = dofile(filename)
	local data_out = {}

	for name, v in pairs(data_in) do
		if players[name].keep then
			data_out[name] = v
		end
	end

	local f = assert(io.open(filename, 'w'))
	f:write('return ')
	mtio.serialize(data_out, f)
	f:close()
end
