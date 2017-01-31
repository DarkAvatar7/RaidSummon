local RaidSummonOptions_DefaultSettings = {
	whisper = true,
	zone = true
}

local function RaidSummon_Initialize()
	if not RaidSummonOptions  then
		RaidSummonOptions = {};
	end

	for i in RaidSummonOptions_DefaultSettings do
		if (not RaidSummonOptions[i]) then
			RaidSummonOptions[i] = RaidSummonOptions_DefaultSettings[i];
		end
	end
end

function RaidSummon_EventFrame_OnLoad()

	DEFAULT_CHAT_FRAME:AddMessage(string.format("RaidSummon version %s by %s", GetAddOnMetadata("RaidSummon", "Version"), GetAddOnMetadata("RaidSummon", "Author")));
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("CHAT_MSG_ADDON")
    this:RegisterEvent("CHAT_MSG_RAID")
	this:RegisterEvent("CHAT_MSG_RAID_LEADER")
    this:RegisterEvent("CHAT_MSG_SAY")
    this:RegisterEvent("CHAT_MSG_YELL")
    
	SlashCmdList["RAIDSUMMON"] = RaidSummon_SlashCommand;
	SLASH_RAIDSUMMON1 = "/raidsummon";
	SLASH_RAIDSUMMON2 = "/rs";
	
	MSG_PREFIX_ADD	= "RSAdd"
	MSG_PREFIX_REMOVE	= "RSRemove"
	RaidSummonDB = {}
	
end

function RaidSummon_EventFrame_OnEvent()

	if event == "VARIABLES_LOADED" then
		this:UnregisterEvent("VARIABLES_LOADED");
		RaidSummon_Initialize();

	elseif event == "CHAT_MSG_SAY" or event == "CHAT_MSG_RAID"  or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_YELL" then
		if string.find(arg1, "123") then
			SendAddonMessage(MSG_PREFIX_ADD, arg2, "RAID")
		end
	elseif event == "CHAT_MSG_ADDON" then
		if arg1 == MSG_PREFIX_ADD then
			if not RaidSummon_hasValue(RaidSummonDB, arg2) then
				table.insert(RaidSummonDB, arg2)
				RaidSummon_UpdateList()
			end
		elseif arg1 == MSG_PREFIX_REMOVE then
			if RaidSummon_hasValue(RaidSummonDB, arg2) then
				for i, v in ipairs (RaidSummonDB) do
					if v == arg2 then
						table.remove(RaidSummonDB, i)
						RaidSummon_UpdateList()
					end
				end
			end
		end
	end
end

function RaidSummon_hasValue (tab, val)
    for i, v in ipairs (tab) do
        if v == val then
            return true
        end
    end
    return false
end


--GUI
function RaidSummon_NameListButton_OnClick(button)

	local name = getglobal(this:GetName().."TextName"):GetText();

	if button == "LeftButton" then
	
		RaidSummon_getRaidMembers()
		
		for i, v in ipairs (RaidSummon_UnitIDDB) do
			if v.rName == name then
				UnitID = "raid"..v.rIndex
			end
		end
		
		if UnitID then
			TargetUnit(UnitID)
			CastSpellByName("Ritual of Summoning")
			
			
			if RaidSummonOptions.zone and RaidSummonOptions.whisper then
				SendChatMessage("RS - Summoning ".. name .. " to "..GetZoneText() .. " - " .. GetSubZoneText(), "RAID")
				SendChatMessage("RS - Summoning you to "..GetZoneText() .. " - " .. GetSubZoneText(), "WHISPER", nil, name)
			elseif RaidSummonOptions.zone and not RaidSummonOptions.whisper  then
				SendChatMessage("RS - Summoning ".. name .. " to "..GetZoneText() .. " - " .. GetSubZoneText(), "RAID")
			elseif not RaidSummonOptions.zone and RaidSummonOptions.whisper then
				SendChatMessage("RS - Summoning ".. name, "RAID")
				SendChatMessage("RS - Summoning you", "WHISPER", nil, name)
			elseif not RaidSummonOptions.zone and not RaidSummonOptions.whisper then
				SendChatMessage("RS - Summoning ".. name, "RAID")
			end
			for i, v in ipairs (RaidSummonDB) do
				if v == name then
					SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
				end
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - Player " .. tostring(name) .. " not found in raid. UnitID: " .. tostring(UnitID))
		end
		
	elseif button == "RightButton" then
		for i, v in ipairs (RaidSummonDB) do
			if v == name then
				SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
			end
		end
	end
			
	RaidSummon_UpdateList()
end

function RaidSummon_getRaidMembers()
    local raidnum = GetNumRaidMembers();

    if ( raidnum > 0 ) then
	RaidSummon_UnitIDDB = {}; 

	for i = 1, raidnum do
	    local rName = GetRaidRosterInfo(i);

		RaidSummon_UnitIDDB[i] = {};
		if (not rName) then 
		    rName = "unknown"..i;
		end
		
		RaidSummon_UnitIDDB[i].rName    = rName;
		RaidSummon_UnitIDDB[i].rIndex   = i; 
		
	    end
	end
end

function RaidSummon_UpdateList()
	for i=1,10 do
		if RaidSummonDB[i] then
			getglobal("RaidSummon_NameList"..i.."TextName"):SetText(RaidSummonDB[i])
			getglobal("RaidSummon_NameList"..i):Show()
		else
			getglobal("RaidSummon_NameList"..i):Hide()
		end
	end
	
	if not RaidSummonDB[1] then
		if RaidSummon_RequestFrame:IsVisible() then
			RaidSummon_RequestFrame:Hide()
		end
	else
		ShowUIPanel(RaidSummon_RequestFrame, 1)
	end
end

--Slash Handler
function RaidSummon_SlashCommand( msg )

	if msg == "help" then
		DEFAULT_CHAT_FRAME:AddMessage("RaidSummon usage:")
		DEFAULT_CHAT_FRAME:AddMessage("/rs or /raidsummon { help | show | zone | whisper }")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9help|r: prints out this help")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9show|r: shows the current summon list")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9zone|r: toggles zoneinfo in /ra and /w")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9whisper|r: toggles the usage of /w")
		DEFAULT_CHAT_FRAME:AddMessage("To drag the frame use shift + left mouse button")
	elseif msg == "show" then
		for i, v in ipairs(RaidSummonDB) do
			DEFAULT_CHAT_FRAME:AddMessage(tostring(v))
		end
	elseif msg == "zone" then
		if RaidSummonOptions["zone"] == true then
			RaidSummonOptions["zone"] = false
			DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - zoneinfo: |cffff0000disabled|r")
		elseif RaidSummonOptions["zone"] == false then
			RaidSummonOptions["zone"] = true
			DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - zoneinfo: |cff00ff00enabled|r")
		end
	elseif msg == "whisper" then
		if RaidSummonOptions["whisper"] == true then
			RaidSummonOptions["whisper"] = false
			DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - whisper: |cffff0000disabled|r")
		elseif RaidSummonOptions["whisper"] == false then
			RaidSummonOptions["whisper"] = true
			DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - whisper: |cff00ff00enabled|r")
		end
	else
	
		if RaidSummon_RequestFrame:IsVisible() then
			RaidSummon_RequestFrame:Hide()
		else
			RaidSummon_UpdateList()
			ShowUIPanel(RaidSummon_RequestFrame, 1)
		end
	
	end
	
end