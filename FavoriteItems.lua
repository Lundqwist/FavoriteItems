-- FavoriteItems
-- Mark items as favorites (a small heart in the icon's upper left corner) and
-- get a warning when a favorite item is sold to a merchant.
--
-- Works with Baganator (uses its corner-widget and region API) and falls back
-- to the default Blizzard bag and bank frames when Baganator isn't loaded.
-- Favorites are stored per item ID and shared by all characters on the account.

local ADDON_NAME = ...

local HEART = "Interface\\AddOns\\FavoriteItems\\Media\\Heart"
local HEART_INLINE = "|T" .. HEART .. ":14:14|t"
local COLOR = "|cffff6fa8"

local db
local markMode = false
local merchantOpen = false

local useBaganator = Baganator ~= nil and Baganator.API ~= nil

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(COLOR .. "FavoriteItems|r: " .. msg)
end

local function ItemIDFromLink(link)
  if type(link) ~= "string" then
    return nil
  end
  local id = link:match("item:(%d+)")
  return id and tonumber(id)
end

local function GetBagSlotItem(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info then
      return info.itemID, info.hyperlink
    end
    return nil
  end
  if GetContainerItemLink then
    local link = GetContainerItemLink(bag, slot)
    return ItemIDFromLink(link), link
  end
end

-------------------------------------------------------------------------------
-- Favorites storage
-------------------------------------------------------------------------------

local function IsFavorite(itemID)
  return itemID ~= nil and db ~= nil and db.items[itemID] ~= nil
end

local RefreshAllHearts -- defined further down

local function SetFavorite(itemID, link, on)
  if not itemID or not db then
    return
  end
  if on then
    db.items[itemID] = link or db.items[itemID] or true
  else
    db.items[itemID] = nil
  end
  RefreshAllHearts()
end

local function ToggleFavorite(itemID, link)
  if not itemID then
    return
  end
  local on = not IsFavorite(itemID)
  SetFavorite(itemID, link, on)
  local name = link or ("item " .. itemID)
  if on then
    Print(HEART_INLINE .. " " .. name .. " is now a favorite.")
  else
    Print(name .. " is no longer a favorite.")
  end
end

-- Small public API for other addons / macros.
FavoriteItems = {
  IsFavorite = IsFavorite,
  SetFavorite = function(itemID, on) SetFavorite(itemID, nil, on) end,
}

-------------------------------------------------------------------------------
-- Finding bag windows and item buttons
-------------------------------------------------------------------------------

local baganatorViews = {}   -- list of top-level Baganator bag/bank frames
local knownViews = {}

local OnContainerHidden -- defined further down
local CreateBankToggle  -- defined further down

local function FindBaganatorViews()
  if not useBaganator then
    return
  end
  for name, obj in pairs(_G) do
    if type(name) == "string" and type(obj) == "table" and not knownViews[obj]
      and name:find("^Baganator_") and (name:find("BackpackViewFrame") or name:find("BankViewFrame"))
      and obj.GetObjectType and obj.GetParent and obj:GetParent() == UIParent then
      knownViews[obj] = true
      local isBank = name:find("BankViewFrame") ~= nil
      table.insert(baganatorViews, obj)
      obj:HookScript("OnHide", OnContainerHidden)
      if isBank then
        CreateBankToggle(obj)
      end
    end
  end
end

local function BlizzardContainers()
  local list = {}
  for i = 1, (NUM_CONTAINER_FRAMES or 13) do
    local f = _G["ContainerFrame" .. i]
    if f then
      table.insert(list, f)
    end
  end
  if ContainerFrameCombinedBags then
    table.insert(list, ContainerFrameCombinedBags)
  end
  if BankFrame then
    table.insert(list, BankFrame)
  end
  return list
end

-- Bag and slot for a default Blizzard item button, or nil if it isn't one.
local function BlizzardBagSlot(button)
  local name = button.GetName and button:GetName()
  if name and name:match("^BankFrameItem%d+$") then
    return BANK_CONTAINER or -1, button:GetID()
  end
  if button.GetBagID and button.GetID then
    local ok, bag = pcall(button.GetBagID, button)
    if ok and bag then
      return bag, button:GetID()
    end
  end
  if name and name:match("^ContainerFrame%d+Item%d+$") then
    return button:GetParent():GetID(), button:GetID()
  end
end

local function GetButtonItem(button)
  if button.BGR then
    return button.BGR.itemID, button.BGR.itemLink
  end
  local bag, slot = BlizzardBagSlot(button)
  if bag and slot then
    return GetBagSlotItem(bag, slot)
  end
end

local function CollectBaganatorButtons(frame, out)
  for _, child in ipairs({ frame:GetChildren() }) do
    if child:IsVisible() then
      if child.BGR ~= nil then
        table.insert(out, child)
      else
        CollectBaganatorButtons(child, out)
      end
    end
  end
end

local function CollectBlizzardButtons(frame, out)
  for _, child in ipairs({ frame:GetChildren() }) do
    if child:IsVisible() then
      local objectType = child:GetObjectType()
      if (objectType == "Button" or objectType == "ItemButton") and BlizzardBagSlot(child) then
        table.insert(out, child)
      else
        CollectBlizzardButtons(child, out)
      end
    end
  end
end

local function VisibleContainers()
  local list = {}
  if useBaganator then
    for _, view in ipairs(baganatorViews) do
      if view:IsVisible() then
        table.insert(list, view)
      end
    end
  else
    for _, f in ipairs(BlizzardContainers()) do
      if f:IsVisible() then
        table.insert(list, f)
      end
    end
  end
  return list
end

local function CollectItemButtons()
  local buttons = {}
  for _, container in ipairs(VisibleContainers()) do
    if useBaganator then
      CollectBaganatorButtons(container, buttons)
    else
      CollectBlizzardButtons(container, buttons)
    end
  end
  return buttons
end

-------------------------------------------------------------------------------
-- Hearts
-------------------------------------------------------------------------------

-- Default Blizzard bags: our own heart texture on each item button.
local function UpdateBlizzardHearts()
  if useBaganator then
    return
  end
  for _, button in ipairs(CollectItemButtons()) do
    local itemID = GetButtonItem(button)
    local fav = IsFavorite(itemID)
    if fav and not button.FavoriteItemsHeart then
      local holder = CreateFrame("Frame", nil, button)
      holder:SetAllPoints(button)
      holder:SetFrameLevel(button:GetFrameLevel() + 5)
      local tex = holder:CreateTexture(nil, "OVERLAY")
      tex:SetTexture(HEART)
      tex:SetSize(14, 14)
      tex:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
      button.FavoriteItemsHeart = holder
    end
    if button.FavoriteItemsHeart then
      button.FavoriteItemsHeart:SetShown(fav)
    end
  end
end

local heartsQueued = false
function RefreshAllHearts()
  if useBaganator then
    Baganator.API.RequestItemButtonsRefresh()
  elseif not heartsQueued then
    heartsQueued = true
    C_Timer.After(0, function()
      heartsQueued = false
      UpdateBlizzardHearts()
    end)
  end
end

if useBaganator then
  Baganator.API.RegisterCornerWidget(
    "Favorite (heart)",
    "favoriteitems_heart",
    function(corner, details)
      -- Must return true/false; nil would mean "data not ready yet".
      return IsFavorite(details and details.itemID)
    end,
    function(itemButton)
      local frame = CreateFrame("Frame", nil, itemButton)
      frame:SetSize(14, 14)
      local tex = frame:CreateTexture(nil, "OVERLAY")
      tex:SetAllPoints()
      tex:SetTexture(HEART)
      frame.padding = 0
      return frame
    end,
    { corner = "top_left", priority = 1 },
    true
  )
end

-------------------------------------------------------------------------------
-- Mark mode: clickable layers on top of the item buttons
-------------------------------------------------------------------------------

local catchers = {}      -- item button -> catcher
local toggles = {}       -- all "Favorites" buttons
local ticker

local function ShowCatcherTooltip(catcher)
  local _, link = GetButtonItem(catcher.itemButton)
  if not link then
    return
  end
  GameTooltip:SetOwner(catcher, "ANCHOR_RIGHT")
  GameTooltip:SetHyperlink(link)
  GameTooltip:AddLine(" ")
  if IsFavorite(ItemIDFromLink(link)) then
    GameTooltip:AddLine(HEART_INLINE .. " Click to remove from favorites", 1, 0.44, 0.66)
  else
    GameTooltip:AddLine(HEART_INLINE .. " Click to mark as favorite", 1, 0.44, 0.66)
  end
  GameTooltip:Show()
end

local function GetCatcher(button)
  local catcher = catchers[button]
  if catcher then
    return catcher
  end
  catcher = CreateFrame("Button", nil, button)
  catcher.itemButton = button
  catcher:SetAllPoints(button)
  catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  local tint = catcher:CreateTexture(nil, "ARTWORK")
  tint:SetAllPoints()
  tint:SetColorTexture(1, 0.4, 0.7, 0.12)

  catcher:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

  catcher:SetScript("OnClick", function(self)
    local itemID, link = GetButtonItem(self.itemButton)
    if itemID then
      ToggleFavorite(itemID, link)
      if GameTooltip:IsOwned(self) then
        ShowCatcherTooltip(self)
      end
    end
  end)
  catcher:SetScript("OnEnter", ShowCatcherTooltip)
  catcher:SetScript("OnLeave", function() GameTooltip:Hide() end)

  catchers[button] = catcher
  return catcher
end

local function RefreshCatchers()
  local active = {}
  for _, button in ipairs(CollectItemButtons()) do
    local catcher = GetCatcher(button)
    catcher:SetFrameLevel(button:GetFrameLevel() + 20)
    catcher:Show()
    active[button] = true
  end
  for button, catcher in pairs(catchers) do
    if not active[button] then
      catcher:Hide()
    end
  end
end

local function UpdateToggles()
  for _, b in ipairs(toggles) do
    if markMode then
      b:SetText("|cff7fff7fDone|r")
      b:LockHighlight()
    else
      b:SetText(HEART_INLINE .. " Favorites")
      b:UnlockHighlight()
    end
  end
end

local function ExitMarkMode()
  if not markMode then
    return
  end
  markMode = false
  if ticker then
    ticker:Cancel()
    ticker = nil
  end
  for _, catcher in pairs(catchers) do
    catcher:Hide()
  end
  GameTooltip:Hide()
  UpdateToggles()
end

local function EnterMarkMode()
  if markMode then
    return
  end
  if InCombatLockdown() then
    Print("Can't mark favorites in combat.")
    return
  end
  FindBaganatorViews()
  if #VisibleContainers() == 0 then
    Print("Open your bags or bank first.")
    return
  end
  markMode = true
  RefreshCatchers()
  -- Bag contents and layouts change while open (looting, sorting, tabs), so
  -- keep the click layers in sync.
  ticker = C_Timer.NewTicker(0.25, function()
    if #VisibleContainers() == 0 then
      ExitMarkMode()
    else
      RefreshCatchers()
    end
  end)
  UpdateToggles()
  Print("Click items to mark or unmark them as favorites. Click " .. COLOR .. "Done|r when finished.")
end

local function ToggleMarkMode()
  if markMode then
    ExitMarkMode()
  else
    EnterMarkMode()
  end
end

function OnContainerHidden()
  C_Timer.After(0, function()
    if markMode and #VisibleContainers() == 0 then
      ExitMarkMode()
    end
  end)
end

-------------------------------------------------------------------------------
-- The "Favorites" buttons on the windows' lower side
-------------------------------------------------------------------------------

local function MakeToggle(parent)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(96, 22)
  b:SetScript("OnClick", ToggleMarkMode)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Favorite items")
    GameTooltip:AddLine("Click, then click items to mark or unmark them as favorites.", 1, 1, 1, true)
    GameTooltip:AddLine("You'll be warned if you sell a favorite.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  table.insert(toggles, b)
  UpdateToggles()
  return b
end

function CreateBankToggle(view)
  local b = MakeToggle(view)
  b:SetPoint("TOPLEFT", view, "BOTTOMLEFT", 4, -2)
end

if useBaganator then
  -- Baganator places registered regions in the backpack's bottom button row.
  Baganator.API.RegisterRegion("FavoriteItems", "favoriteitems", "backpack", "bottom_left", MakeToggle(UIParent))
end

local function CreateBlizzardToggles()
  if ContainerFrameCombinedBags then
    local b = MakeToggle(ContainerFrameCombinedBags)
    b:SetPoint("TOPRIGHT", ContainerFrameCombinedBags, "BOTTOMRIGHT", -4, -2)
  end
  if ContainerFrame1 then
    local b = MakeToggle(ContainerFrame1)
    b:SetPoint("TOPRIGHT", ContainerFrame1, "BOTTOMRIGHT", -4, -2)
  end
  if BankFrame then
    local b = MakeToggle(BankFrame)
    b:SetPoint("TOPLEFT", BankFrame, "BOTTOMLEFT", 4, -2)
  end
end

-------------------------------------------------------------------------------
-- Sold-favorite warning
-------------------------------------------------------------------------------

local pendingSold = {}   -- list of { id, link, count }
local warning

local function FindBuybackIndex(itemID)
  for i = GetNumBuybackItems(), 1, -1 do
    if ItemIDFromLink(GetBuybackItemLink(i)) == itemID then
      return i
    end
  end
end

local buybackQueue = {}
local function BuybackNext()
  if not merchantOpen then
    wipe(buybackQueue)
    return
  end
  local itemID = table.remove(buybackQueue, 1)
  if not itemID then
    return
  end
  local index = FindBuybackIndex(itemID)
  if index then
    BuybackItem(index)
  end
  -- One at a time: the buyback list shifts after each purchase.
  if #buybackQueue > 0 then
    C_Timer.After(0.5, BuybackNext)
  end
end

local function CreateWarning()
  local f = CreateFrame("Frame", "FavoriteItemsSoldWarning", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  f:SetSize(380, 160)
  f:SetPoint("TOP", UIParent, "TOP", 0, -150)
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetClampedToScreen(true)
  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
  end

  f.title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  f.title:SetPoint("TOP", 0, -20)
  f.title:SetText(HEART_INLINE .. "  You sold a favorite item!  " .. HEART_INLINE)

  f.body = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  f.body:SetPoint("TOP", f.title, "BOTTOM", 0, -12)
  f.body:SetWidth(330)
  f.body:SetJustifyH("CENTER")

  f.hint = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  f.hint:SetPoint("TOP", f.body, "BOTTOM", 0, -8)
  f.hint:SetWidth(330)

  f.buyback = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.buyback:SetSize(120, 24)
  f.buyback:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -6, 18)
  f.buyback:SetText("Buy back")
  f.buyback:SetScript("OnClick", function()
    wipe(buybackQueue)
    for _, entry in ipairs(pendingSold) do
      for _ = 1, entry.count do
        table.insert(buybackQueue, entry.id)
      end
    end
    BuybackNext()
    f:Hide()
  end)

  f.ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.ok:SetSize(120, 24)
  f.ok:SetPoint("BOTTOMLEFT", f, "BOTTOM", 6, 18)
  f.ok:SetText("Keep it sold")
  f.ok:SetScript("OnClick", function() f:Hide() end)

  f:SetScript("OnHide", function() wipe(pendingSold) end)
  table.insert(UISpecialFrames, "FavoriteItemsSoldWarning")
  f:Hide()
  return f
end

local function UpdateWarning()
  warning = warning or CreateWarning()
  local lines = {}
  for _, entry in ipairs(pendingSold) do
    local name = entry.link or ("item " .. entry.id)
    if entry.count > 1 then
      name = name .. " x" .. entry.count
    end
    table.insert(lines, name)
  end
  warning.body:SetText(table.concat(lines, "\n"))
  if merchantOpen then
    warning.buyback:Enable()
    warning.hint:SetText("You can still buy it back from this merchant's Buyback tab.")
  else
    warning.buyback:Disable()
    warning.hint:SetText("The merchant window is closed, so it can't be bought back here.")
  end
  warning:SetHeight(110 + warning.body:GetStringHeight() + warning.hint:GetStringHeight())
  warning:Show()
end

local function WarnSold(itemID, link, count)
  for _, entry in ipairs(pendingSold) do
    if entry.id == itemID then
      entry.count = entry.count + count
      UpdateWarning()
      return
    end
  end
  table.insert(pendingSold, { id = itemID, link = link, count = count })
  UpdateWarning()

  local name = link or ("item " .. itemID)
  Print("|cffff4040Warning:|r you sold your favorite item " .. name .. "!")
  if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] then
    RaidNotice_AddMessage(RaidWarningFrame, HEART_INLINE .. " Favorite item sold: " .. name, ChatTypeInfo["RAID_WARNING"])
  end
  PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
end

-- Selling is detected through the merchant's buyback list: every sale (right
-- click, drag to the merchant, Baganator's junk seller...) ends up there.
local buybackSnapshot

local function SnapshotBuyback()
  local counts, links = {}, {}
  for i = 1, GetNumBuybackItems() do
    local link = GetBuybackItemLink(i)
    local id = ItemIDFromLink(link)
    if id then
      counts[id] = (counts[id] or 0) + 1
      links[id] = link
    end
  end
  return counts, links
end

local function CheckBuyback()
  if not merchantOpen or not buybackSnapshot then
    return
  end
  local counts, links = SnapshotBuyback()
  for id, count in pairs(counts) do
    local before = buybackSnapshot[id] or 0
    if count > before and IsFavorite(id) then
      WarnSold(id, links[id], count - before)
    end
  end
  buybackSnapshot = counts
end

-------------------------------------------------------------------------------
-- Tooltip line
-------------------------------------------------------------------------------

local function AddTooltipLine(tooltip, itemID)
  if IsFavorite(itemID) and not tooltip.FavoriteItemsLineAdded then
    tooltip.FavoriteItemsLineAdded = true
    tooltip:AddLine(HEART_INLINE .. " Favorite", 1, 0.44, 0.66)
  end
end

local function HookTooltips()
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if tooltip == GameTooltip or tooltip == ItemRefTooltip then
        AddTooltipLine(tooltip, data and data.id)
      end
    end)
  else
    for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
      tt:HookScript("OnTooltipSetItem", function(self)
        local _, link = self:GetItem()
        AddTooltipLine(self, ItemIDFromLink(link))
      end)
    end
  end
  for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
    tt:HookScript("OnTooltipCleared", function(self) self.FavoriteItemsLineAdded = nil end)
  end
end

-------------------------------------------------------------------------------
-- Slash command
-------------------------------------------------------------------------------

SLASH_FAVORITEITEMS1 = "/fav"
SLASH_FAVORITEITEMS2 = "/favorites"
SlashCmdList.FAVORITEITEMS = function(msg)
  msg = strtrim((msg or ""):lower())
  if msg == "list" then
    local n = 0
    for id, link in pairs(db.items) do
      n = n + 1
      Print(HEART_INLINE .. " " .. (type(link) == "string" and link or ("item " .. id)))
    end
    if n == 0 then
      Print("No favorites yet.")
    end
  elseif msg == "help" then
    Print("/fav - start or stop marking favorites (opens your bags)")
    Print("/fav list - list all favorites")
  else
    if markMode then
      ExitMarkMode()
    else
      if #VisibleContainers() == 0 then
        OpenAllBags()
        C_Timer.After(0.1, EnterMarkMode)
      else
        EnterMarkMode()
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_CLOSED")
events:RegisterEvent("MERCHANT_UPDATE")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("BANKFRAME_OPENED")
events:RegisterEvent("PLAYERBANKSLOTS_CHANGED")

events:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    FavoriteItemsDB = FavoriteItemsDB or {}
    FavoriteItemsDB.items = FavoriteItemsDB.items or {}
    db = FavoriteItemsDB
  elseif event == "PLAYER_LOGIN" then
    HookTooltips()
    if useBaganator then
      FindBaganatorViews()
      -- Baganator may build some views late; look again shortly after login.
      C_Timer.After(2, FindBaganatorViews)
    else
      CreateBlizzardToggles()
      for _, f in ipairs(BlizzardContainers()) do
        f:HookScript("OnShow", RefreshAllHearts)
        f:HookScript("OnHide", OnContainerHidden)
      end
      if ContainerFrame_Update then
        hooksecurefunc("ContainerFrame_Update", RefreshAllHearts)
      end
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    ExitMarkMode()
  elseif event == "MERCHANT_SHOW" then
    merchantOpen = true
    buybackSnapshot = SnapshotBuyback()
  elseif event == "MERCHANT_CLOSED" then
    merchantOpen = false
    buybackSnapshot = nil
    if warning and warning:IsShown() then
      UpdateWarning()
    end
  elseif event == "MERCHANT_UPDATE" then
    CheckBuyback()
  elseif event == "BAG_UPDATE_DELAYED" then
    CheckBuyback()
    -- Baganator refreshes its own corner widgets when items move.
    if not useBaganator then
      RefreshAllHearts()
    end
  elseif event == "BANKFRAME_OPENED" then
    if useBaganator then
      FindBaganatorViews()
    else
      RefreshAllHearts()
    end
  elseif event == "PLAYERBANKSLOTS_CHANGED" then
    if not useBaganator then
      RefreshAllHearts()
    end
  end
end)
