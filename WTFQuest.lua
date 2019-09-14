local Name,AddOn=...;

function WTFPrint(msg, r, g, b)
    DEFAULT_CHAT_FRAME:AddMessage(msg, r, g, b)
end

function PrintAbandoned()
    WTFPrint("Abandoned quests: " .. table.concat(WTFQuestsAbandoned['quests'], ", "))
end

function findAbandonedQuest(questID)
    for index, value in pairs(WTFQuestsAbandoned["quests"]) do
        if value == questID then
            return index
        end
    end

    return nil
end

function isQuestAbandoned(questID)
    local res = findAbandonedQuest(questID)

    return res ~= nil
end

function addAbandonedQuest(questID)
    if isQuestAbandoned(questID) then return; end

    table.insert(WTFQuestsAbandoned["quests"], questID)
end

function removeAbandonedQuest(questID)
    while(true) do
        local index = findAbandonedQuest(questID)
        if index == nil then return; end

        table.remove(WTFQuestsAbandoned["quests"], index)
    end
end

function displayQuestInfo()
    if (MkQL_SetQuest ~= nil) then
        if (MkQL_Main_Frame:IsVisible()) then
            if (MkQL_global_iCurrQuest == self.m_iQuestIndex) then
                MkQL_Main_Frame:Hide();
            return;
            end
        end
        MkQL_SetQuest(self.m_iQuestIndex);
        return;
    end
end

function saveCurrentQuestsToDb()
    local i = 1
    while GetQuestLogTitle(i) do
        local title, level, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
            if not isHeader then
                storeQuestInfo(i)
            end
        i = i + 1
    end
end

function storeQuestValue(questID, name, value)
    if not WTFQuestsAbandoned["quest_cache"] then WTFQuestsAbandoned["quest_cache"] = {}; end
    if not WTFQuestsAbandoned["quest_cache"][questID] then WTFQuestsAbandoned["quest_cache"][questID] = {}; end
    WTFQuestsAbandoned["quest_cache"][questID][name] = value;
end

function newOnEnter(self)
    if ( self:GetAlpha() > 0 ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        
        -- Remember the currently selected quest log entry, just to play nice
        local tmpQuestLogSelection = GetQuestLogSelection();
        
        SelectQuestLogEntry(MkQL_global_iCurrQuest);
        
        if ( self.rewardType == "item" ) then
            if (self:GetID() > 0) then
                GameTooltip:SetQuestLogItem(self.type, self:GetID());
            else
                GameTooltip:SetHyperlink('item:' .. (-self:GetID()));
            end
        elseif ( self.rewardType == "spell" ) then
            if self:GetID() > 0 then
                GameTooltip:SetQuestLogRewardSpell();
            else
                GameTooltip:SetHyperlink('spell:' .. (-self:GetID()));
            end
        end
        
        -- Restore the current quest log selection
        SelectQuestLogEntry(tmpQuestLogSelection);
    end
    CursorUpdate(self);
end

function displayQuestInfo(questID)
    if not WTFQuestsAbandoned["quest_cache"][questID] then
        WTFPrint("Quest " .. questID .. " not found in DB")
        return
    end

    questInfo = WTFQuestsAbandoned["quest_cache"][questID]

    -- show the main frame
	MkQL_Main_Frame:Show();

	-- Get the quest title info
	local strQuestLogTitleText = questInfo["title"];

	--MkQL_global_iCurrQuest = iQuestNum;
	
	local strQuestDescription, strQuestObjectives = questInfo['description'], questInfo['objectives'];
	
	local strOverview = strQuestObjectives;

	-- Set the quest tag
    MkQL_QuestTitle_Txt:SetText(strQuestLogTitleText);
	
	if (strOverview ~= nil) then
		strOverview = MkQL_HighlightText(strOverview);
	else
		MkQL_Main_Frame:Hide(); return
	end
	
	if (questInfo['num_leaderboards'] > 0) then
		strOverview = strOverview .. "\n\n";

		for i=1, questInfo['num_leaderboards'], 1 do
			local strLeaderBoardText = questInfo["leaderboard_texts"][i];

			if (strLeaderBoardText) then
				strOverview = strOverview .. "  " .. MonkeyQuest_GetLeaderboardColorStr(strLeaderBoardText) ..
					strLeaderBoardText .. "\n";
			end
		end
	end

	MkQL_Overview_Txt:SetText(strOverview);
	MkQL_Desc_Txt:SetText(MONKEYQUESTLOG_DESC_HEADER);
	if (strQuestDescription ~= nil) then
		MkQL_DescBody_Txt:SetText(MkQL_HighlightText(strQuestDescription));
	else
		MkQL_Main_Frame:Hide(); return
	end
	MkQL_UpdateSize();

	-- REWARDS
	local numQuestRewards = questInfo['num_rewards'];
	local numQuestChoices = questInfo['num_choices'];
	local rewardMoney = questInfo['reward_money'];
	local name, texture, numItems, quality, isUsable = 1;
	local numTotalRewards = numQuestRewards + numQuestChoices;
	local rewardXP = 0
	
    local rewardItem = nil;

	if (numTotalRewards == 0 and rewardMoney == 0 and rewardXP == 0) then
		MkQL_Rewards_Txt:SetText("");
		MkQL_local_iExtraHeight = 0;
	else
		MkQL_Rewards_Txt:SetText(MONKEYQUESTLOG_REWARDS_HEADER);
		MkQL_local_iExtraHeight = 16;
	end

    -- first erase the reward items
	for i=1, MkQL_MAX_REWARDS, 1 do
		rewardItem = getglobal("MkQL_RewardItem"..i.."_Btn");

        if (rewardItem ~= nil) then
            rewardItem:SetScript("OnEnter", newOnEnter)
			rewardItem:Hide();
		end
	end

	if (numQuestChoices > 0) then
		MkQL_RewardsChoose_Txt:SetText(MkQL_REWARDSCHOOSE_TXT);
		
		-- anchor the reward items
		MkQL_RewardItem1_Btn:SetPoint("TOPLEFT", "MkQL_RewardsChoose_Btn", "BOTTOMLEFT", 0, -4);
		MkQL_local_iExtraHeight = MkQL_local_iExtraHeight + 4;
		
	else
		MkQL_RewardsChoose_Txt:SetText("");
	end

	-- blah blah do the choices
	for i=1, numQuestChoices, 1 do
		
		rewardItem = getglobal("MkQL_RewardItem"..(i).."_Btn");
		rewardItem.type = "choice";
        numItems = 1;
        local choice = questInfo['choices'][i];
		name, texture, numItems, quality, isUsable = choice['name'], choice['texture'], choice['num_items'], choice['quality'], choice['is_usable'];

		rewardItem:SetID(-choice['item_id'])
		rewardItem:Show();
		-- For the tooltip
		rewardItem.rewardType = "item";
		SetItemButtonCount(rewardItem, numItems);
		SetItemButtonTexture(rewardItem, texture);
		if ( isUsable ) then
			SetItemButtonTextureVertexColor(rewardItem, 1.0, 1.0, 1.0);
		else
			SetItemButtonTextureVertexColor(rewardItem, 0.5, 0, 0);
		end

		rewardItem:ClearAllPoints();
		
		if (i > 1) then
			rewardItem:SetPoint("TOPLEFT", "MkQL_RewardItem"..(i - 1).."_Btn", "TOPRIGHT", 4, 0);
		else
			rewardItem:SetPoint("TOPLEFT", "MkQL_RewardsChoose_Btn", "BOTTOMLEFT", 0, -10);
		end
	end
	
	
	-- do the rewards
	if (numQuestRewards > 0 or rewardMoney ~= 0 or rewardXP ~= 0) then
		if (rewardXP == 0) then
			MkQL_RewardsReceive_Txt:SetText(MkQL_REWARDSRECEIVE_TXT);
		else
			MkQL_RewardsReceive_Txt:SetText(MkQL_REWARDSRECEIVE_TXT .. "\n\n" ..rewardXP .. " XP");
		end
		if (numQuestChoices > 0) then
			-- re anchor
			MkQL_RewardsReceive_Btn:SetPoint("TOPLEFT", "MkQL_RewardItem1_Btn", "BOTTOMLEFT", 0, -15);
		else
			MkQL_RewardsReceive_Btn:SetPoint("TOPLEFT", "MkQL_Rewards_Btn", "BOTTOMLEFT", 0, -4);
		end

		MkQL_local_iExtraHeight = MkQL_local_iExtraHeight + 8;
	else
		MkQL_RewardsReceive_Txt:SetText("");
	end
	

	for i=1, numQuestRewards, 1 do
		rewardItem = getglobal("MkQL_RewardItem"..(i + numQuestChoices).."_Btn");
		rewardItem.type = "reward";
        numItems = 1;
        local reward = questInfo['rewards'][i]
		name, texture, numItems, quality, isUsable = reward['name'], reward['texture'], reward['num_items'], reward['quality'], reward['is_usable'];

		rewardItem:SetID(-reward['item_id'])
		rewardItem:Show();
		-- For the tooltip
		rewardItem.rewardType = "item";
		SetItemButtonCount(rewardItem, numItems);
		SetItemButtonTexture(rewardItem, texture);
		if ( isUsable ) then
			SetItemButtonTextureVertexColor(rewardItem, 1.0, 1.0, 1.0);
		else
			SetItemButtonTextureVertexColor(rewardItem, 0.5, 0, 0);
		end

		rewardItem:ClearAllPoints();
		
		if (i > 1) then
			rewardItem:SetPoint("TOPLEFT", "MkQL_RewardItem"..(i + numQuestChoices - 1).."_Btn", "TOPRIGHT", 4, 0);
		else
			rewardItem:SetPoint("TOPLEFT", "MkQL_RewardsReceive_Btn", "BOTTOMLEFT", 0, -4);
		end
		
		MonkeyLib_DebugMsg("Quest rewards loop!");
	end

	if (rewardMoney == 0) then
		MkQL_RewardMoney_Frame:Hide();
	else
		-- the money
		MkQL_RewardMoney_Frame:Show();
		MoneyFrame_Update("MkQL_RewardMoney_Frame", rewardMoney);
		
		MkQL_RewardMoney_Frame:ClearAllPoints();
		
		if (numQuestRewards > 0) then
			MkQL_RewardMoney_Frame:SetPoint("TOPLEFT", "MkQL_RewardItem"..(1 + numQuestChoices).."_Btn", "BOTTOMLEFT", 0, -4);
		else
			MkQL_RewardMoney_Frame:SetPoint("TOPLEFT", "MkQL_RewardsReceive_Btn", "BOTTOMLEFT", 0, -3);
		end
		
		MkQL_local_iExtraHeight = MkQL_local_iExtraHeight + 4;
	end
	
	-- share button
	-- Determine whether the selected quest is pushable or not
	if GetQuestLogPushable() then
		MkQL_ShareQuest_Btn:Disable();
    else
        MkQL_ShareQuest_Btn:Hide();
    end

    MkQL_AbandonQuest_Btn:Hide();
	
	MkQL_UpdateSize();
end

function storeQuestInfo(questIndex)
    -- Get the quest title info
    local strQuestLogTitleText, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(questIndex);
    if isHeader then return; end

    WTFPrint("Title: " .. strQuestLogTitleText)

    storeQuestValue(questID, 'title', strQuestLogTitleText);

    -- Remember the currently selected quest log entry, just to play nice
    local tmpQuestLogSelection = GetQuestLogSelection();
    SelectQuestLogEntry(questIndex);

    local strQuestDescription, strQuestObjectives = GetQuestLogQuestText();
    storeQuestValue(questID, 'description', strQuestDescription);
    storeQuestValue(questID, 'objectives', strQuestObjectives);
    storeQuestValue(questID, 'num_leaderboards', GetNumQuestLeaderBoards());

    local leaderboardTexts = {}

    if (GetNumQuestLeaderBoards() > 0) then
		for i=1, GetNumQuestLeaderBoards(), 1 do
			local strLeaderBoardText, _, _ = GetQuestLogLeaderBoard(i);
            leaderboardTexts[i] = strLeaderBoardText;
		end
    end
    storeQuestValue(questID, 'leaderboard_texts', leaderboardTexts)

    local numQuestRewards = GetNumQuestLogRewards();
    storeQuestValue(questID, 'num_rewards', numQuestRewards)
    local numQuestChoices = GetNumQuestLogChoices();
    storeQuestValue(questID, 'num_choices', numQuestChoices)
    local rewardMoney = GetQuestLogRewardMoney();
    storeQuestValue(questID, 'reward_money', rewardMoney)

    local choices = {}
    for i=1, numQuestChoices, 1 do
		local name, texture, numItems, quality, isUsable, itemID = GetQuestLogChoiceInfo(i);
        choices[i] = {
            ["item_id"] = itemID,
            ["name"] = name,
            ["texture"] = texture,
            ["num_items"] = numItems,
            ["quality"] = quality,
            ["is_usable"] = isUsable,
        }
    end

    storeQuestValue(questID, 'choices', choices)

    local rewards = {}
    for i=1, numQuestRewards, 1 do
		local name, texture, numItems, quality, isUsable, itemID = GetQuestLogRewardInfo(i);
        rewards[i] = {
            ["item_id"] = itemID,
            ["name"] = name,
            ["texture"] = texture,
            ["num_items"] = numItems,
            ["quality"] = quality,
            ["is_usable"] = isUsable,
        }
    end
    
    storeQuestValue(questID, 'rewards', rewards)

    SelectQuestLogEntry(tmpQuestLogSelection);

end

-- local MyQuestFrame = CreateFrame("Frame", "MyQuestFrame", UIParent, "MkQL_Main_Frame")
-- MyQuestFrame:Show();

local Panel=CreateFrame("Frame");
Panel.name=Title;

Panel:RegisterEvent("ADDON_LOADED");
Panel:RegisterEvent("QUEST_ACCEPTED");
Panel:RegisterEvent("QUEST_COMPLETE");
Panel:RegisterEvent("QUEST_REMOVED");

Panel:SetScript("OnEvent",function(self,event,...)
	if event=="ADDON_LOADED" and (...)==Name then
		WTFPrint("WTF LOADED");
        -- self:UnregisterEvent(event);
        if not WTFQuestsAbandoned then
            WTFQuestsAbandoned = {
                ["quests"] = {}
            };
        end
    elseif event=="QUEST_ACCEPTED" then
        local questIndex, questID = ...
        WTFPrint("Accepted id " .. questID)
        removeAbandonedQuest(questID)
        WTFPrint(event);
        storeQuestInfo(questIndex)
    elseif event=="QUEST_COMPLETE" then
        WTFPrint(event);
    elseif event=="QUEST_REMOVED" then
        local questID = (...)
        addAbandonedQuest(questID)
    end
end);

