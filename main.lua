local api = require("api")

local bard_helper = {
  name = "Bard Helper",
  version = "0.2+",
  author = "Waifu + Psejik",
  desc = "Shows songs time remaining"
}

-- controls via chat:
-- "!bard_hold_on"
-- "!bard_hold_off"
-- "!bard_column"
-- "!bard_row"


--[[
	Сделано:
	- возможность двигать Canvas - есть (темный квадратик слева от иконок песен)
	- отображение в столбик или рядок

	Что еще нужно сделать:
	- автоматическое отображение прерывания песен при получении одного из списка дебафов (сон, стан, фир, пузырь...)

]]

local settings = {}
local Canvas
local delta_coord = 50

--[[
local function SaveSettings(hold)
  settings.HoldTheNote = hold
  api.Log:Info("Hold the Note set to " .. tostring(hold))
  api.SaveSettings()
end
]]

-- библиотека песен
local songsTimeRemains = {
  {
    title="Quickstep",
	songDuration = 15,
	--if settings.HoldTheNote then songDuration = 30 else songDuration = 15 end
    --buffId=803,
	skillId=10723,
    buffId=804,
    improvedBuffId=21444,
    --delta_coord=0,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  },
  {
    title="Bloody Chantey",
	songDuration = 15,
    --buffId=850,
	skillId=10727,
    buffId=7663,
    improvedBuffId=21446,
    --delta_coord=50,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  },
  {
    title="Bulwark Ballad",
	songDuration = 15,
    --buffId=1000,
	skillId=11396,
    buffId=4389,
    improvedBuffId=21447,
    --delta_coord=100,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  },
  {
    title="Ode to Recovery",
	songDuration = 15,
    --buffId=834,	-- Ode to Recovery (Rank 2)
	skillId=10724,
    buffId=835,
    improvedBuffId=21445,
    --delta_coord=150,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  },
  {
    title="Grief's Cadence",
	songDuration = 15,
    buffId=6830,
    --delta_coord=150,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  },
  

  {
	-- arg[3] arg[5]=id arg[6]=name
	-- arg = {1e057, "SPELL_CAST_START", "Psejik", "Psejik", 36628, "Alarm Call", "PHYSICAL", 7}
	-- arg = {1e057, "SPELL_CAST_SUCCESS", "Psejik", "Psejik", 36628, "Alarm Call", "PHYSICAL", 7}
	-- arg = {1e057, "SPELL_AURA_APPLIED", "Psejik", "Psejik", 21435, "Stone Alarm Call", "PHYSICAL", "BUFF", false, 9}
	-- arg = {1e057, "SPELL_AURA_REMOVED", "Psejik", "Psejik", 21435, "Stone Alarm Call", "PHYSICAL", "BUFF", true, 9}
    title="Alarm Call",
	songDuration = 15, --9 if Sleep
    buffId=2362,
    --delta_coord=150,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  },
  
  {
    title="Polymorphic Resonance",
	songDuration = 25,
    buffId=20473, --18506, -- or 20473
    --delta_coord=150,
    timeUsed=0,
    buffLostTime=0,
    icon=nil,
    label=nil
  },
}

-- вызывается с уже измененной длительностью
local function UpdateSongIcon(song, timeRemains)
  local pathToImage = api.Ability:GetBuffTooltip(song.buffId).path
  F_SLOT.SetIconBackGround(song.icon, pathToImage)

  song.label:SetText(tostring(timeRemains))
end


-- какая-то непонятная пока проверка (есть ли наложенный баф от умения перфоманса)
--local function checkPlayerHasBuff(buffName)
local function checkPlayerHasBuff(buffId, improvedBuffId)
    local buffCount = api.Unit:UnitBuffCount("player")

    if buffCount > 0 then
        for i = 1, buffCount do
			-- перебираем все бафы на игроке
            local buff = api.Unit:UnitBuff("player", i)
			
				--api.Log:Info("BuffId is " .. buff.buff_id)
				--api.Log:Info(buff) -- buff.path buff.stack buff.id buff.timeLeft

            if buff and buff.buff_id then
				--[[
                local buffTooltip = api.Ability:GetBuffTooltip(buff.buff_id)

                if string.find(buffTooltip.name, buffName) then
                  return true
                end
				]]

				
				if buff.buff_id == buffId or buff.buff_id == improvedBuffId then
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

-- отдельная функция чтобы переключать длительность песен от значения в настройках
local function getSongDuration()
  if settings.HoldTheNote then
    return 15
  end

  return 0
end


-- анализ сообщения боевого чата
--local function updateSongTimeUsed(casterName, skillName)
local function updateSongTimeUsed(casterName, skillId, skillName)

	local playerName = api.Unit:GetUnitNameById(api.Unit:GetUnitId("player"))

	-- отсеиваем сообщеия от других игроков
	if casterName ~= playerName then
		return
	end

	local currentTime = parseTime(api.Time.GetLocalTime())

	for i = 1, #songsTimeRemains do
		local song = songsTimeRemains[i]

		--if "[Perform] " .. song.title == skillName then
		if song.skillId == skillId then
			song.timeUsed = currentTime
			song.buffLostTime = 0
			song.icon:Show(true)
			song.label:Show(true)
			
			local duration = song.songDuration + getSongDuration()

			--if settings.HoldTheNote then duration = song.songDuration + 15 else duration = song.songDuration end

			--UpdateSongIcon(song, timeRemains)
			UpdateSongIcon(song, duration)
			
		elseif song.title == skillName then
			song.timeUsed = currentTime
			song.buffLostTime = 0
			song.icon:Show(true)
			song.label:Show(true)

			UpdateSongIcon(song, song.songDuration)
		
		end
	end

	-- добавить сюда как-то отметку про надевание акваланга
	-- в логе это Acquired: [Mistral Underwarer Breathing Device]
end


local function OnUpdate()
	local currentTime = parseTime(api.Time.GetLocalTime())

	for i = 1, #songsTimeRemains do
		local song = songsTimeRemains[i]

		if song.timeUsed > 0 then
			--local timeRemains = song.timeUsed + getSongDuration() - currentTime
			local timeRemains

			if song.buffId ==2362 or song.buffId ==20473 then
				timeRemains = song.timeUsed + song.songDuration - currentTime
			else
				timeRemains = song.timeUsed + song.songDuration + getSongDuration() - currentTime
			end

			if timeRemains > 0 then
			-- странное обнуление длительности если
				--if checkPlayerHasBuff(song.title) then
				if checkPlayerHasBuff(song.buffId, song.improvedBuffId) then
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

--[[
local function getColumnMode()
	if settings.column then
		return true
	end
	
	return false
end
]]

-- отрисовка иконок песен
local function createSongUI(i, settings, Canvas)
	local song = songsTimeRemains[i]

	song.icon = CreateItemIconButton("SongIcon_" .. song.buffId, Canvas)
	song.icon:Show(false)
	--song.icon:AddAnchor("TOPLEFT", Canvas, "TOPLEFT", -20 + song.y_coord, -20)
	
	--local column = settings.column -- or true
	--local column = getColumnMode()
	
	if settings.column then
		--debug
		--api.Log:Info("[BH debug: Column]")
		
		song.icon:AddAnchor("TOPLEFT", Canvas, "TOPLEFT", 20 , 0 + (i-1) * delta_coord)
	else
		--debug
		--api.Log:Info("[BH debug: Row]")
	
		song.icon:AddAnchor("TOPLEFT", Canvas, "TOPLEFT", 20 + (i-1) * delta_coord, 0)
	end

	F_SLOT.ApplySlotSkin(song.icon, song.icon.back, SLOT_STYLE.BUFF)

	song.label = Canvas:CreateChildWidget("label", "label_" .. song.buffId, 0, true)
	--song.label:AddAnchor("TOPLEFT", Canvas, "TOPLEFT", song.y_coord, 0)

	-- отрисовка таймера на песне
	if settings.column then
		song.label:AddAnchor("TOPLEFT", Canvas, "TOPLEFT", 40, 20 + (i-1) * delta_coord)
	else
		song.label:AddAnchor("TOPLEFT", Canvas, "TOPLEFT", 40 + (i-1) * delta_coord, 20)
	end
	
	song.label.style:SetFontSize(30)
	song.label.style:SetShadow(true)
	song.label:Show(false)
end

function CreateMainDisplay(settings)

	local canvas_x = settings.x or 1300
	local canvas_y = settings.y or 200
	
	Canvas = api.Interface:CreateEmptyWindow("BuffAlerterCanvas", "UIParent")

	Canvas:AddAnchor("TOPLEFT", "UIParent", canvas_x * api.Interface:GetUIScale(), canvas_y * api.Interface:GetUIScale())

	--[[
	if canvas_x ~= 100 and canvas_y ~= 0 then
		Canvas:AddAnchor("TOPLEFT", "UIParent", canvas_x * api.Interface:GetUIScale(), canvas_y * api.Interface:GetUIScale())
	else
		Canvas:AddAnchor("LEFT", "UIParent", canvas_x * api.Interface:GetUIScale(), canvas_y * api.Interface:GetUIScale())
	end
	]]
	
	
	Canvas.bg = Canvas:CreateNinePartDrawable(TEXTURE_PATH.HUD, "background")
	Canvas.bg:SetTextureInfo("bg_quest")
	Canvas.bg:SetColor(0, 0, 0, 0.5)
	Canvas.bg:AddAnchor("TOPLEFT", Canvas, 0, 0)
	--Canvas.bg:AddAnchor("BOTTOMRIGHT", Canvas, -10, 10)
	
	-- размеры темного пятнышка
	Canvas:SetExtent(25, 25)
	Canvas:Show(true)
	
    -- drag events for main window
    function Canvas:OnDragStart(arg)
        Canvas:StartMoving()
        api.Cursor:ClearCursor()
        api.Cursor:SetCursorImage(CURSOR_PATH.MOVE, 0, 0)
    end
    function Canvas:OnDragStop()
        Canvas:StopMovingOrSizing()
        local x, y = Canvas:GetEffectiveOffset()
        api.Cursor:ClearCursor()

	    settings.x = x
		settings.y = y
		api.SaveSettings()
    end


    Canvas:SetHandler("OnDragStart", Canvas.OnDragStart)
    Canvas:SetHandler("OnDragStop", Canvas.OnDragStop)
	
	
    if Canvas.RegisterForDrag ~= nil then
        Canvas:RegisterForDrag("LeftButton")
    end
    if Canvas.EnableDrag ~= nil then Canvas:EnableDrag(true) end
	
	
	Canvas:EnableDrag(true)
	
	-- изменение через чат: наличие пассивного таланта "Hold the Note"
	function Canvas:OnEvent(event, ...)
		if event == "COMBAT_MSG" then
			-- api.Log:Info(arg) -- просмотр детальной информации по активированному скиллу
			updateSongTimeUsed(arg[3], arg[5], arg[6]) --casterName, skillId, skillName
		end

		if event == "CHAT_MESSAGE" then
			if arg[5] == "!bard_hold_on" then
				--SaveSettings(true)
				settings.HoldTheNote = true
				api.Log:Info("[BardHelper] Hold the Note set to " .. tostring(settings.HoldTheNote))
				api.SaveSettings()
			  
			elseif arg[5] == "!bard_hold_off" then
				--SaveSettings(false)
				settings.HoldTheNote = false
				api.Log:Info("[BardHelper] Hold the Note set to " .. tostring(settings.HoldTheNote))
				api.SaveSettings()
				
			-- переключение режима отображения (столбик или рядок)
			elseif arg[5] == "!bard_column" then
				settings.column = true
				api.Log:Info("[BardHelper] column mode " .. tostring(settings.column))
				api.SaveSettings()

				-- перерисовка позиций для иконок
				for i = 1, #songsTimeRemains do
					-- тут нужно почистить от старых иконок иначе они остаются висеть навечно
					songsTimeRemains[i].icon:Show(false)
					songsTimeRemains[i].label:Show(false)
				
					--createSongUI(songsTimeRemains[i], settings, Canvas, i)
					createSongUI(i, settings, Canvas)
				end
			elseif arg[5] == "!bard_row" then
				settings.column = false
				api.Log:Info("[BardHelper] column mode " .. tostring(settings.column))
				api.SaveSettings()
				
				for i = 1, #songsTimeRemains do
					songsTimeRemains[i].icon:Show(false)
					songsTimeRemains[i].label:Show(false)
					createSongUI(i, settings, Canvas)
				end
			end
			
		end
	end
	
	
	for i = 1, #songsTimeRemains do
		--createSongUI(songsTimeRemains[i], settings, Canvas)
		createSongUI(i, settings, Canvas)
	end
	

end



-- START
local function OnLoad()
	settings = api.GetSettings("BardHelper")

	api.Log:Info("Loaded " .. bard_helper.name .. " v" ..
					 bard_helper.version .. " by " .. bard_helper.author)
	api.On("UPDATE", OnUpdate)


	
	CreateMainDisplay(settings)

	api.On("UPDATE", OnUpdate)
	Canvas:SetHandler("OnEvent", Canvas.OnEvent)
	Canvas:RegisterEvent("COMBAT_MSG")
	Canvas:RegisterEvent("CHAT_MESSAGE")
    --Canvas:SetHandler("OnDragStart", Canvas.OnDragStart)
    --Canvas:SetHandler("OnDragStop", Canvas.OnDragStop)
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
