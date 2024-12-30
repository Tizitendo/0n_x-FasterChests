log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
params = {}
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
mods.on_all_mods_loaded(function()
    for k, v in pairs(mods) do
        if type(v) == "table" and v.tomlfuncs then
            Toml = v
        end
    end
    params = {
        Balanced = false
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

local Reset = false
local Director = nil
local Hud = nil
local FinishedTele = false
local TimeIncrease = true
local chests = {}
local index = 1
local Director = nil

Initialize(function()
    -- set open delay on balanced
    Callback.add("onSecond", "FasterChests-onSecond", function(arg1, arg2)
        if Director.teleporter_active > 1 and not FinishedTele then
            FinishedTele = true
            for i = 1, index do
                if chests[i] ~= nil and chests[i].open_delay ~= nil then
                    chests[i].open_delay = 1.0
                end
            end
        end
    end)

    -- TimeIncrease is to only increase by one second every other chest
    Callback.add("onGameStart", "FasterChests-onGameStart", function()
        local function GameStarted()
            TimeIncrease = true
            Director = GM._mod_game_getDirector()
            Hud = GM._mod_game_getHUD()
        end
        Alarm.create(GameStarted, 1)
    end)

    Callback.add("onStageStart", "FasterChests-onStageStart", function()
        local function ResetChestList()
            Reset = true
        end
        Alarm.create(ResetChestList, 10)
    end)
end)

gm.post_script_hook(gm.constants.interactable_init_cost, function(self, other, result, args)
    -- reset chest list
    if Reset then
        FinishedTele = false
        chests = {}
        index = 1
        Reset = false
    end

    -- get chests
    if args[1].value.open_delay ~= nil and args[1].value.open_delay > 1.0 then
        chests[index] = args[1].value
        if not params.Balanced then
            chests[index].open_delay = 1.0
        end
        index = index + 1
    end
end)

gm.post_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
    -- increase time
    if args[1].value.open_delay == 1.0 then
        if FinishedTele and params.Balanced then
            if TimeIncrease then
                Director.time_total = Director.time_total + 1
                Director.time_start = Director.time_start + 1
                Hud.second = Hud.second + 1
                TimeIncrease = false
            else
                TimeIncrease = true
            end
        end
    end
end)

-- Gui
gui.add_to_menu_bar(function()
    params.Balanced = ImGui.Checkbox("Balanced mode", params.Balanced)
    Toml.save_cfg(_ENV["!guid"], params)
end)
-- Add ImGui window
gui.add_imgui(function()
    if ImGui.Begin("Faster Chests") then
        params.Balanced = ImGui.Checkbox("Balanced mode", params.Balanced)
    Toml.save_cfg(_ENV["!guid"], params)
    end
    ImGui.End()
end)
