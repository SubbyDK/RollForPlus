
-- ====================================================================================================
-- =                                   All the locals we need here.                                   =
-- ====================================================================================================

local Debug = false                             -- For debugging.
local AddToRoll = 10                            -- How much there will be added to the roll each time.
local RaidPlace                                 -- The name of the raid we are checking.
local ReserverName                              -- Used when we loop through RollFor info to get the name.


-- ====================================================================================================
-- =                                Create frame(s) and Register event                                =
-- ====================================================================================================



-- ====================================================================================================
-- =                                          Event handler.                                          =
-- ====================================================================================================



-- ====================================================================================================
-- =                                     OnUpdate on every frame.                                     =
-- ====================================================================================================



-- ====================================================================================================
-- =                                          Slash commands                                          =
-- ====================================================================================================

SLASH_ROLLFORPLUS1, SLASH_ROLLFORPLUS2, SLASH_ROLLFORPLUS3 = "/rf+", "/rfp", "/rollforplus"
SlashCmdList["ROLLFORPLUS"] = function(msg)
    -- Show the RollForConverter.
    mainFrame:Show()
end

-- ====================================================================================================
-- =                                     Check who got what loot.                                     =
-- ====================================================================================================


-- ====================================================================================================
-- =                           Check if we have to add any plus to the info                           =
-- ====================================================================================================

--
local function CheckForPlus(raidData)
    -- Check if we received any raid data.
    if (raidData) then

        -- Make sure PlusTableDB is made.
        if (not PlusTableDB) or (not type(PlusTableDB) == "table") then
            PlusTableDB = {}
        end

        -- Check and save instance name.
        if (raidData.metadata) and (raidData.metadata.instances) then
            for _, instanceName in ipairs(raidData.metadata.instances) do
                -- Save the name of the raid.
                RaidPlace = instanceName
            end
        else
            editBoxExport:SetText("No instance information found.");
            return;
        end

        -- Check and display soft reserves information
        if (raidData.softreserves) then
            -- Iterate through each soft reserve entry (each player).
            for _, reserve in ipairs(raidData.softreserves) do
                ReserverName = reserve.name
                -- Check if the current player has any items listed in their soft reserves.
                if (reserve.items) then
                    -- Iterate through each item in the player's soft reserves.
                    for _, item in ipairs(reserve.items) do

                        -- Make sure we have a table for this raid.
                        if (not PlusTableDB[RaidPlace]) then
                            PlusTableDB[RaidPlace] = {}
                        end
                        -- Make sure we have a table for this person.
                        if (not PlusTableDB[RaidPlace][ReserverName]) then
                            PlusTableDB[RaidPlace][ReserverName] = { Items = {} }
                        end

                        -- Check if the item ID is already reserved by this person.
                        local alreadyReserved = false
                        for _, reservedItem in ipairs(PlusTableDB[RaidPlace][ReserverName].Items) do
                            if reservedItem.id == item.id then
                                -- Add a plus.
                                DEFAULT_CHAT_FRAME:AddMessage(item.sr_plus)
                                alreadyReserved = true
                                break
                            end
                        end

                        if (not alreadyReserved) then
                            -- It's a new item, add it to the table.
                            table.insert(PlusTableDB[RaidPlace][ReserverName].Items, item.id)
                        end
                        -- If it's already reserved, we do nothing (as per your original empty else).
                        
                        -- table.insert(PlusTableDB[RaidPlace][ReserverName].Items, item.id)
                        


                        if (item.sr_plus) then
                            --DEFAULT_CHAT_FRAME:AddMessage(ReserverName .. " - " .. RaidPlace .. "  Item ID: " .. item.id .. ", Quality: " .. item.quality .. ", Plus: " .. item.sr_plus);
                        else
                            --DEFAULT_CHAT_FRAME:AddMessage(ReserverName .. " - " .. RaidPlace .. "  Item ID: " .. item.id .. ", Quality: " .. item.quality);
                        end
                    end
                end
            end
        end
        -- For test
        editBoxExport:SetText("Soft reserves and instances displayed.");
    -- If no raid data was received.
    else
        editBoxExport:SetText("No raid data received.");
    end
end

-- ====================================================================================================
-- =                    Convert the RollFor text to to something we can work with.                    =
-- ====================================================================================================

-- Your provided Base64 decoding function
local function DecodeBase64Text(textString)
    -- String containing all valid Base64 characters
    local base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    -- Inner function to decode a Base64 string
    local function decode_base64(data)
        -- Check if the input data is nil or falsey
        if (not data) then
            return nil -- Return nil if no data is provided
        end

        -- Remove any characters from the input that are not valid Base64 characters or padding (=)
        data = string.gsub(data, "[^" .. base64_chars .. "=]", "")

        -- Perform two nested string substitutions to decode the Base64 data
        return string.gsub(string.gsub(data, ".", function(x)
            -- This inner gsub converts each Base64 character to its 6-bit binary representation

            if (x == "=") then
                return "" -- Remove padding characters ('=')
            end

            local r, f = "", (string.find(base64_chars, x) - 1) -- Find the index (0-63) of the Base64 character in the base64_chars string
            -- r: the result (binary string), f: the index of the base64 character

            -- Iterate from 6 down to 1 to extract each of the 6 bits
            for i = 6, 1, -1 do
                -- Calculate if the i-th bit is set (1) or not (0) using modulo and powers of 2
                r = r .. (math.mod(f, 2 ^ i) - math.mod(f, 2 ^ (i - 1)) > 0 and "1" or "0")
                -- math.mod(f, 2^i) gets the remainder when f is divided by 2^i
                -- subtracting math.mod(f, 2^(i-1)) isolates the i-th bit.
                -- if the result > 0, the bit is 1, otherwise 0
            end
            return r -- Return the 6-bit binary string
        end), "%d%d%d?%d?%d?%d?%d?%d?", function(x)
            -- This outer gsub converts 8-bit binary strings to their corresponding ASCII characters
            -- %d represents a digit (0-9), the ? makes the preceding digit optional

            if (string.len(x) ~= 8) then
                return "" -- Return empty string for incomplete 8-bit sequences (due to padding)
            end

            local c = 0 -- Initialize the decimal value of the byte
            -- Iterate through the 8 bits of the binary string
            for i = 1, 8 do
                -- Calculate the decimal value by adding the corresponding power of 2 if the bit is '1'
                c = c + (string.sub(x, i, i) == "1" and 2 ^ (8 - i) or 0)
                -- string.sub(x, i, i) gets the i-th character of x
                -- if it's "1", add 2^(8-i) to c.
            end
            return string.char(c) -- Convert the decimal value to its ASCII character
        end)
    end

    return decode_base64(textString)

end

-- ====================================================================================================
-- =                                                               =
-- ====================================================================================================

-- Function to decode Base64, then JSON, and send metadata to CheckForPlus
local function SendMetaDataToCheckForPlus(encodedString)

    -- Get the decoded info we need.
    local decodedJsonString = DecodeBase64Text(encodedString)

    -- Did we get any info ?
    if (decodedJsonString) then
        -- 
        local json = LibStub("Json-0.1.2")
        -- Is json loaded ?
        if (json) then
            -- 
            local success, decodedTable = pcall(json.decode, decodedJsonString)
            -- Now we check if the whole table decoded
            if (success) and (decodedTable) then
                -- Send the entire table
                CheckForPlus(decodedTable)
            -- 
            elseif (not success) then
                DEFAULT_CHAT_FRAME:AddMessage("Error decoding JSON: " .. decodedTable)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("Error: Json-0.1.2 library not found.")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("Error: Base64 decoding failed.")
    end
end

-- ====================================================================================================
-- =                                          The interface.                                          =
-- ====================================================================================================

-- Create the main frame
mainFrame = CreateFrame("Frame", "RollForPlusMainFrame", UIParent);
    mainFrame:SetPoint("CENTER", 0, 0);
    mainFrame:SetWidth(700);
    mainFrame:SetHeight(450);
    mainFrame:SetFrameStrata("DIALOG");
    mainFrame:SetClampedToScreen(true);
    mainFrame:SetMovable(true);
    mainFrame:EnableMouse(true);
    mainFrame:RegisterForDrag("LeftButton");
    mainFrame:SetScript("OnDragStart", function()
        this:StartMoving();
    end);
    mainFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing();
    end);
    mainFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    });
    mainFrame:SetBackdropColor(0, 0, 0, 0.9);
    mainFrame:Show()

-- Set headline.
local newsText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    newsText:SetPoint("TOP", mainFrame, "TOP", 0, -15);
    newsText:SetJustifyH("CENTER");
    newsText:SetText("Convert RollFor text to add +" .. AddToRoll);

-- Close button.
local closeButton = CreateFrame("Button", nil, RollForPlusMainFrame, "UIPanelCloseButton");
    closeButton:SetWidth(32);
    closeButton:SetHeight(32);
    closeButton:SetPoint("TOPRIGHT", RollForPlusMainFrame, "TOPRIGHT", 2, 0);
    closeButton:SetScript("OnClick", function()
        mainFrame:Hide();
    end);
    closeButton:Show();

-- Create the import content frame.
local importFrame = CreateFrame("Frame", "ImportMainFrame", RollForPlusMainFrame);
    importFrame:SetPoint("TOPLEFT", RollForPlusMainFrame, "TOPLEFT", 40, -40)
    importFrame:SetPoint("BOTTOMRIGHT", RollForPlusMainFrame, "BOTTOMRIGHT", -40, 250)
    importFrame:SetWidth(700-85); -- Adjust as needed
    importFrame:SetHeight(450-305);
    importFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    });
    importFrame:SetBackdropColor(0, 0, 0, 0.9);
    importFrame:Show();

-- Create the import scroll frame.
local scrollframeImport = CreateFrame("ScrollFrame", "ImportScrollFrame", ImportMainFrame);
    scrollframeImport:SetPoint("TOPLEFT", ImportMainFrame, "TOPLEFT", 0, 0);
    scrollframeImport:SetPoint("BOTTOMRIGHT", ImportMainFrame, "BOTTOMRIGHT", 0, 0);
    scrollframeImport:SetWidth(importFrame:GetWidth()); -- Adjust as needed
    scrollframeImport:SetHeight(importFrame:GetHeight());
    --scrollframeImport:EnableMouseWheel(true)
    scrollframeImport:Show();

-- Editbox for import.
local editBoxImport = CreateFrame("EditBox", "RollForImport", ImportScrollFrame);
    editBoxImport:SetTextInsets( 6, 6, 6, 6)
    editBoxImport:SetPoint("TOPLEFT", ImportScrollFrame, "TOPLEFT", 0, 0); 
    editBoxImport:SetPoint("BOTTOMRIGHT", ImportScrollFrame, "BOTTOMRIGHT", 0, 0);
    editBoxImport:SetWidth(scrollframeImport:GetWidth());
    editBoxImport:SetHeight(scrollframeImport:GetHeight());
    editBoxImport:SetAutoFocus(false)
    editBoxImport:SetMultiLine(true);
    editBoxImport:SetMaxLetters(0)
    editBoxImport:SetFontObject("ChatFontNormal")
    editBoxImport:Show()
    scrollframeImport:SetScrollChild(editBoxImport);

    -- For easy testing
    editBoxImport:SetText("eyJtZXRhZGF0YSI6eyJpZCI6IjdCWlJRQSIsImluc3RhbmNlIjo5NCwiaW5zdGFuY2VzIjpbIkJsYWNrd2luZyBMYWlyIl0sIm9yaWdpbiI6InJhaWRyZXMifSwic29mdHJlc2VydmVzIjpbeyJuYW1lIjoiU3ViYmVyIiwiaXRlbXMiOlt7ImlkIjoxNjkxMSwicXVhbGl0eSI6NCwic3JfcGx1cyI6MjB9LHsiaWQiOjE2OTExLCJxdWFsaXR5Ijo0LCJzcl9wbHVzIjoyMH1dfSx7Im5hbWUiOiJSZWlsbG9zIiwiaXRlbXMiOlt7ImlkIjoxNjk1MSwicXVhbGl0eSI6NCwic3JfcGx1cyI6MTB9LHsiaWQiOjE2OTUyLCJxdWFsaXR5Ijo0fV19XSwiaGFyZHJlc2VydmVzIjpbeyJpZCI6MTY5MTAsInF1YWxpdHkiOjR9XX0=")

    -- What will happen ehen escape is pressed.
    editBoxImport:SetScript("OnEscapePressed", function()
        editBoxImport:ClearFocus()
    end)
    editBoxImport:SetScript("OnEnterPressed", function()
        -- Not used, just here so I know I have the option if I ever need.
    end)
    editBoxImport:SetScript("OnMouseDown", function()
        -- Not used, just here so I know I have the option if I ever need.
    end)
    editBoxImport:SetScript("OnEditFocusGained", function()
        -- Not used, just here so I know I have the option if I ever need.
    end)
    editBoxImport:SetScript("OnEditFocusLost", function()
        -- Not used, just here so I know I have the option if I ever need.
    end)
    editBoxImport:SetScript("OnTextChanged", function()
        -- Not used, just here so I know I have the option if I ever need.
    end)

    -- Button to save the people we have added.
    local saveButtonImport = CreateFrame("Button", nil, RollForPlusMainFrame, "UIPanelButtonTemplate");
        saveButtonImport:SetWidth(80);
        saveButtonImport:SetHeight(18);
        saveButtonImport:SetPoint("TOPRIGHT", ImportMainFrame, "BOTTOMRIGHT", 0, 0);
        saveButtonImport:SetText("Do Magic !");
        saveButtonImport:SetScript("OnClick", function()

            local text = editBoxImport:GetText();
            -- Check that we got some test.
            if (text) and (text ~= "") then
                --decode_base64(text);
                --ConvertRollForText(text);
                --DecodeBase64TextFromRollFor(text)
                SendMetaDataToCheckForPlus(text)
            end

            -- Clear focus from editBox.
            editBoxImport:ClearFocus()

        end);

-- ====================================================================================================

-- Create the import content frame.
local exportFrame = CreateFrame("Frame", "ExportMainFrame", RollForPlusMainFrame);
    exportFrame:SetPoint("TOPLEFT", RollForPlusMainFrame, "TOPLEFT", 40, -230)
    exportFrame:SetPoint("BOTTOMRIGHT", RollForPlusMainFrame, "BOTTOMRIGHT", -40, 40)
    exportFrame:SetWidth(700-85); -- Adjust as needed
    exportFrame:SetHeight(450-305);
    exportFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    });
    exportFrame:SetBackdropColor(0, 0, 0, 0.9);
    exportFrame:Show();

-- Create the import scroll frame.
local scrollframeExport = CreateFrame("ScrollFrame", "ExportScrollFrame", ExportMainFrame);
    scrollframeExport:SetPoint("TOPLEFT", ExportMainFrame, "TOPLEFT", 0, 0);
    scrollframeExport:SetPoint("BOTTOMRIGHT", ExportMainFrame, "BOTTOMRIGHT", 0, 0);
    scrollframeExport:SetWidth(importFrame:GetWidth()); -- Adjust as needed
    scrollframeExport:SetHeight(importFrame:GetHeight());
    --scrollframeExport:EnableMouseWheel(true)
    scrollframeExport:Show();

-- Editbox for import.
editBoxExport = CreateFrame("EditBox", "RollForExport", ExportScrollFrame);
    editBoxExport:SetTextInsets( 6, 6, 6, 6)
    editBoxExport:SetPoint("TOPLEFT", ExportScrollFrame, "TOPLEFT", 0, 0); 
    editBoxExport:SetPoint("BOTTOMRIGHT", ExportScrollFrame, "BOTTOMRIGHT", 0, 0);
    editBoxExport:SetWidth(scrollframeExport:GetWidth());
    editBoxExport:SetHeight(scrollframeExport:GetHeight());
    editBoxExport:SetAutoFocus(false)
    editBoxExport:SetMultiLine(true);
    editBoxExport:SetMaxLetters(0)
    editBoxExport:SetFontObject("ChatFontNormal")
    editBoxExport:Show()
    scrollframeExport:SetScrollChild(editBoxExport);

    -- What will happen ehen escape is pressed.
    editBoxExport:SetScript("OnEscapePressed", function()
        editBoxExport:ClearFocus()
    end)
    editBoxExport:SetScript("OnEnterPressed", function()
        -- Not used, just here so I know I have the option if I ever need.
    end)
    editBoxExport:SetScript("OnMouseDown", function()
        -- Not used, just here so I know I have the option if I ever need.
    end)
    editBoxExport:SetScript("OnEditFocusGained", function()
        -- Not used, just here so I know I have the option if I ever need.
    end)
    editBoxExport:SetScript("OnEditFocusLost", function()
        -- Not used, just here so I know I have the option if I ever need.
    end)
    editBoxExport:SetScript("OnTextChanged", function()
        -- Not used, just here so I know I have the option if I ever need.
    end)

    -- Button to copy.
    local saveButtonExport = CreateFrame("Button", nil, RollForPlusMainFrame, "UIPanelButtonTemplate");
        saveButtonExport:SetWidth(60);
        saveButtonExport:SetHeight(18);
        saveButtonExport:SetPoint("TOPRIGHT", ExportMainFrame, "BOTTOMRIGHT", 0, 0);
        saveButtonExport:SetText("Copy");
        saveButtonExport:SetScript("OnClick", function()

            local text = editBoxImport:GetText();
            -- Check that we got some test.
            if (text) and (text ~= "") then
                editBoxExport:SetFocus()
                editBoxExport:HighlightText()
            end

        end);

    -- Discord import.
    local DicordImport = CreateFrame("Button", nil, RollForPlusMainFrame, "UIPanelButtonTemplate");
        DicordImport:SetWidth(120);
        DicordImport:SetHeight(18);
        DicordImport:SetPoint("TOPLEFT", ExportMainFrame, "BOTTOMLEFT", 0, 0);
        DicordImport:SetText("Import from Discord");
        DicordImport:SetScript("OnClick", function()
            -- Open the window for Discord export.
        end);

    -- Discord export.
    local DicordExport = CreateFrame("Button", nil, RollForPlusMainFrame, "UIPanelButtonTemplate");
        DicordExport:SetWidth(110);
        DicordExport:SetHeight(18);
        DicordExport:SetPoint("TOPLEFT", DicordImport, "TOPRIGHT", 10, 0);
        DicordExport:SetText("Export to Discord");
        DicordExport:SetScript("OnClick", function()
            -- Open the window for Discord export.
        end);




























