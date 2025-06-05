local api = require("api")

local bard_helper = {
  name = "Bard Helper",
  version = "0.1",
  author = "Waifu",
  desc = "Shows songs time remaining"
}


local settings

local function SaveSettings(hold)
  settings.HoldTheNote = hold
  api.Log:Info("Hold the Note set to " .. tostring(hold))
  api.SaveSettings()
end


local songsTimeRemains = {
  {
    title="Quickstep",
    buffId=803,
    y_coord=0,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  },
  {
    title="Bloody Chantey",
    buffId=850,
    y_coord=50,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  },
  {
    title="Bulwark Ballad",
    buffId=1000,
    y_coord=100,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  },
  {
    title="Ode to Recovery",
    buffId=834,
    y_coord=150,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  }
}


Canvas = api.Interface:CreateEmptyWindow("BuffAlerterCanvas")
Canvas:Show(true)
Canvas:AddAnchor("CENTER", "UIParent", -100, -300)


local function createSongUI(song)
  song.icon = CreateItemIconButton("SongIcon_" .. song.buffId, Canvas)
  song.icon:Show(false)
  song.icon:AddAnchor("TOPLEFT", Canvas, "TOPLEFT", -20 + song.y_coord, -20)

  F_SLOT.ApplySlotSkin(song.icon, song.icon.back, SLOT_STYLE.BUFF)

  song.label = Canvas:CreateChildWidget("label", "label_" .. song.buffId, 0, true)
  song.label:AddAnchor("TOPLEFT", Canvas, "TOPLEFT", song.y_coord, 0)
  song.label.style:SetFontSize(30)
  song.label.style:SetShadow(true)
  song.label:Show(false)
end


local function UpdateSongIcon(song, timeRemains)
  local pathToImage = api.Ability:GetBuffTooltip(song.buffId).path
  F_SLOT.SetIconBackGround(song.icon, pathToImage)

  song.label:SetText(tostring(timeRemains))
end


local function checkPlayerHasBuff(buffName)
    local buffCount = api.Unit:UnitBuffCount("player")

    if buffCount > 0 then
        for i = 1, buffCount do
            local buff = api.Unit:UnitBuff("player", i)

            if buff and buff.buff_id then
                local buffTooltip = api.Ability:GetBuffTooltip(buff.buff_id)

                if string.find(buffTooltip.name, buffName) then
                  return true
                end
            end
        end
    end

    return false
end


local function parseTime(time)
  return tonumber(time:sub(8, 11))
end

local function getSongDuration()
  if settings.HoldTheNote then
    return 30
  end

  return 15
end


local function updateSongTimeUsed(casterName, skillName)
  local playerName = api.Unit:GetUnitNameById(api.Unit:GetUnitId("player"))

  if casterName ~= playerName then
    return
  end

  local currentTime = parseTime(api.Time.GetLocalTime())

  for i = 1, #songsTimeRemains do
    local song = songsTimeRemains[i]

    if "[Perform] " .. song.title == skillName then
      song.timeUsed = currentTime
      song.buffLostTime = 0
      song.icon:Show(true)
      song.label:Show(true)

      UpdateSongIcon(song, getSongDuration())
    end
  end
end


local function OnUpdate()
  local currentTime = parseTime(api.Time.GetLocalTime())

  for i = 1, #songsTimeRemains do
    local song = songsTimeRemains[i]

    if song.timeUsed > 0 then
      local timeRemains = song.timeUsed + getSongDuration() - currentTime

      if timeRemains > 0 then
        if checkPlayerHasBuff(song.title) then
          song.buffLostTime = 0
          UpdateSongIcon(song, timeRemains)
        else
          if song.buffLostTime == 0 then
            song.buffLostTime = currentTime
          elseif currentTime - song.buffLostTime > 1 then
            song.icon:Show(false)
            song.label:Show(false)
            song.timeUsed = 0
            song.buffLostTime = 0
          end
        end
      else
        song.icon:Show(false)
        song.label:Show(false)
      end
    end
  end
end


function Canvas:OnEvent(event, ...)
  if event == "COMBAT_MSG" then
    updateSongTimeUsed(arg[3], arg[6])
  end

  if event == "CHAT_MESSAGE" then
    if arg[5] == "!bard_hold_on" then
      SaveSettings(true)
    end

    if arg[5] == "!bard_hold_off" then
      SaveSettings(false)
    end
  end
end


local function OnLoad()
  settings = api.GetSettings("BardHelper")

  api.Log:Info("Bard Helper Initialized")

  for i = 1, #songsTimeRemains do
    createSongUI(songsTimeRemains[i])
  end

  api.On("UPDATE", OnUpdate)
  Canvas:SetHandler("OnEvent", Canvas.OnEvent)
  Canvas:RegisterEvent("COMBAT_MSG")
  Canvas:RegisterEvent("CHAT_MESSAGE")
end


local function OnUnload()
  if Canvas ~= nil then
    Canvas:Show(false)
    Canvas = nil
  end
end


bard_helper.OnLoad = OnLoad
bard_helper.OnUnload = OnUnload

return bard_helper
