-- // ui module for code ide
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/username/RobloxCodeIDE/main/utils.lua"))();
local config = loadstring(game:HttpGet("https://raw.githubusercontent.com/username/RobloxCodeIDE/main/config.lua"))();
local themes_mgr = loadstring(game:HttpGet("https://raw.githubusercontent.com/username/RobloxCodeIDE/main/themesManager.lua"))();

local plrs = game:GetService("Players");
local uis = game:GetService("UserInputService");
local ts = game:GetService("TweenService");

local lp = plrs.LocalPlayer;
local mouse = lp:GetMouse();

local ui = {};

-- // ui components
ui.components = {};

-- // create a slider component
function ui.components.create_slider(parent, title, min, max, default, callback)
    local container = Instance.new("Frame");
    container.Name = title:gsub("%s+", "") .. "SliderContainer";
    container.BackgroundTransparency = 1;
    container.Size = UDim2.new(1, 0, 0, 50);
    container.Parent = parent;
    
    local title_label = Instance.new("TextLabel");
    title_label.Name = "Title";
    title_label.BackgroundTransparency = 1;
    title_label.Size = UDim2.new(1, 0, 0, 20);
    title_label.Font = utils.fonts.semibold;
    title_label.TextSize = 14;
    title_label.TextColor3 = utils.colors.text;
    title_label.TextXAlignment = Enum.TextXAlignment.Left;
    title_label.Text = title;
    title_label.Parent = container;
    
    local value_label = Instance.new("TextLabel");
    value_label.Name = "Value";
    value_label.BackgroundTransparency = 1;
    value_label.Size = UDim2.new(0, 50, 0, 20);
    value_label.Position = UDim2.new(1, -50, 0, 0);
    value_label.Font = utils.fonts.regular;
    value_label.TextSize = 14;
    value_label.TextColor3 = utils.colors.text;
    value_label.TextXAlignment = Enum.TextXAlignment.Right;
    value_label.Text = tostring(default);
    value_label.Parent = container;
    
    local track = Instance.new("Frame");
    track.Name = "Track";
    track.BackgroundColor3 = utils.colors.secondary;
    track.BorderSizePixel = 0;
    track.Size = UDim2.new(1, 0, 0, 6);
    track.Position = UDim2.new(0, 0, 0, 30);
    track.Parent = container;
    
    utils:create_corner(track, 3);
    
    local fill = Instance.new("Frame");
    fill.Name = "Fill";
    fill.BackgroundColor3 = utils.colors.accent;
    fill.BorderSizePixel = 0;
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0);
    fill.Parent = track;
    
    utils:create_corner(fill, 3);
    
    local knob = Instance.new("Frame");
    knob.Name = "Knob";
    knob.BackgroundColor3 = utils.colors.text;
    knob.Size = UDim2.new(0, 16, 0, 16);
    knob.Position = UDim2.new((default - min) / (max - min), -8, 0, -5);
    knob.Parent = track;
    
    utils:create_corner(knob, 8);
    
    -- // slider functionality
    local dragging = false;
    local value = default;
    
    local function update_value(new_val)
        value = math.clamp(new_val, min, max);
        value_label.Text = tostring(math.floor(value * 100) / 100);
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0);
        knob.Position = UDim2.new((value - min) / (max - min), -8, 0, -5);
        
        if callback then
            callback(value);
        end
    end
    
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true;
        end
    end);
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = input.Position.X;
            local relative = math.clamp((pos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1);
            update_value(min + relative * (max - min));
            dragging = true;
        end
    end);
    
    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false;
        end
    end);
    
    uis.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local pos = input.Position.X;
            local relative = math.clamp((pos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1);
            update_value(min + relative * (max - min));
        end
    end);
    
    -- // functions to get/set value
    local slider = {
        instance = container,
        get_value = function()
            return value;
        end,
        set_value = function(new_val)
            update_value(new_val);
        end
    };
    
    return slider;
end

-- // create a toggle switch
function ui.components.create_toggle(parent, title, default, callback)
    local container = Instance.new("Frame");
    container.Name = title:gsub("%s+", "") .. "ToggleContainer";
    container.BackgroundTransparency = 1;
    container.Size = UDim2.new(1, 0, 0, 30);
    container.Parent = parent;
    
    local title_label = Instance.new("TextLabel");
    title_label.Name = "Title";
    title_label.BackgroundTransparency = 1;
    title_label.Size = UDim2.new(1, -60, 1, 0);
    title_label.Font = utils.fonts.semibold;
    title_label.TextSize = 14;
    title_label.TextColor3 = utils.colors.text;
    title_label.TextXAlignment = Enum.TextXAlignment.Left;
    title_label.Text = title;
    title_label.Parent = container;
    
    local toggle_button = Instance.new("Frame");
    toggle_button.Name = "ToggleButton";
    toggle_button.BackgroundColor3 = default and utils.colors.accent or utils.colors.secondary;
    toggle_button.Size = UDim2.new(0, 40, 0, 20);
    toggle_button.Position = UDim2.new(1, -50, 0, 5);
    toggle_button.Parent = container;
    
    utils:create_corner(toggle_button, 10);
    
    local knob = Instance.new("Frame");
    knob.Name = "Knob";
    knob.BackgroundColor3 = utils.colors.text;
    knob.Size = UDim2.new(0, 16, 0, 16);
    knob.Position = UDim2.new(default and 0.6 or 0, 2, 0, 2);
    knob.Parent = toggle_button;
    
    utils:create_corner(knob, 8);
    
    -- // toggle functionality
    local enabled = default;
    
    local function update(value)
        enabled = value;
        
        ts:Create(toggle_button, utils.tween_info.short, {
            BackgroundColor3 = enabled and utils.colors.accent or utils.colors.secondary
        }):Play();
        
        ts:Create(knob, utils.tween_info.short, {
            Position = UDim2.new(enabled and 0.6 or 0, 2, 0, 2)
        }):Play();
        
        if callback then
            callback(enabled);
        end
    end
    
    toggle_button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            update(not enabled);
        end
    end);
    
    -- // functions to get/set value
    local toggle = {
        instance = container,
        get_value = function()
            return enabled;
        end,
        set_value = function(value)
            update(value);
        end
    };
    
    return toggle;
end

-- // create a dropdown selector
function ui.components.create_dropdown(parent, title, options, default, callback)
    local container = Instance.new("Frame");
    container.Name = title:gsub("%s+", "") .. "DropdownContainer";
    container.BackgroundTransparency = 1;
    container.Size = UDim2.new(1, 0, 0, 70);
    container.ClipsDescendants = true;
    container.Parent = parent;
    
    local title_label = Instance.new("TextLabel");
    title_label.Name = "Title";
    title_label.BackgroundTransparency = 1;
    title_label.Size = UDim2.new(1, 0, 0, 20);
    title_label.Font = utils.fonts.semibold;
    title_label.TextSize = 14;
    title_label.TextColor3 = utils.colors.text;
    title_label.TextXAlignment = Enum.TextXAlignment.Left;
    title_label.Text = title;
    title_label.Parent = container;
    
    local dropdown_button = Instance.new("TextButton");
    dropdown_button.Name = "DropdownButton";
    dropdown_button.BackgroundColor3 = utils.colors.secondary;
    dropdown_button.Size = UDim2.new(1, 0, 0, 30);
    dropdown_button.Position = UDim2.new(0, 0, 0, 25);
    dropdown_button.Font = utils.fonts.regular;
    dropdown_button.TextSize = 14;
    dropdown_button.TextColor3 = utils.colors.text;
    dropdown_button.Text = default or options[1] or "Select...";
    dropdown_button.TextXAlignment = Enum.TextXAlignment.Left;
    dropdown_button.TextTruncate = Enum.TextTruncate.AtEnd;
    dropdown_button.Parent = container;
    
    utils:create_corner(dropdown_button, 6);
    
    local dropdown_padding = Instance.new("UIPadding");
    dropdown_padding.PaddingLeft = UDim.new(0, 10);
    dropdown_padding.Parent = dropdown_button;
    
    local dropdown_arrow = Instance.new("ImageLabel");
    dropdown_arrow.Name = "Arrow";
    dropdown_arrow.BackgroundTransparency = 1;
    dropdown_arrow.Size = UDim2.new(0, 20, 0, 20);
    dropdown_arrow.Position = UDim2.new(1, -25, 0, 5);
    dropdown_arrow.Image = "rbxassetid://9429891584";
    dropdown_arrow.Rotation = 0;
    dropdown_arrow.Parent = dropdown_button;
    
    local dropdown_menu = Instance.new("Frame");
    dropdown_menu.Name = "DropdownMenu";
    dropdown_menu.BackgroundColor3 = utils.colors.primary;
    dropdown_menu.Size = UDim2.new(1, 0, 0, 0);
    dropdown_menu.Position = UDim2.new(0, 0, 0, 60);
    dropdown_menu.Visible = false;
    dropdown_menu.ZIndex = 10;
    dropdown_menu.Parent = container;
    
    utils:create_corner(dropdown_menu, 6);
    
    local dropdown_list = Instance.new("ScrollingFrame");
    dropdown_list.Name = "OptionsList";
    dropdown_list.BackgroundTransparency = 1;
    dropdown_list.Size = UDim2.new(1, 0, 1, 0);
    dropdown_list.CanvasSize = UDim2.new(0, 0, 0, 0);
    dropdown_list.ScrollBarThickness = 4;
    dropdown_list.ScrollBarImageColor3 = utils.colors.accent;
    dropdown_list.ZIndex = 10;
    dropdown_list.Parent = dropdown_menu;
    
    local dropdown_list_layout = Instance.new("UIListLayout");
    dropdown_list_layout.SortOrder = Enum.SortOrder.LayoutOrder;
    dropdown_list_layout.Padding = UDim.new(0, 2);
    dropdown_list_layout.Parent = dropdown_list;
    
    local dropdown_list_padding = Instance.new("UIPadding");
    dropdown_list_padding.PaddingTop = UDim.new(0, 5);
    dropdown_list_padding.PaddingBottom = UDim.new(0, 5);
    dropdown_list_padding.PaddingLeft = UDim.new(0, 5);
    dropdown_list_padding.PaddingRight = UDim.new(0, 5);
    dropdown_list_padding.Parent = dropdown_list;
    
    -- // populate options
    local option_buttons = {};
    for i, option in ipairs(options) do
        local option_button = Instance.new("TextButton");
        option_button.Name = "Option_" .. option;
        option_button.BackgroundColor3 = utils.colors.secondary;
        option_button.BackgroundTransparency = 0.8;
        option_button.Size = UDim2.new(1, -10, 0, 25);
        option_button.Font = utils.fonts.regular;
        option_button.TextSize = 14;
        option_button.TextColor3 = utils.colors.text;
        option_button.Text = option;
        option_button.TextXAlignment = Enum.TextXAlignment.Left;
        option_button.LayoutOrder = i;
        option_button.ZIndex = 11;
        option_button.Parent = dropdown_list;
        
        utils:create_corner(option_button, 4);
        
        local option_padding = Instance.new("UIPadding");
        option_padding.PaddingLeft = UDim.new(0, 10);
        option_padding.Parent = option_button;
        
        option_buttons[option] = option_button;
        
        -- // hover effect
        utils:create_hover_effect(option_button);
    end
    
    -- // update canvas size
    dropdown_list_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        dropdown_list.CanvasSize = UDim2.new(0, 0, 0, dropdown_list_layout.AbsoluteContentSize.Y + 10);
    end);
    
    -- // dropdown functionality
    local open = false;
    local selected = default or options[1] or "";
    
    local function toggle_dropdown()
        open = not open;
        
        -- // tween the container size and dropdown menu
        if open then
            container.Size = UDim2.new(1, 0, 0, 70 + math.min(150, #options * 30));
            dropdown_menu.Visible = true;
            dropdown_menu.Size = UDim2.new(1, 0, 0, math.min(150, #options * 30));
        else
            container.Size = UDim2.new(1, 0, 0, 70);
            dropdown_menu.Size = UDim2.new(1, 0, 0, 0);
            task.delay(0.2, function()
                if not open then
                    dropdown_menu.Visible = false;
                end
            end);
        end
        
        -- // tween the arrow
        ts:Create(dropdown_arrow, utils.tween_info.short, {
            Rotation = open and 180 or 0
        }):Play();
    end
    
    local function select_option(option)
        if option ~= selected then
            selected = option;
            dropdown_button.Text = selected;
            
            if callback then
                callback(selected);
            end
        end
        
        toggle_dropdown();
    end
    
    dropdown_button.MouseButton1Click:Connect(toggle_dropdown);
    
    -- // option selection
    for option, button in pairs(option_buttons) do
        button.MouseButton1Click:Connect(function()
            select_option(option);
        end);
    end
    
    -- // functions to get/set value
    local dropdown = {
        instance = container,
        get_value = function()
            return selected;
        end,
        set_value = function(option)
            if option_buttons[option] then
                select_option(option);
            end
        end
    };
    
    return dropdown;
end

-- // create a button
function ui.components.create_button(parent, text, callback)
    local button = Instance.new("TextButton");
    button.Name = text:gsub("%s+", "") .. "Button";
    button.BackgroundColor3 = utils.colors.accent;
    button.Size = UDim2.new(0, 100, 0, 30);
    button.Font = utils.fonts.semibold;
    button.TextSize = 14;
    button.TextColor3 = utils.colors.text;
    button.Text = text;
    button.Parent = parent;
    
    utils:create_corner(button, 6);
    utils:create_hover_effect(button);
    utils:create_pop_effect(button);
    
    button.MouseButton1Click:Connect(function()
        if callback then
            callback();
        end
    end);
    
    return button;
end

-- // create the main IDE UI
function ui:create_ide()
    -- // Create ScreenGui
    self.screen_gui = Instance.new("ScreenGui");
    self.screen_gui.Name = "CodeIDEMoonlight";
    self.screen_gui.ResetOnSpawn = false;
    self.screen_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
    self.screen_gui.Parent = lp:WaitForChild("PlayerGui");
    
    -- // Shadow effect for depth
    self.shadow = Instance.new("ImageLabel");
    self.shadow.Name = "Shadow";
    self.shadow.BackgroundTransparency = 1;
    self.shadow.Size = UDim2.new(1, 30, 1, 30);
    self.shadow.Position = UDim2.new(0, -15, 0, -15);
    self.shadow.Image = "rbxassetid://5028857084";
    self.shadow.ImageColor3 = Color3.fromRGB(0, 0, 0);
    self.shadow.ImageTransparency = 0.5;
    self.shadow.ScaleType = Enum.ScaleType.Slice;
    self.shadow.SliceCenter = Rect.new(24, 24, 276, 276);
    self.shadow.ZIndex = 0;
    self.shadow.Parent = self.screen_gui;
    
    -- // Main frame
    self.main_frame = Instance.new("Frame");
    self.main_frame.Name = "MainFrame";
    self.main_frame.BackgroundColor3 = utils.colors.background;
    self.main_frame.Size = UDim2.new(0, config.ui.width, 0, config.ui.height);
    self.main_frame.Position = UDim2.new(0.5, -config.ui.width/2, 0.5, -config.ui.height/2);
    self.main_frame.Parent = self.screen_gui;
    
    utils:create_corner(self.main_frame, 8);
    
    self.shadow.AnchorPoint = Vector2.new(0.5, 0.5);
    self.shadow.Position = UDim2.new(0.5, 0, 0.5, 0);
    self.shadow.Parent = self.main_frame;
    
    -- // Title bar
    self.title_bar = Instance.new("Frame");
    self.title_bar.Name = "TitleBar";
    self.title_bar.BackgroundColor3 = utils.colors.primary;
    self.title_bar.Size = UDim2.new(1, 0, 0, 30);
    self.title_bar.Parent = self.main_frame;
    
    utils:create_corner(self.title_bar, 8);
    
    local corner_fix = Instance.new("Frame");
    corner_fix.Name = "CornerFix";
    corner_fix.BackgroundColor3 = utils.colors.primary;
    corner_fix.BorderSizePixel = 0;
    corner_fix.Size = UDim2.new(1, 0, 0, 8);
    corner_fix.Position = UDim2.new(0, 0, 1, -8);
    corner_fix.ZIndex = 0;
    corner_fix.Parent = self.title_bar;
    
    -- // Title
    self.title = Instance.new("TextLabel");
    self.title.Name = "Title";
    self.title.BackgroundTransparency = 1;
    self.title.Size = UDim2.new(1, -100, 1, 0);
    self.title.Position = UDim2.new(0, 10, 0, 0);
    self.title.Font = utils.fonts.bold;
    self.title.TextSize = 16;
    self.title.TextColor3 = utils.colors.text;
    self.title.TextXAlignment = Enum.TextXAlignment.Left;
    self.title.Text = config.ui.title;
    self.title.Parent = self.title_bar;
    
    -- // Window controls
    self.window_controls = Instance.new("Frame");
    self.window_controls.Name = "WindowControls";
    self.window_controls.BackgroundTransparency = 1;
    self.window_controls.Size = UDim2.new(0, 90, 1, 0);
    self.window_controls.Position = UDim2.new(1, -90, 0, 0);
    self.window_controls.Parent = self.title_bar;
    
    -- // Minimize button
    self.minimize_btn = Instance.new("ImageButton");
    self.minimize_btn.Name = "MinimizeButton";
    self.minimize_btn.BackgroundTransparency = 1;
    self.minimize_btn.Size = UDim2.new(0, 30, 0, 30);
    self.minimize_btn.Position = UDim2.new(0, 0, 0, 0);
    self.minimize_btn.Image = "rbxassetid://9429429202";
    self.minimize_btn.ImageColor3 = utils.colors.text;
    self.minimize_btn.Parent = self.window_controls;
    
    utils:create_hover_effect(self.minimize_btn);
    
    -- // Maximize button
    self.maximize_btn = Instance.new("ImageButton");
    self.maximize_btn.Name = "MaximizeButton";
    self.maximize_btn.BackgroundTransparency = 1;
    self.maximize_btn.Size = UDim2.new(0, 30, 0, 30);
    self.maximize_btn.Position = UDim2.new(0, 30, 0, 0);
    self.maximize_btn.Image = "rbxassetid://9429429912";
    self.maximize_btn.ImageColor3 = utils.colors.text;
    self.maximize_btn.Parent = self.window_controls;
    
    utils:create_hover_effect(self.maximize_btn);
    
    -- // Close button
    self.close_btn = Instance.new("ImageButton");
    self.close_btn.Name = "CloseButton";
    self.close_btn.BackgroundTransparency = 1;
    self.close_btn.Size = UDim2.new(0, 30, 0, 30);
    self.close_btn.Position = UDim2.new(0, 60, 0, 0);
    self.close_btn.Image = "rbxassetid://9429430022";
    self.close_btn.ImageColor3 = utils.colors.text;
    self.close_btn.Parent = self.window_controls;
    
    utils:create_hover_effect(self.close_btn);
    
    -- // Content container
    self.content = Instance.new("Frame");
    self.content.Name = "Content";
    self.content.BackgroundColor3 = utils.colors.background;
    self.content.BackgroundTransparency = 1;
    self.content.Size = UDim2.new(1, 0, 1, -30);
    self.content.Position = UDim2.new(0, 0, 0, 30);
    self.content.Parent = self.main_frame;
    
    return self.main_frame;
end

return ui;
