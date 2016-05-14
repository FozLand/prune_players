#!/usr/bin/lua

local load_time_start = os.clock()
local now = os.time()

if #arg ~= 1 then
	io.write(string.format('Usage:\n  %s <WorldPath>\n',arg[0]))
end

local load_players = function(world_path)
	local f = assert(io.open(world_path .. '/auth.txt', 'r'))
	local auth_data = f:read('*all')
	f:close()

	local players = {}
	local count = 0
	for line in string.gmatch(auth_data, '([^\n]*)\n') do
		local pattern = '([^:]*):([^:]*):([^:]*):([^:]*)'
		for n, h, p, t in string.gmatch(line, pattern) do
			table.insert(players,n) -- to retain player order
			players[n] = {
				name = n,
				hash = h,
				privs = p,
				last_login = tonumber(t),
			}
			count = count + 1
		end
	end
	table.sort(players)
	return players, count
end

local load_claim_counts = function(world_path,players)
	local f = assert(io.open(world_path..'/landrush-claims', 'r'))
	local claim_data = f:read('*all')
	f:close()

	for line in string.gmatch(claim_data, '([^\n]*)\n') do
		local pattern = '([%S]+)%s([%S]+)%s([%S]+)%s([%S]+)'
		for pos, owner, shared, claim_type in string.gmatch(line, pattern) do
			if claim_type == 'landclaim' then
				-- increment owned count
				if not players[owner].claims then
					players[owner].claims = {owned = 0, shared = 0}
				end
				players[owner].claims.owned = players[owner].claims.owned + 1

				for player in string.gmatch(shared, '([^,]+)') do
					-- increment shared count
					if player ~= '*' and player ~= '*all' then
						if not players[player].claims then
							players[player].claims = {owned = 0, shared = 0}
						end
						players[player].claims.shared = players[player].claims.shared + 1
					end
				end
			end
		end
	end
end

local has_claimed_land = function(player)
	local claims = player.claims
	if claims and ( claims.owned > 0 or claims.shared > 0 ) then
		return true
	end
	return false
end

local recently_logged_in = function(player)
	--local thirty_days_ago = now - 2592000 -- seconds in 30 days (30*24*60*60)
	local thirty_days_ago = now - (87*24*60*60)
	if player.last_login > thirty_days_ago then
		return true
	end
	return false
end

mtio = {}
dofile('mtio.lua')

local world_path = arg[1]
local players, player_count = load_players(world_path)
load_claim_counts(world_path,players)

local removed_count = 0
for _, name in ipairs(players) do
	local player = players[name]
	if has_claimed_land(player) or
	   recently_logged_in(player) then

		-- keep the player
		player.keep = true
	else

		-- remove the player
		player.keep = false
		removed_count = removed_count + 1
	end
end

-- write kept players to new auth.txt, pruned player to auth.pruned
mtio.write_auth(world_path, players)
-- move player files for deleted players out of player directory
mtio.prune_player_files(world_path, players)
-- remove deleted players from beds_spawns
mtio.rewrite_beds_spawns(world_path, players)
-- remove deleted players from chat_next.mt
mtio.rewrite_chat_next(world_path, players)
-- remove deleted players from homes
mtio.rewrite_homes(world_path, players)
-- remove deleted players from u_skins.mt
mtio.rewrite_u_skins(world_path, players)
-- remove deleted players from unified_inventory_home.home
mtio.rewrite_unified_inventory_home(world_path, players)
-- remove deleted players from news/news_stamps.mt
mtio.rewrite_news_stamps(world_path, players)

print('Loaded '..player_count..' players.')
print('Removed '..removed_count..' players.')
io.write(string.format('Finished in %.3fs\n',os.clock() - load_time_start))
