-- Remote Logger Functions and UI Elements

local remoteLogger = {
    enabled = false,
    remotes = {},
    connection = nil,
    loggedArgs = {},
    hookFunction = nil
}

-- Create UI elements
local remoteToggleBtn = Instance.new("TextButton")
remoteToggleBtn.Name = "remoteLoggerToggleBtn"
remoteToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
remoteToggleBtn.Position = UDim2.new(0, 10, 0, 290) -- Position below Part Selector
remoteToggleBtn.Size = UDim2.new(0, 200, 0, 30)
remoteToggleBtn.Font = Enum.Font.SourceSans
remoteToggleBtn.TextSize = 14
remoteToggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
remoteToggleBtn.Text = " Check Remote Args"
remoteToggleBtn.BorderSizePixel = 0
remoteToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
remoteToggleBtn.ZIndex = 4

Instance.new("UIStroke", remoteToggleBtn).Color = Color3.fromRGB(90, 90, 90)
Instance.new("UIPadding", remoteToggleBtn).PaddingLeft = UDim.new(0, 8)
Instance.new("UICorner", remoteToggleBtn).CornerRadius = UDim.new(0, 6)

local checkMark = Instance.new("TextLabel")
checkMark.Name = "CheckMark"
checkMark.Parent = remoteToggleBtn
checkMark.BackgroundTransparency = 1
checkMark.Size = UDim2.new(0, 20, 1, 0)
checkMark.Position = UDim2.new(1, -25, 0, 0)
checkMark.Font = Enum.Font.SourceSansBold
checkMark.TextSize = 16
checkMark.TextColor3 = Color3.fromRGB(180, 220, 180)
checkMark.Text = "✓"
checkMark.Visible = false
checkMark.TextXAlignment = Enum.TextXAlignment.Right
checkMark.ZIndex = 5

-- Create dropdown frame
local dropFrame = Instance.new("Frame")
dropFrame.Name = "RemoteDropFrame"
dropFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropFrame.Position = UDim2.new(0, 10, 0, 330)
dropFrame.Size = UDim2.new(0, 200, 0, 0)
dropFrame.BorderSizePixel = 0
dropFrame.ClipsDescendants = true
dropFrame.Visible = false
dropFrame.ZIndex = 5

Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", dropFrame).Color = Color3.fromRGB(90, 90, 90)

local dropScroll = Instance.new("ScrollingFrame")
dropScroll.Name = "RemoteScroll"
dropScroll.Parent = dropFrame
dropScroll.BackgroundTransparency = 1
dropScroll.Position = UDim2.new(0, 0, 0, 0)
dropScroll.Size = UDim2.new(1, 0, 1, 0)
dropScroll.ScrollBarThickness = 4
dropScroll.ScrollingDirection = Enum.ScrollingDirection.Y
dropScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
dropScroll.ZIndex = 5

local dropList = Instance.new("UIListLayout")
dropList.Parent = dropScroll
dropList.SortOrder = Enum.SortOrder.LayoutOrder
dropList.Padding = UDim.new(0, 2)

-- Functions
function remoteLogger.findRemotes()
    local found = {}
    
    for _, service in ipairs(game:GetChildren()) do
        if typeof(service) == "Instance" then
            for _, desc in ipairs(service:GetDescendants()) do
                if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                    table.insert(found, desc)
                end
            end
        end
    end
    
    return found
end

function remoteLogger.getRemotePath(remote)
    local path = remote.Name
    local current = remote
    while current.Parent and current.Parent ~= game do
        current = current.Parent
        path = current.Name .. "." .. path
    end
    return path
end

function remoteLogger.logRemoteArgs(remote, ...)
    local args = {...}
    local argStr = ""
    
    for i, arg in ipairs(args) do
        local argType = typeof(arg)
        if argType == "table" then
            local success, encoded = pcall(function()
                return game:GetService("HttpService"):JSONEncode(arg)
            end)
            argStr = argStr .. "table" .. i .. ": " .. (success and encoded or "Failed to encode")
        else
            argStr = argStr .. "arg" .. i .. ": " .. tostring(arg)
        end
        if i < #args then argStr = argStr .. ", " end
    end
    
    remoteLogger.loggedArgs[remote] = {
        path = remoteLogger.getRemotePath(remote),
        type = remote.ClassName,
        args = argStr
    }
end

function remoteLogger.updateSystemPrompt()
    local remotesInfo = {}
    for remote, info in pairs(remoteLogger.loggedArgs) do
        table.insert(remotesInfo, string.format(
            "Remote: %s\nType: %s\nArgs: %s",
            info.path,
            info.type,
            info.args
        ))
    end
    
    if #remotesInfo > 0 then
        local remoteSection = "Logged Remotes:\n" .. table.concat(remotesInfo, "\n\n")
        
        if currentSystemPrompt == "" then
            currentSystemPrompt = remoteSection
        else
            local start = currentSystemPrompt:find("Logged Remotes:\n")
            if start then
                local nextSection = currentSystemPrompt:find("\n\n", start)
                currentSystemPrompt = currentSystemPrompt:sub(1, start - 1) .. 
                                    remoteSection ..
                                    (nextSection and currentSystemPrompt:sub(nextSection) or "")
            else
                currentSystemPrompt = currentSystemPrompt .. "\n\n" .. remoteSection
            end
        end
    end
end

function remoteLogger.createRemoteButton(remote, index)
    local btn = Instance.new("TextButton")
    btn.Name = remote.Name .. "_Btn"
    btn.Parent = dropScroll
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Size = UDim2.new(1, -4, 0, 25)
    btn.Position = UDim2.new(0, 2, 0, (index - 1) * 27)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Text = " " .. remote.Name
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.ZIndex = 6
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Parent = btn
    statusLabel.BackgroundTransparency = 1
    statusLabel.Position = UDim2.new(1, -50, 0, 0)
    statusLabel.Size = UDim2.new(0, 45, 1, 0)
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 12
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    statusLabel.Text = "Pending"
    statusLabel.ZIndex = 6
    
    return btn
end

function remoteLogger.setupNamecall()
    if remoteLogger.hookFunction then return end
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if remoteLogger.enabled and (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            task.spawn(function()
                remoteLogger.logRemoteArgs(self, ...)
                local btn = dropScroll:FindFirstChild(self.Name .. "_Btn")
                if btn and btn:FindFirstChild("Status") then
                    btn.Status.Text = "Logged"
                    btn.Status.TextColor3 = Color3.fromRGB(100, 200, 100)
                end
            end)
        end
        
        return oldNamecall(self, ...)
    end))
    
    remoteLogger.hookFunction = oldNamecall
end

function remoteLogger.startChecking()
    remoteLogger.remotes = remoteLogger.findRemotes()
    
    -- Clear existing buttons
    for _, child in ipairs(dropScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Create buttons for each remote
    for i, remote in ipairs(remoteLogger.remotes) do
        local btn = remoteLogger.createRemoteButton(remote, i)
    end
    
    -- Update scroll frame canvas size
    dropScroll.CanvasSize = UDim2.new(0, 0, 0, #remoteLogger.remotes * 27 + 2)
    
    -- Show dropdown
    dropFrame.Size = UDim2.new(0, 200, 0, math.min(200, #remoteLogger.remotes * 27 + 4))
    dropFrame.Visible = true
    
    -- Setup namecall hook
    remoteLogger.setupNamecall()
    
    -- Notify user
    _G.partSelector.showNotif("Remote logger enabled - waiting for remote calls", 3)
end

-- Connect button
remoteToggleBtn.MouseButton1Click:Connect(function()
    remoteLogger.enabled = not remoteLogger.enabled
    checkMark.Visible = remoteLogger.enabled
    
    if remoteLogger.enabled then
        remoteLogger.startChecking()
    else
        dropFrame.Visible = false
        dropFrame.Size = UDim2.new(0, 200, 0, 0)
        remoteLogger.loggedArgs = {}
    end
end)

-- Return the button to be added to the settings frame
return remoteToggleBtn
