
--[[ Houman#7172 ]]
--[[ Houman#7172 ]]

local ESX = nil
local cach_log = nil

local function reversedipairsiter(t, i)
    i = i - 1
    if i ~= 0 then
        return i, t[i]
    end
end
function reversedipairs(t)
    return reversedipairsiter, t, #t + 1
end

local IsInATM = false

function OpenATM()
	SendNUIMessage({
		type = 'OpenATM',
	})
	SetNuiFocus(true, true)
	IsInATM = true
end

function CloseATM()
	SendNUIMessage({
		type = 'CloseATM',
	})
	SetNuiFocus(false, false)
	IsInATM = false
end

local cashhtml = ''
local bankhtml = ''

function SET_CASH_AND_BANK(cash, bank, last)
	if last then
		local M = 0
		local color = 'green'
		if last.cash then
			color = 'green'
			M = tonumber(cash) - tonumber(last.cash)
			if tonumber(last.cash) >= tonumber(cash) then
				color = 'red'
			else
				M = '+' .. tostring(M)
			end
			cashhtml = '<div style="float:right;color:'..color..';">|'..tostring(M)..'</div>'
			CreateThread(function()
				Wait(2500)
				cashhtml = ''
			end)
		end
		if last.bank then
			color = 'green'
			M = tonumber(bank) - tonumber(last.bank)
			if tonumber(last.bank) >= tonumber(bank) then
				color = 'red'
			else
				M = '+' .. tostring(M)
			end
			bankhtml = '<div style="float:right;color:'..color..';">|'..tostring(M)..'</div>'
			CreateThread(function()
				Wait(2500)
				bankhtml = ''
			end)
		end
	end
	if cash then
		SendNUIMessage({
			type = 'SetCash',
			money=cashhtml..'Cash: '..tostring(cash)..'$'
		})
	end
	if bank then
		SendNUIMessage({
			type = 'SetBank',
			money='Bank: '..tostring(bank)..'$'..bankhtml
		})
	end
end

function Set_IC_Name(name)
	SendNUIMessage({
		type = 'IC_Name',
		name=name
	})
end


function Save_Cach_Log()
	if type(cach_log) ~= 'string' then
		cach_log = json.encode(cach_log)
	end
	SetResourceKvp('CACH_LOG', cach_log)
	cach_log = json.decode(cach_log)
end

function Add_Cach_Log(text)
	table.insert(cach_log, text)
	Save_Cach_Log()
end

function Get_Cach_Log()
	local text = ''
	for _,i in reversedipairs((cach_log)) do
		text = text .. i .. '<br>'
	end
	return text
end

function Say_Player_Give_You_Money(playerid, money)
	local handle = RegisterPedheadshot(PlayerPedId())
    while not IsPedheadshotReady(handle) or not IsPedheadshotValid(handle) do
        Citizen.Wait(0)
    end
    local txd = GetPedheadshotTxdString(handle)
    BeginTextCommandThefeedPost("STRING")
	local texta = ("ID: %s"):format(playerid)
	local textb = ("Send You %s$"):format(money)
	EndTextCommandThefeedPostMessagetextWithCrewTag(txd, txd, false, 9, texta, textb, 1.0)
    UnregisterPedheadshot(handle)
end

function StartHelpText(msg)
	SetTextComponentFormat("STRING")
	AddTextComponentString(msg)
	DisplayHelpTextFromStringLabel(0, true, 1, -1)
end
function StopHelpText()
	SetTextComponentFormat("STRING")
	AddTextComponentString(' ')
	DisplayHelpTextFromStringLabel(0, false, 0, 30)
end

local The_ATM = nil
local NearATM = false

CreateThread(function()
	while ESX == nil do
		Wait(250)
	end
	while true do
		Wait(555)
		local coords = GetEntityCoords(PlayerPedId())
		local NearATM_x = false
		local NearATM_x2 = false
		local last_atm_find = {0, 9999.0}
		for k,v in pairs(Config.ATM_Objects) do
			local atm = GetClosestObjectOfType(coords, 15.0, GetHashKey(v), false)
			if DoesEntityExist(atm) then
				NearATM_x2 = true
				local V = Vdist(GetEntityCoords(atm), coords)
				if V <= 2.0 and V <= last_atm_find[2] then
					last_atm_find[1] = atm
					last_atm_find[2] = V
				end
			end
		end
		if DoesEntityExist(last_atm_find[1]) then
			NearATM_x = true
			The_ATM = last_atm_find[1]
		end
		if NearATM_x and not NearATM then
			StartHelpText(Config.PressToOpen)
		elseif not NearATM_x and NearATM then
			StopHelpText()
			CloseATM()
		end
		NearATM = NearATM_x
		if not NearATM_x2 or IsInATM then
			Wait(777)
			if not NearATM_x2 then
				The_ATM = nil
			end
		end
	end
end)

CreateThread(function()
	while ESX == nil do
		Wait(250)
	end
	while true do
		Wait(1)
		if IsInATM or not NearATM then
			Wait(500)
			if IsInATM then
				ESX.TriggerServerCallback('Hu_ATM:GetInfo_A', function(list)
					if type(list) == 'table' and list.cash and list.bank then
						SET_CASH_AND_BANK(list.cash, list.bank)
						Set_IC_Name(list.icname)
					end
				end)
			end
		elseif NearATM then
			if IsControlJustPressed(2, 38) then
				local playerPed = PlayerPedId()
				RequestAnimDict(Config.Anim_a[1])
				RequestAnimDict(Config.Anim_b[1])
				while not HasAnimDictLoaded(Config.Anim_a[1]) do Wait(10) end
				SetCurrentPedWeapon(playerPed, GetHashKey("weapon_unarmed"), true)
				TaskLookAtEntity(playerPed, The_ATM, 2000, 2048, 2)
				TaskGoStraightToCoord(playerPed, GetEntityCoords(The_ATM), 3.0, 4000, GetEntityHeading(The_ATM), 0.5)
				Wait(1000)
				TaskPlayAnim(playerPed, Config.Anim_a[1], Config.Anim_a[2], 8.0, 1.0, -1, 0, 0.0, 0, 0, 0)
				RemoveAnimDict(Config.Anim_a[1])
				Wait(1200)
				TaskPlayAnim(playerPed, Config.Anim_b[1], Config.Anim_b[2], 8.0, 1.0, -1, 0, 0.0, 0, 0, 0)
				RemoveAnimDict(Config.Anim_b[1])
				PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
				if NearATM then
					OpenATM()
				end
			end
		end
	end
end)

CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Wait(250)
	end
	cach_log = GetResourceKvpString('CACH_LOG')
	if cach_log then
		cach_log = json.decode(cach_log)
	else
		cach_log = '[]'
		Save_Cach_Log()
		cach_log = json.decode(cach_log)
	end
	OpenATM()
	CloseATM()
end)

RegisterNUICallback('datas', function(data, cb)
    local datas = data
	if datas.SetNuiFocus ~= nil then
		local bool = datas.SetNuiFocus
		SetNuiFocus(bool, bool)
	elseif datas.CloseATM == true then
		IsInATM = false
	elseif datas.Cash_Select == true then
		if datas.type and datas.money and tonumber(datas.money) and tonumber(datas.money) > 0 then
			if datas.type == 'GET' or datas.type == 'PUT' then
				SendNUIMessage({
					type = 'ASK',
					model=datas.type,
					money=tonumber(datas.money)
				})
			else
				if datas.type == 'SEND_Player' then
					SendNUIMessage({
						type = 'ASK_TO_SEND',
						model=datas.type,
						money=tonumber(datas.money),
						playerid = tonumber(datas.playerid),
					})
				end
			end
		else
			SendNUIMessage({
				type = 'ERROR',
			})
		end
	elseif datas.Cash_YES == true then
		if datas.type and datas.money and tonumber(datas.money) and tonumber(datas.money) > 0 then
			if datas.type == 'PUT' then
				ESX.TriggerServerCallback('Hu_ATM:MONEY_A', function(cb, cash, bank, last, x_time)
					if cb then
						SET_CASH_AND_BANK(cash, bank, last)
						Add_Cach_Log(string.format('You PUT %s$ In Bank | %s', datas.money, x_time))
					else
						SendNUIMessage({
							type = 'ERROR',
						})
					end
				end, {type='PUT', money=datas.money})
			elseif datas.type == 'GET' then
				ESX.TriggerServerCallback('Hu_ATM:MONEY_A', function(cb, cash, bank, last, x_time)
					if cb then
						SET_CASH_AND_BANK(cash, bank, last)
						Add_Cach_Log(string.format('You GET %s$ From Bank | %s', datas.money, x_time))
					else
						SendNUIMessage({
							type = 'ERROR',
						})
					end
				end, {type='GET', money=datas.money})
			elseif datas.type == 'SEND_Player' then
				if datas.playerid and datas.money then
					ESX.TriggerServerCallback('Hu_ATM:MONEY_SEND_FOR_PLAYER', function(cb, bank, lastbank, x_time)
						if cb then
							SET_CASH_AND_BANK(nil, bank, {bank=lastbank})
							Add_Cach_Log(('You Send %s$ To ID:%s | %s'):format(datas.money, datas.playerid, x_time))
						else
							SendNUIMessage({
								type = 'ERROR',
							})
						end
					end, {money=datas.money, playerid=datas.playerid})
				else
					SendNUIMessage({
						type = 'ERROR',
					})
				end
			end
		end
	elseif datas.Open_LOG == true then
		SendNUIMessage({
			type = 'Open_Log',
			text = Get_Cach_Log(),
		})
	end
end)

RegisterNetEvent('Hu_ATM:ADD_MONEY_FROM_PLAYER')
AddEventHandler('Hu_ATM:ADD_MONEY_FROM_PLAYER', function(datas)
	local playerid = datas[1]
	local money = datas[2]
	local bank = datas[3]
	local lastbank = datas[4]
	Say_Player_Give_You_Money(playerid, money)
	SET_CASH_AND_BANK(nil, bank, {bank=lastbank})
end)
