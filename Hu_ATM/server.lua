
--[[ Houman#7172 ]]
--[[ Houman#7172 ]]

local ESX  = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local times_a = {}


function GetTime(name, source)
	name = tostring(name)
	source = tostring(source)
	local now_time = GetGameTimer()
	now_time = now_time / 1
	if not times_a[name] then
		times_a[name] = {}
	end
	if not times_a[name][source] then
		times_a[name][source] = 0
	end
	local want_return = now_time - times_a[name][source]
	times_a[name][source] = now_time
	return want_return
end

ESX.RegisterServerCallback('Hu_ATM:GetInfo_A', function(source, cb)

	local t = GetTime('GetInfo_A', source)
	if t >= 300 then
		local xPlayer = ESX.GetPlayerFromId(source)
		cb({cash=xPlayer.money, bank=xPlayer.bank, icname=xPlayer.name})
	else
		cb(nil)
	end

end)

function GetX_Time()
	return os.date("%Y/%m/%d")..' - '..os.date("%H:%M:%S")
end

ESX.RegisterServerCallback('Hu_ATM:MONEY_A', function(source, cb, data)

	local t = GetTime('MONEY_A', source)
	if t >= 1500 then
		local xPlayer = ESX.GetPlayerFromId(source)
		local cash = xPlayer.money
		local bank = xPlayer.bank
		local last = {bank = bank, cash = cash}
		if data and data.type and data.money and tonumber(data.money) then
			data.money = tonumber(data.money)
			data.money = math.floor(data.money)
			if data.money > 0 then
				if data.type == 'PUT' then
					if cash >= data.money then
						xPlayer.removeMoney(data.money)
						xPlayer.addBank(data.money)
						xPlayer = ESX.GetPlayerFromId(source)
						cash = xPlayer.money
						bank = xPlayer.bank
						local x_time = GetX_Time()
						cb(true, cash, bank, last, x_time)
						return
					else
						cb(false)
						return
					end
				elseif data.type == 'GET' then
					if bank >= data.money then
						xPlayer.removeBank(data.money)
						xPlayer.addMoney(data.money)
						xPlayer = ESX.GetPlayerFromId(source)
						cash = xPlayer.money
						bank = xPlayer.bank
						local x_time = GetX_Time()
						cb(true, cash, bank, last, x_time)
						return
					else
						cb(false)
						return
					end
				end
			end
		end
	end

	cb(nil)


end)

ESX.RegisterServerCallback('Hu_ATM:MONEY_SEND_FOR_PLAYER', function(source, cb, data)

	local t = GetTime('MONEY_SEND_FOR_PLAYER', source)
	if t >= 1500 then
		local xPlayer = ESX.GetPlayerFromId(source)
		local bank = xPlayer.bank
		local lastbank = bank
		if data and data.playerid and tonumber(data.playerid) and data.money and tonumber(data.money) then
			data.money = tonumber(data.money)
			data.money = math.floor(data.money)
			data.playerid = tonumber(data.playerid)
			data.playerid = math.floor(data.playerid)
			if data.money > 0 and data.playerid ~= -1 then
				local yPlayer = ESX.GetPlayerFromId(data.playerid)
				if yPlayer and yPlayer.source and DoesEntityExist(GetPlayerPed(data.playerid)) then
					if bank >= data.money then
						local Data_a = yPlayer.bank
						xPlayer.removeBank(data.money)
						yPlayer.addBank(data.money)
						yPlayer = ESX.GetPlayerFromId(data.playerid)
						local Data_b = yPlayer.bank
						TriggerClientEvent('Hu_ATM:ADD_MONEY_FROM_PLAYER', data.playerid, {source, data.money, Data_a, Data_b})
						xPlayer = ESX.GetPlayerFromId(source)
						bank = xPlayer.bank
						local x_time = GetX_Time()
						cb(true, bank, lastbank, x_time)
						return
					else
						cb(false)
						return
					end
				end
			end
		end
	end

	cb(nil)


end)
