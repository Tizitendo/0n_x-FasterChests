log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
params = {}
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()
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
local Teleporter = nil
local Director = nil
local Hud = nil
local FinishedTele = false
local TimeIncrease = true
local chests = {}
local index = 1

Initialize(function()
    -- set open delay on balanced
    Callback.add("onSecond", "FasterChests-onSecond", function()
        if Teleporter ~= nil and Teleporter.time >= Teleporter.maxtime then
            Teleporter = nil
            FinishedTele = true
            for i = 1, index do
                if chests[i].open_delay ~= nil then
                    chests[i].open_delay = 1.0
                end
            end
        end
    end)

    --Timeincrease is to only increase by one second every other chest
    Callback.add("onPlayerInit", "FasterChests-onPlayerInit", function()
        TimeIncrease = true
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
        Teleporter = nil;
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

gm.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
    if result.value.object_index == gm.constants.oDirectorControl then
        Director = result.value
    end
    if result.value.object_index == gm.constants.oHUD then
        Hud = result.value
    end
end)

gm.post_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
    -- get teleporter value
    if args[1].value.mountain ~= nil then
        Teleporter = args[1].value
    end

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

-- Add ImGui window
gui.add_to_menu_bar(function()
    params.Balanced = ImGui.Checkbox("Balanced mode", params.Balanced)
    Toml.save_cfg(_ENV["!guid"], params)
end)
