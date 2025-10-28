-- Virtual Keyboard for CC:T with Next/Previous/Select

math.randomseed(os.epoch("utc"))

-- Wrap monitor
local mon = peripheral.find("monitor")  -- replace with your monitor side if needed
mon.setTextScale(1)
mon.clear()
mon.setCursorPos(1,1)

-- Wrap redstone relays
local leftRelay = peripheral.wrap("redstone_relay_1")
local rightRelay = peripheral.wrap("redstone_relay_2")

if not leftRelay or not rightRelay then
    print("Missing redstone relays")
    return
end

-- Keyboard layout (the empty strings are to waste turns and to align keys)
local keys = {
    {"1","2","3","4","5","6","7","8","9","0", ""},
    {"q","w","e","r","t","y","u","i","o","p", ""},
    {"a","s","d","f","g","h","j","k","l", "", ""},
    {"z","x","c","v","b","n","m", "", "", "", ""},
    {"SPACE","BACK"}
}

-- Current selection
local selRow = 1
local selCol = 1

-- Input string
local input = ""

-- Draw a single key
local function drawKey(x, y, label, selected)
    mon.setCursorPos(x, y)
    if selected then
        mon.write("[" .. label .. "]") -- highlight
    else
        mon.write(" " .. label .. " ")
    end
end

-- Get keys pressed
local function getKeysPressed()
    return {
        previous = leftRelay.getInput("left"),
        next = leftRelay.getInput("back"),
        select = rightRelay.getInput("back"),
        submit = rightRelay.getInput("right"),
    }
end
local order = {"previous", "next", "select", "submit"}

-- Fixed drawNavButtons that preserves order
local function drawNavButtons()
    local y = #keys + 2
    local keysPressed = getKeysPressed()

    local x = 1
    for _, key in ipairs(order) do
        local pressed = keysPressed[key]
        drawKey(x, y, string.upper(key), pressed)
        x = x + #key + 4
    end
end

-- Function to randomize both keys within rows and the order of rows (except the bottom one)
local function randomizeKeys()
    -- Shuffle keys within each row
    for i = 1, #keys do
        for j = #keys[i], 2, -1 do
            local k = math.random(j)
            keys[i][j], keys[i][k] = keys[i][k], keys[i][j]
        end
    end

    -- Shuffle the rows, except the bottom one
    for i = #keys - 1, 2, -1 do
        local k = math.random(i)
        keys[i], keys[k] = keys[k], keys[i]
    end
end

-- Function to go to the next line on the monitor
local function nextLine()
    local x, y = mon.getCursorPos()
    mon.setCursorPos(1, y + 1)
end

local turns = 1
local randomAmmountTurns = math.random(10, 20)
local lastChangeTurn = 0

-- Draw keyboard + navigation buttons
local function drawKeyboard()
    mon.clear()
    mon.setCursorPos(1,1)

    -- Check if it's time to change layout
    if turns - lastChangeTurn >= randomAmmountTurns then
        randomAmmountTurns = math.random(10, 20)
        lastChangeTurn = turns
        mon.write("It's about time to get a new keyboard layout...")
        nextLine()
        os.sleep(2)
        mon.clear()
        randomizeKeys()
    end

    -- Draw keys
    for row = 1, #keys do
        local colPos = 1
        for col = 1, #keys[row] do
            local selected = (row == selRow and col == selCol)
            drawKey(colPos, row, keys[row][col], selected)
            colPos = colPos + #keys[row][col] + 3
        end
    end

    -- Draw navigation buttons
    drawNavButtons()

    -- Show current input and turns info
    mon.setCursorPos(1, #keys + 4)
    mon.write("Current: " .. input)
    mon.setCursorPos(1, #keys + 6)
    mon.write("Turns: " .. turns)
    nextLine()
    mon.write("Turns left: " .. (randomAmmountTurns - (turns - lastChangeTurn)))
end

-- Move selection
local function moveSelection(dir)
    if dir == "NEXT" then
        selCol = selCol + 1
        if selCol > #keys[selRow] then
            selCol = 1
            selRow = selRow + 1
            if selRow > #keys then selRow = 1 end
        end
    elseif dir == "PREV" then
        selCol = selCol - 1
        if selCol < 1 then
            selRow = selRow - 1
            if selRow < 1 then selRow = #keys end
            selCol = #keys[selRow]
        end
    end
end

-- Handle select
local function selectKey()
    local key = keys[selRow][selCol]
    if key == "BACK" then
        input = input:sub(1, -2)
    elseif key == "SPACE" then
        input = input.." "
    else
        input = input..key
    end
end

-- Initial draw
drawKeyboard()

-- Main loop
while true do
    os.pullEvent("redstone")
    print("redstone")
    os.sleep(0.1)
    local keysPressed = getKeysPressed()
    local hasChanged = false
    if keysPressed["select"] then
        selectKey()
        print("selectKey")
        hasChanged = true
    end
    if keysPressed["submit"] then
        print("submit", input)
        input = ""
        hasChanged = true
    end
    if keysPressed["previous"] then
        moveSelection("PREV")
        print("moveSelection PREV")
        hasChanged = true
    end
    if keysPressed["next"] then
        moveSelection("NEXT")
        print("moveSelection NEXT")
        hasChanged = true
    end
    if hasChanged then
        turns = turns + 1
    end
    drawKeyboard()
    print("drawKeyboard")
end