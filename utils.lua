-- // utility functions for roblox code ide
local utils = {};

-- // services
local tweenservice = game:GetService("TweenService");
local plrs = game:GetService("Players");
local rs = game:GetService("RunService");
local http = game:GetService("HttpService");

-- // variables
local lp = plrs.LocalPlayer;
local mouse = lp:GetMouse();

-- // constants
utils.colors = {
    background = Color3.fromRGB(30, 30, 40),
    primary = Color3.fromRGB(60, 50, 80),
    secondary = Color3.fromRGB(80, 70, 100),
    accent = Color3.fromRGB(140, 120, 200),
    text = Color3.fromRGB(230, 230, 240),
    success = Color3.fromRGB(100, 200, 100),
    error = Color3.fromRGB(200, 100, 100),
    warning = Color3.fromRGB(200, 180, 100),
    highlight = Color3.fromRGB(160, 140, 220)
};

utils.fonts = {
    regular = Enum.Font.Gotham,
    bold = Enum.Font.GothamBold,
    semibold = Enum.Font.GothamSemibold,
    monospace = Enum.Font.Code
};

utils.tween_info = {
    short = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    medium = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    long = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
};

-- // create nice hover effect with a gradient that moves from left to right
function utils:create_hover_effect(btn)
    local glow = Instance.new("UIGradient");
    glow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    });
    glow.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 0.9)
    });
    glow.Rotation = 90;
    glow.Parent = btn;
    
    local hover_conn;
    hover_conn = btn.MouseEnter:Connect(function()
        local tween = tweenservice:Create(glow, utils.tween_info.medium, {Rotation = 0});
        tween:Play();
        
        tweenservice:Create(btn, utils.tween_info.short, {
            BackgroundColor3 = utils.lighten_color(btn.BackgroundColor3, 0.1)
        }):Play();
    end);
    
    local leave_conn;
    leave_conn = btn.MouseLeave:Connect(function()
        local tween = tweenservice:Create(glow, utils.tween_info.medium, {Rotation = 90});
        tween:Play();
        
        tweenservice:Create(btn, utils.tween_info.short, {
            BackgroundColor3 = btn.BackgroundColor3
        }):Play();
    end);
    
    return {
        gradient = glow,
        connections = {hover_conn, leave_conn}
    };
end

-- // create a pop out effect for buttons
function utils:create_pop_effect(btn)
    local original_size = btn.Size;
    local original_pos = btn.Position;
    
    local hover_conn;
    hover_conn = btn.MouseEnter:Connect(function()
        tweenservice:Create(btn, utils.tween_info.short, {
            Size = UDim2.new(original_size.X.Scale, original_size.X.Offset + 4, 
                             original_size.Y.Scale, original_size.Y.Offset + 4),
            Position = UDim2.new(original_pos.X.Scale, original_pos.X.Offset - 2, 
                                original_pos.Y.Scale, original_pos.Y.Offset - 2)
        }):Play();
    end);
    
    local leave_conn;
    leave_conn = btn.MouseLeave:Connect(function()
        tweenservice:Create(btn, utils.tween_info.short, {
            Size = original_size,
            Position = original_pos
        }):Play();
    end);
    
    return {
        connections = {hover_conn, leave_conn}
    };
end

-- // lighten a color by a percentage (0-1)
function utils.lighten_color(color, amount)
    return Color3.new(
        math.min(color.R + amount, 1),
        math.min(color.G + amount, 1),
        math.min(color.B + amount, 1)
    );
end

-- // darken a color by a percentage (0-1)
function utils.darken_color(color, amount)
    return Color3.new(
        math.max(color.R - amount, 0),
        math.max(color.G - amount, 0),
        math.max(color.B - amount, 0)
    );
end

-- // create a rounded ui corner for an element
function utils:create_corner(parent, radius)
    local corner = Instance.new("UICorner");
    corner.CornerRadius = UDim.new(0, radius or 6);
    corner.Parent = parent;
    return corner;
end

-- // encode save data to json
function utils:encode_json(data)
    return http:JSONEncode(data);
end

-- // decode json data
function utils:decode_json(json_string)
    return http:JSONDecode(json_string);
end

-- // generate a unique id
function utils:generate_id()
    return http:GenerateGUID(false);
end

-- // split string into array by delimiter
function utils:split(str, delimiter)
    local result = {};
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

return utils;
