local n_name, pB = ...
pB.Version = 1

local config = {
	key = n_name,
	title = n_name,
	subtitle = 'Settings',
	width = 200,
	height = 500,
	config = {
		{ type = 'header', text = "Settings:", size = 25, align = "Center"},
		{ type = 'spacer' },
		{ type = "spinner", text = "Change Pet at Health %:", key = "swapHealth", min = 10, max = 100, default = 25, step = 1 },
		{ type = "checkbox", text = "Auto Trap", key = "trap", default = false },
		{ type = "checkbox", text = "Only use favorite pets", key = "favorites", default = false },
		{ type = "dropdown", text = "Team type:", key = "teamtype", list = {
			{ text = "Battle Team", key = "BattleTeam" },
			{ text = "Leveling Team", key = "LvlngTeam" },
		}, default = "BattleTeam" },
		{ type = 'rule' },{ type = 'spacer' },
		{ type = 'header', text = "Status:", size = 25, align = "Center"},
		{ type = 'spacer' },
		-- Pet Slot 1
		{ type = "text", text = "Pet in slot 1: ", size = 11, offset = -11 },
		{ key = 'petslot1', type = "text", text = "...", size = 11, align = "right", offset = 0 },
		-- Pet Slot 2
		{ type = "text", text = "Pet in slot 2: ", size = 11, offset = -11 },
		{ key = 'petslot2', type = "text", text = "...", size = 11, align = "right", offset = 0 },
		-- Pet Slot 3
		{ type = "text", text = "Pet in slot 3: ", size = 11, offset = -11 },
		{ key = 'petslot3', type = "text", text = "...", size = 11, align = "right", offset = 0 },
		{ type = 'spacer' },
		-- Last attack
		{ type = "text", text = "Last Used Attack: ", size = 11, offset = -11 },
		{ key = 'lastAttack', type = "text", text = "...", size = 11, align = "right", offset = 0 },
		{ type = 'spacer' },{ type = 'rule' },{ type = 'spacer' },
		{ type = "button", text = "Start", width = 225, height = 20, callback = function(self, button)
				isRunning = not isRunning
				self:SetText(isRunning and "Stop" or "Start")
			end
		},
	}	
}

-- Create the GUI and add it to NeP
pB.GUI = NeP.Interface:BuildGUI(config)
NeP.Interface:Add(n_name..' V:'..pB.Version, function() pB.GUI:Show() end)
pB.GUI:Hide()