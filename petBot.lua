NeP.Interface.CreatePlugin('BattlePet Bot', function() NeP.Interface.ShowGUI('NePpetBot') end)

local Fetch = NeP.Interface.fetchKey
local C_PB = C_PetBattles
local C_PJ = C_PetJournal
local isRunning = false

--[[-----------------------------------------------
** GUI table **
DESC: Gets returned to PEs build GUI to create it.

Build By: MTS
---------------------------------------------------]]
local config = {
	key = "NePpetBot",
	profiles = true,
	title = '|T'..NeP.Interface.Logo..':10:10|t'.." "..NeP.Info.Name,
	subtitle = "PetBot Settings",
	color = NeP.Interface.addonColor,
	width = 250,
	height = 300,
	config = {
		{ type = 'header', text = '|cff'..NeP.Interface.addonColor.."Settings:", size = 25, align = "Center"},
		{ type = 'spacer' },
			{ type = "spinner", text = "Change Pet at Health %:", key = "swapHealth", width = 70, min = 10, max = 100, default = 25, step = 1 },
			{ type = "checkbox", text = "Auto Trap", key = "trap", default = false },
			{ type = "checkbox", text = "Only use favorite pets", key = "favorites", default = false },
			{ type = "dropdown", text = "Team type:", key = "teamtype", list = {
				{ text = "Battle Team", key = "BattleTeam" },
				{ text = "Leveling Team", key = "LvlngTeam" },
			}, default = "BattleTeam" },
		{ type = 'rule' },{ type = 'spacer' },
		{ type = 'header', text = '|cff'..NeP.Interface.addonColor.."Status:", size = 25, align = "Center"},
		{ type = 'spacer' },
			-- Pet Slot 1
			{ type = "text", text = "|cff"..NeP.Interface.addonColor.."Pet in slot 1: ", size = 11, offset = -11 },
			{ key = 'petslot1', type = "text", text = "...", size = 11, align = "right", offset = 0 },
			-- Pet Slot 2
			{ type = "text", text = "|cff"..NeP.Interface.addonColor.."Pet in slot 2: ", size = 11, offset = -11 },
			{ key = 'petslot2', type = "text", text = "...", size = 11, align = "right", offset = 0 },
			-- Pet Slot 3
			{ type = "text", text = "|cff"..NeP.Interface.addonColor.."Pet in slot 3: ", size = 11, offset = -11 },
			{ key = 'petslot3', type = "text", text = "...", size = 11, align = "right", offset = 0 },
			{ type = 'spacer' },
			-- Last attack
			{ type = "text", text = "|cff"..NeP.Interface.addonColor.."Last Used Attack: ", size = 11, offset = -11 },
			{ key = 'lastAttack', type = "text", text = "...", size = 11, align = "right", offset = 0 },
		{ type = 'spacer' },{ type = 'rule' },{ type = 'spacer' },
			{ type = "button", text = "Start", width = 225, height = 20,callback = function(self, button)
					isRunning = not isRunning
					if isRunning then
						self:SetText("Stop")
					else
						self:SetText("Start")
					end
				end
			},
	}	
}

NeP.Interface.buildGUI(config)

local petBotGUI = NeP.Interface.getGUI('NePpetBot')
local maxPetLvl = 0

local function getPetHealth(owner, index)
	return math.floor((C_PB.GetHealth(owner, index) / C_PB.GetMaxHealth(owner, index)) * 100)
end

local function scanJournal()
	local petTable = {}
	local maxAmount, petAmount = C_PJ.GetNumPets()
	for i=1,petAmount do
		local guid, id, _, _, lvl, _ , _, name, icon = C_PJ.GetPetInfoByIndex(i)
		local health, maxHealth, attack, speed, rarity = C_PJ.GetPetStats(guid)
		local healthPercentage = math.floor((health / maxHealth) * 100)
		if healthPercentage > tonumber(Fetch('NePpetBot', 'swapHealth')) then
			petTable[#petTable+1]={
				guid = guid,
				lvl = lvl,
				attack = attack,
			}
		end
	end
	if petTable[1] ~= nil then
		if Fetch('NePpetBot', 'teamtype') == 'BattleTeam' then
			table.sort(petTable, function(a,b) return a.attack > b.attack end)
		else
			table.sort(petTable, function(a,b) return a.lvl > b.lvl end)
		end
		maxPetLvl = petTable[1].lvl
	end
	return petTable
end

local function scanLoadOut()
	local loadOut = {}
	for k=1,3 do
		local petID, petSpellID_slot1, petSpellID_slot2, petSpellID_slot3, locked = C_PJ.GetPetLoadOutInfo(k)
		local _,_, level, _,_,_,_, petName, petIcon, petType, _,_,_,_, canBattle = C_PJ.GetPetInfoByPetID(petID)
		local health, maxHealth, attack, speed, rarity = C_PJ.GetPetStats(petID)
		local healthPercentage = math.floor((health / maxHealth) * 100)
		loadOut[#loadOut+1] = {
			health = healthPercentage,
			level = level,
			id = petID,
			attack = attack
		}
	end
	return loadOut
end

local function buildBattleTeam()
	if Fetch('NePpetBot', 'teamtype') == 'BattleTeam' then
		local petTable = scanJournal()
		for i=1,#petTable do
			if #petTable > 0 and not C_PJ.PetIsSlotted(petTable[i].guid) then
				local loadOut = scanLoadOut()
				for k=1,#loadOut do
					if loadOut[k].level < maxPetLvl then
						if loadOut[k].level < maxPetLvl or loadOut[k].health < tonumber(Fetch('NePpetBot', 'swapHealth')) 
						or not C_PJ.PetIsFavorite(loadOut[k].id) and Fetch('NePpetBot', 'favorites')
						or loadOut[k].attack < petTable[i].attack then
							C_PJ.SetPetLoadOutInfo(k, petTable[i].guid)
							break
						end
					end
				end
			end
		end
	end
end

local function buildLevelingTeam()
	if Fetch('NePpetBot', 'teamtype') == 'LvlngTeam' then
		local petTable = scanJournal()
		for i=1,#petTable do
			if #petTable > 0 and not C_PJ.PetIsSlotted(petTable[i].guid) then
				local loadOut = scanLoadOut()
				for k=1,#loadOut do
					if loadOut[k].level >= maxPetLvl then
						if loadOut[k].level >= maxPetLvl or loadOut[k].health < tonumber(Fetch('NePpetBot', 'swapHealth')) 
						or not C_PJ.PetIsFavorite(loadOut[k].id) and Fetch('NePpetBot', 'favorites') then
							C_PJ.SetPetLoadOutInfo(k, petTable[i].guid)
							break
						end
					end
				end
			end
		end
	end
end

local function scanGroup()
	local petAmount = C_PB.GetNumPets(1)
	local goodPets = {}
	for k=1,petAmount do
		local health = getPetHealth(1, k)
		if health > tonumber(Fetch('NePpetBot', 'swapHealth')) then
			goodPets[#goodPets+1] = {
				id = k,
				health = health
			}
		end
	end
	table.sort(goodPets, function(a,b) return a.health > b.health end)
	return goodPets
end

local function PetSwap()
	local activePet = C_PB.GetActivePet(1)
	local goodPets = scanGroup()
	if #goodPets < 1 then
		C_PB.ForfeitGame()
	else
		for i=1,#goodPets do
			if getPetHealth(1, activePet) <= tonumber(Fetch('NePpetBot', 'swapHealth')) then
				C_PB.ChangePet(goodPets[i].id)
				break
			end
		end
	end
	return false
end

local function scanPetAbilitys()
	local Abilitys = {}
	local activePet = C_PB.GetActivePet(1)
	local enemieActivePet = C_PB.GetActivePet(2)
	for i=3,1,-1 do
		local isUsable, currentCooldown = C_PB.GetAbilityState(1, activePet, i)
		if isUsable then
			local id, name, icon, maxcooldown, desc, numTurns, abilityPetType, nostrongweak = C_PB.GetAbilityInfo(1, activePet, i)
			local enemieType = C_PB.GetPetType(2, enemieActivePet)
			local attackModifer = C_PB.GetAttackModifier(abilityPetType, enemieType)
			local power = C_PB.GetPower(1, activePet)
			local totalDmg = power*attackModifer
			Abilitys[#Abilitys+1]={
				dmg = totalDmg,
				name = name,
				icon = icon,
				id = i
			}
			--print(i..' '..totalDmg..'( '..power..' \ '..attackModifer..' \ '..numTurns..' )'..maxcooldown)
		end
	end
	table.sort(Abilitys, function(a,b) return a.dmg > b.dmg end)
	return Abilitys
end

local _lastAttack = '...'
local function PetAttack()
	local Abilitys = scanPetAbilitys()
	for i=1,#Abilitys do
		if #Abilitys > 1 and _lastAttack ~= Abilitys[i].name or #Abilitys <=1 then
			if Abilitys[i] ~= nil then
				_lastAttack = Abilitys[i].name
				petBotGUI.elements.lastAttack:SetText('|T'..Abilitys[i].icon..':10:10|t'..Abilitys[i].name)
				C_PB.UseAbility(Abilitys[i].id)
			end
		end
	end
	C_PB.SkipTurn()
end

C_Timer.NewTicker(0.5, (function()
	if petBotGUI.parent:IsShown() then
		local activePet = C_PB.GetActivePet(1)
		local enemieActivePet = C_PB.GetActivePet(2)
		
		-- Pet 1
		local petID, petSpellID_slot1, petSpellID_slot2, petSpellID_slot3, locked = C_PJ.GetPetLoadOutInfo(1)
		local _,_, level, _,_,_,_, petName, petIcon, petType, _,_,_,_, canBattle = C_PJ.GetPetInfoByPetID(petID)
		petBotGUI.elements.petslot1:SetText('|T'..petIcon..':10:10|t'..petName)

		-- Pet 2
		local petID, petSpellID_slot1, petSpellID_slot2, petSpellID_slot3, locked = C_PJ.GetPetLoadOutInfo(2)
		local _,_, level, _,_,_,_, petName, petIcon, petType, _,_,_,_, canBattle = C_PJ.GetPetInfoByPetID(petID)
		petBotGUI.elements.petslot2:SetText('|T'..petIcon..':10:10|t'..petName)

		-- Pet 3
		local petID, petSpellID_slot1, petSpellID_slot2, petSpellID_slot3, locked = C_PJ.GetPetLoadOutInfo(3)
		local _,_, level, _,_,_,_, petName, petIcon, petType, _,_,_,_, canBattle = C_PJ.GetPetInfoByPetID(petID)
		petBotGUI.elements.petslot3:SetText('|T'..petIcon..':10:10|t'..petName)

		if isRunning and not C_PB.IsWaitingOnOpponent() then
			if not C_PB.IsInBattle() then
				buildBattleTeam()
				buildLevelingTeam()
			else
				-- Trap
				if getPetHealth(2, enemieActivePet) <= 35 and Fetch('NePpetBot', 'trap') and C_PB.IsWildBattle() and C_PB.IsTrapAvailable() then
					C_PB.UseTrap()
				-- Swap
				elseif not PetSwap() then
					if C_PB.GetBattleState() == 3 then
						PetAttack()
					end
				end
			end
		end
	end
end), nil)