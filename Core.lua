-- UI Scaler: per-window scale for Blizzard's default frames.
--
-- Each module lists every global frame name it might go by. Names differ
-- between client versions, so missing ones are simply skipped. Many of these
-- windows live in load-on-demand Blizzard addons and don't exist until first
-- opened, which is why we rescan on every ADDON_LOADED.

local ADDON, ns = ...

local bagFrames = { "ContainerFrameCombinedBags" }
for i = 1, 13 do bagFrames[#bagFrames + 1] = "ContainerFrame" .. i end

-- Icons are Blizzard's own, shipped with the client. Not every client has
-- every icon; Options.lua falls back to a question mark for missing ones.
ns.MODULES = {
    { key = "character",   name = "Character",      icon = "Interface\\Icons\\INV_Misc_Necklace_02",                  frames = { "CharacterFrame" } },
    { key = "bags",        name = "Bags",           icon = "Interface\\Icons\\INV_Misc_Bag_08",                       frames = bagFrames },
    { key = "map",         name = "World Map",      icon = "Interface\\Icons\\INV_Misc_Map_01",                       frames = { "WorldMapFrame" } },
    { key = "spellbook",   name = "Spellbook",      icon = "Interface\\Icons\\INV_Misc_Book_09",                      frames = { "SpellBookFrame", "PlayerSpellsFrame" } },
    { key = "talents",     name = "Talents",        icon = "Interface\\Icons\\Ability_Marksmanship",                  frames = { "PlayerTalentFrame", "ClassTalentFrame" } },
    { key = "questlog",    name = "Quest Log",      icon = "Interface\\Icons\\INV_Misc_QuestionMark",                 frames = { "QuestLogFrame" } },
    { key = "quest",       name = "Quest & Gossip", icon = "Interface\\Icons\\INV_Misc_Note_01",                      frames = { "QuestFrame", "GossipFrame" } },
    { key = "social",      name = "Social",         icon = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend", frames = { "FriendsFrame" } },
    { key = "guild",       name = "Guild",          icon = "Interface\\Icons\\Achievement_GuildPerk_MobileBanking",   frames = { "GuildFrame", "CommunitiesFrame" } },
    { key = "lfg",         name = "Group Finder",   icon = "Interface\\Icons\\INV_Misc_GroupLooking",                 frames = { "LFGParentFrame", "PVEFrame" } },
    { key = "merchant",    name = "Merchant",       icon = "Interface\\Icons\\INV_Misc_Coin_01",                      frames = { "MerchantFrame" } },
    { key = "bank",        name = "Bank",           icon = "Interface\\Icons\\INV_Misc_Coin_17",                      frames = { "BankFrame" } },
    { key = "mail",        name = "Mail",           icon = "Interface\\Icons\\INV_Letter_15",                         frames = { "MailFrame", "OpenMailFrame" } },
    { key = "auction",     name = "Auction House",  icon = "Interface\\Icons\\INV_Misc_AuctionHouse",                 frames = { "AuctionFrame", "AuctionHouseFrame" } },
    { key = "professions", name = "Professions",    icon = "Interface\\Icons\\Trade_BlackSmithing",                   frames = { "TradeSkillFrame", "CraftFrame", "ProfessionsFrame" } },
    { key = "trainer",     name = "Trainer",        icon = "Interface\\Icons\\Trade_Engraving",                       frames = { "ClassTrainerFrame" } },
    { key = "loot",        name = "Loot",           icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue",                  frames = { "LootFrame" } },
    { key = "dressup",     name = "Dressing Room",  icon = "Interface\\Icons\\INV_Chest_Cloth_17",                    frames = { "DressUpFrame" } },
    { key = "macros",      name = "Macros",         icon = "Interface\\Icons\\INV_Misc_Gear_01",                      frames = { "MacroFrame" } },
    { key = "gamemenu",    name = "Game Menu",      icon = "Interface\\Icons\\INV_Misc_Gear_08",                      frames = { "GameMenuFrame" } },
}

ns.MIN, ns.MAX = 0.5, 2.0

local db
local owner = {}      -- frame -> module key, for every frame we've hooked
local pending = {}    -- protected frames waiting for combat to end
local applying = false

local function apply(frame)
    local scale = db.scales[owner[frame]]
    if not scale then return end -- untouched: leave Blizzard's own scale alone
    if InCombatLockdown() and frame:IsProtected() then
        pending[frame] = true
        return
    end
    if math.abs(frame:GetScale() - scale) < 0.001 then return end
    applying = true
    frame:SetScale(scale)
    applying = false
end

local function hook(frame, key)
    if owner[frame] then return end
    owner[frame] = key
    -- Blizzard rescales some windows itself (bags fit themselves to screen
    -- height every time they open), so re-assert ours whenever that happens.
    hooksecurefunc(frame, "SetScale", function(self)
        if not applying then apply(self) end
    end)
    frame:HookScript("OnShow", apply)
    apply(frame)
end

local function scan()
    for _, m in ipairs(ns.MODULES) do
        for _, name in ipairs(m.frames) do
            local f = _G[name]
            if type(f) == "table" and f.SetScale and f.HookScript then
                hook(f, m.key)
            end
        end
    end
end

function ns.LoadedFrames(key)
    local list = {}
    for frame, k in pairs(owner) do
        if k == key then list[#list + 1] = frame end
    end
    return list
end

function ns.GetScale(key)
    return db.scales[key] or 1
end

function ns.SetScale(key, value)
    value = math.max(ns.MIN, math.min(ns.MAX, value))
    value = math.floor(value * 100 + 0.5) / 100
    if value == 1 then
        ns.Reset(key)
        return
    end
    db.scales[key] = value
    for _, f in ipairs(ns.LoadedFrames(key)) do apply(f) end
end

-- Forget the override and put the window back to 100%. Bags recompute their
-- own scale the next time they open.
function ns.Reset(key)
    db.scales[key] = nil
    for _, f in ipairs(ns.LoadedFrames(key)) do
        if not (InCombatLockdown() and f:IsProtected()) then
            applying = true
            f:SetScale(1)
            applying = false
        end
    end
end

function ns.ResetAll()
    for _, m in ipairs(ns.MODULES) do ns.Reset(m.key) end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, arg)
    if event == "ADDON_LOADED" and arg == ADDON then
        UIScalerDB = UIScalerDB or {}
        UIScalerDB.scales = UIScalerDB.scales or {}
        db = UIScalerDB
        scan()
    elseif event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
        if db then scan() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        for f in pairs(pending) do apply(f) end
        wipe(pending)
    end
end)
