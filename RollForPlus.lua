
-- ====================================================================================================
-- =                                   All the locals we need here.                                   =
-- ====================================================================================================

local Debug = true                             -- For debugging.
local AddToRoll = 10                            -- How much there will be added to the roll each time.


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
-- =                     Convert the RollFor text to to a table we can work with.                     =
-- ====================================================================================================

-- Function to decode Base64 encoded text from a "RollFor" string.
local function DecodeBase64TextFromRollFor(textString)

  -- String containing all valid Base64 characters
  local base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

  -- Inner function to decode a Base64 string
  local function decode_base64(data)
    -- Check if the input data is nil or falsey
    if not data then
      return nil  -- Return nil if no data is provided
    end

    -- Remove any characters from the input that are not valid Base64 characters or padding (=)
    data = string.gsub(data, "[^" .. base64_chars .. "=]", "")

    -- Perform two nested string substitutions to decode the Base64 data
    return string.gsub(string.gsub(data, ".", function(x)
      -- This inner gsub converts each Base64 character to its 6-bit binary representation

      if (x == "=") then
        return ""  -- Remove padding characters ('=')
      end

      local r, f = "", (string.find(base64_chars, x) - 1)  -- Find the index (0-63) of the Base64 character in the base64_chars string
      -- r: the result (binary string), f: the index of the base64 character

      -- Iterate from 6 down to 1 to extract each of the 6 bits
      for i = 6, 1, -1 do
        -- Calculate if the i-th bit is set (1) or not (0) using modulo and powers of 2
        r = r .. (math.mod(f, 2 ^ i) - math.mod(f, 2 ^ (i - 1)) > 0 and "1" or "0")
        -- math.mod(f, 2^i) gets the remainder when f is divided by 2^i
        -- subtracting math.mod(f, 2^(i-1)) isolates the i-th bit.
        -- if the result > 0, the bit is 1, otherwise 0
      end
      return r  -- Return the 6-bit binary string
    end), "%d%d%d?%d?%d?%d?%d?%d?", function(x)
      -- This outer gsub converts 8-bit binary strings to their corresponding ASCII characters
      -- %d represents a digit (0-9), the ? makes the preceding digit optional

      if (string.len(x) ~= 8) then
        return ""  -- Return empty string for incomplete 8-bit sequences (due to padding)
      end

      local c = 0  -- Initialize the decimal value of the byte
      -- Iterate through the 8 bits of the binary string
      for i = 1, 8 do
        -- Calculate the decimal value by adding the corresponding power of 2 if the bit is '1'
        c = c + (string.sub(x, i, i) == "1" and 2 ^ (8 - i) or 0)
        -- string.sub(x, i, i) gets the i-th character of x
        -- if it's "1", add 2^(8-i) to c.
      end
      return string.char(c)  -- Convert the decimal value to its ASCII character
    end)
  end

    -- The Base64 encoded string to decode (passed as argument to the function)
    local encoded_data = textString

    -- Decode the Base64 string
    local decoded_json_string = decode_base64(encoded_data)

    -- 
    if (decoded_json_string) then
        DEFAULT_CHAT_FRAME:AddMessage("Base64 Decoded JSON String:")
        -- Print the decoded JSON string
        DEFAULT_CHAT_FRAME:AddMessage(decoded_json_string)

        -- Attempt to decode the JSON string into a Lua table (you'll need a JSON library)
        -- Assuming you have a JSON library like "Json-0.1.2"
        local json = LibStub("Json-0.1.2")
        -- 
        if (json) then
            -- Use pcall for safe JSON decoding
            local success, decoded_table = pcall(json.decode, decoded_json_string)
            -- success: boolean indicating if decoding was successful
            -- decoded_table: the decoded table, or an error message if decoding failed
            if (success) then
                DEFAULT_CHAT_FRAME:AddMessage("JSON Decoded Table:")
                -- Function to print nested tables
                local function print_table(t, indent)
                    -- Default indent is empty string
                    indent = indent or ""
                    -- Iterate through key-value pairs in the table
                    for k, v in pairs(t) do
                        -- If the value is a table (nested structure)
                        if type(v) == "table" then
                        -- Print the key
                            DEFAULT_CHAT_FRAME:AddMessage(indent .. tostring(k) .. ": ")
                            -- Recursively call print_table with increased indent
                            print_table(v, indent .. "  ")
                        else
                            -- Print key-value pair
                            DEFAULT_CHAT_FRAME:AddMessage(indent .. tostring(k) .. ": " .. tostring(v))
                        end
                    end
                end
                print_table(decoded_table)  -- Call the function to print the decoded table
                --editBoxExport:SetText("Done")
                DEFAULT_CHAT_FRAME:AddMessage(decoded_table)
            else
                -- Print the error message
                DEFAULT_CHAT_FRAME:AddMessage("Error decoding JSON: " .. decoded_table)
            end
        else
            -- Print message if JSON library is not found
            DEFAULT_CHAT_FRAME:AddMessage("Json-0.1.2 library not found.  Cannot decode JSON.")
        end
    else
        -- Print message if Base64 decoding failed
        DEFAULT_CHAT_FRAME:AddMessage("Base64 Decoding Failed!")
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
    editBoxImport:SetText("eyJtZXRhZGF0YSI6eyJpZCI6IlRDVEczVyIsImluc3RhbmNlIjoxMDEsImluc3RhbmNlcyI6WyJMb3dlciBLYXJhemhhbiBIYWxscyJdLCJvcmlnaW4iOiJyYWlkcmVzIn0sInNvZnRyZXNlcnZlcyI6W3sibmFtZSI6IkxldG1lYmxlZWQiLCJpdGVtcyI6W3siaWQiOjYxNDUxLCJxdWFsaXR5IjozfV19LHsibmFtZSI6IlJhdHRsZWJyaXRjaCIsIml0ZW1zIjpbeyJpZCI6NjEyODEsInF1YWxpdHkiOjR9XX0seyJuYW1lIjoiQW5nZWxyaXBwZXJoIiwiaXRlbXMiOlt7ImlkIjo2MTI4NCwicXVhbGl0eSI6NH1dfSx7Im5hbWUiOiJBbGRpd2FycmlvciIsIml0ZW1zIjpbeyJpZCI6NjE0NDMsInF1YWxpdHkiOjR9XX0seyJuYW1lIjoiU3ViYmVyIiwiaXRlbXMiOlt7ImlkIjo4NTQ3LCJxdWFsaXR5IjozfV19XSwiaGFyZHJlc2VydmVzIjpbXX0=")

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
                DecodeBase64TextFromRollFor(text)
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
































