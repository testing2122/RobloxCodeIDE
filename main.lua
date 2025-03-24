-- // moonlight code ide for roblox
-- // a beautiful lua code editor with file explorer, syntax highlighting, and more

-- // load dependencies directly with http get to enable running the whole ide with just one loadstring
local function load_module(name)
    local urls = {
        utils = "https://raw.githubusercontent.com/username/RobloxCodeIDE/main/utils.lua",
        config = "https://raw.githubusercontent.com/username/RobloxCodeIDE/main/config.lua",
        themes_manager = "https://raw.githubusercontent.com/username/RobloxCodeIDE/main/themesManager.lua",
        file_explorer = "https://raw.githubusercontent.com/username/RobloxCodeIDE/main/fileExplorer.lua",
        code_editor = "https://raw.githubusercontent.com/username/RobloxCodeIDE/main/codeEditor.lua",
        functions = "https://raw.githubusercontent.com/username/RobloxCodeIDE/main/functions.lua",
        ui = "https://raw.githubusercontent.com/username/RobloxCodeIDE/main/ui.lua"
    };
    
    local success, result = pcall(function()
        return loadstring(game:HttpGet(urls[name]))();
    end);
    
    if success then
        return result;
    else
        warn("Failed to load module: " .. name .. " | Error: " .. tostring(result));
        return nil;
    end
end

-- // services
local plrs = game:GetService("Players");
local uis = game:GetService("UserInputService");
local rs = game:GetService("RunService");

-- // variables
local lp = plrs.LocalPlayer;
local mouse = lp:GetMouse();

-- // load modules
local utils = load_module("utils");
local config = load_module("config");
local themes_mgr = load_module("themes_manager");
local funcs = load_module("functions");
local ui_module = load_module("ui");

-- // check if modules loaded correctly
if not (utils and config and themes_mgr and funcs and ui_module) then
    error("Failed to load required modules");
    return;
end

local ide = {};
ide.windows = {};
ide.current_file = nil;
ide.open_files = {};
ide.session_data = {
    open_files = {},
    current_file = nil,
    cursor_positions = {},
    theme = "moonlight"
};

-- // load previous session if available
local prev_session = funcs.config:load_session();
if prev_session then
    ide.session_data = prev_session;
end

-- // create main window
function ide:create_main_window()
    local main_ui = ui_module:create_ide();
    
    -- // create content layout
    local content = main_ui.Content;
    
    -- // file explorer
    local file_explorer = load_module("file_explorer").new(content);
    file_explorer.container.Size = UDim2.new(0, config.file_explorer.width, 1, 0);
    
    -- // code editor container
    local editor_container = Instance.new("Frame");
    editor_container.Name = "EditorContainer";
    editor_container.BackgroundTransparency = 1;
    editor_container.Size = UDim2.new(1, -config.file_explorer.width, 1, 0);
    editor_container.Position = UDim2.new(0, config.file_explorer.width, 0, 0);
    editor_container.Parent = content;
    
    -- // create code editor
    local code_editor = load_module("code_editor").new(editor_container);
    
    -- // handle file selection
    file_explorer:set_select_callback(function(path, is_folder)
        if not is_folder then
            ide.current_file = path;
        end
    end);
    
    -- // handle file opening
    file_explorer:set_file_open_callback(function(path)
        self:open_file(path, code_editor);
    end);
    
    -- // store references
    self.main_window = {
        ui = main_ui,
        file_explorer = file_explorer,
        code_editor = code_editor
    };
    
    -- // connect window controls
    self:connect_window_controls();
    
    -- // window dragging
    self:make_draggable(main_ui, main_ui.TitleBar);
    
    -- // load previous files
    if #ide.session_data.open_files > 0 then
        for _, file_path in ipairs(ide.session_data.open_files) do
            if funcs.fs:file_exists(file_path) then
                self:open_file(file_path, code_editor);
            end
        end
        
        -- // open last active file
        if ide.session_data.current_file and funcs.fs:file_exists(ide.session_data.current_file) then
            self:open_file(ide.session_data.current_file, code_editor);
        end
    end
    
    return self.main_window;
end

-- // make a frame draggable
function ide:make_draggable(frame, handle)
    local dragging = false;
    local dragInput;
    local dragStart;
    local startPos;
    
    handle = handle or frame;
    
    local function update(input)
        local delta = input.Position - dragStart;
        frame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        );
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true;
            dragStart = input.Position;
            startPos = frame.Position;
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false;
                end
            end);
        end
    end);
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input;
        end
    end);
    
    uis.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input);
        end
    end);
end

-- // connect window control buttons
function ide:connect_window_controls()
    local window = self.main_window;
    
    -- // minimize button
    window.ui.TitleBar.WindowControls.MinimizeButton.MouseButton1Click:Connect(function()
        window.ui.Visible = false;
    end);
    
    -- // maximize button
    local maximized = false;
    local original_size, original_pos;
    
    window.ui.TitleBar.WindowControls.MaximizeButton.MouseButton1Click:Connect(function()
        if not maximized then
            original_size = window.ui.Size;
            original_pos = window.ui.Position;
            
            window.ui.Size = UDim2.new(1, 0, 1, 0);
            window.ui.Position = UDim2.new(0, 0, 0, 0);
            maximized = true;
        else
            window.ui.Size = original_size;
            window.ui.Position = original_pos;
            maximized = false;
        end
    end);
    
    -- // close button
    window.ui.TitleBar.WindowControls.CloseButton.MouseButton1Click:Connect(function()
        self:save_session();
        window.ui.Parent:Destroy();
    end);
    
    -- // global key to show/hide
    uis.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.F11 then
            window.ui.Visible = not window.ui.Visible;
        end
    end);
end

-- // open a file in the editor
function ide:open_file(path, editor)
    if not editor then
        if not self.main_window or not self.main_window.code_editor then
            return false;
        end
        editor = self.main_window.code_editor;
    end
    
    local success = editor:load_file(path);
    
    if success then
        ide.current_file = path;
        
        -- // update session data
        if not table.find(ide.session_data.open_files, path) then
            table.insert(ide.session_data.open_files, path);
        end
        ide.session_data.current_file = path;
        
        -- // set cursor position if available
        if ide.session_data.cursor_positions[path] then
            editor.cursor_pos = ide.session_data.cursor_positions[path];
            editor:update_cursor();
        end
        
        return true;
    end
    
    return false;
end

-- // save current session data
function ide:save_session()
    if not self.main_window or not self.main_window.code_editor then 
        return false;
    end
    
    -- // save cursor position
    if ide.current_file then
        ide.session_data.cursor_positions[ide.current_file] = {
            line = self.main_window.code_editor.cursor_pos.line,
            col = self.main_window.code_editor.cursor_pos.col
        };
    end
    
    -- // update theme
    ide.session_data.theme = themes_mgr:get_current_theme().name:lower();
    
    -- // save session to file
    funcs.config:save_session(ide.session_data);
    
    return true;
end

-- // create settings window
function ide:create_settings_window()
    -- // create window
    local settings_gui = Instance.new("ScreenGui");
    settings_gui.Name = "CodeIDESettings";
    settings_gui.ResetOnSpawn = false;
    settings_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
    settings_gui.Parent = lp:WaitForChild("PlayerGui");
    
    local settings_frame = Instance.new("Frame");
    settings_frame.Name = "SettingsFrame";
    settings_frame.BackgroundColor3 = utils.colors.background;
    settings_frame.Size = UDim2.new(0, 500, 0, 400);
    settings_frame.Position = UDim2.new(0.5, -250, 0.5, -200);
    settings_frame.Parent = settings_gui;
    
    utils:create_corner(settings_frame, 8);
    
    -- // shadow
    local shadow = Instance.new("ImageLabel");
    shadow.Name = "Shadow";
    shadow.BackgroundTransparency = 1;
    shadow.Size = UDim2.new(1, 30, 1, 30);
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0);
    shadow.AnchorPoint = Vector2.new(0.5, 0.5);
    shadow.Image = "rbxassetid://5028857084";
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0);
    shadow.ImageTransparency = 0.5;
    shadow.ScaleType = Enum.ScaleType.Slice;
    shadow.SliceCenter = Rect.new(24, 24, 276, 276);
    shadow.ZIndex = 0;
    shadow.Parent = settings_frame;
    
    -- // title bar
    local title_bar = Instance.new("Frame");
    title_bar.Name = "TitleBar";
    title_bar.BackgroundColor3 = utils.colors.primary;
    title_bar.Size = UDim2.new(1, 0, 0, 30);
    title_bar.Parent = settings_frame;
    
    utils:create_corner(title_bar, 8);
    
    local corner_fix = Instance.new("Frame");
    corner_fix.Name = "CornerFix";
    corner_fix.BackgroundColor3 = utils.colors.primary;
    corner_fix.BorderSizePixel = 0;
    corner_fix.Size = UDim2.new(1, 0, 0, 8);
    corner_fix.Position = UDim2.new(0, 0, 1, -8);
    corner_fix.ZIndex = 0;
    corner_fix.Parent = title_bar;
    
    -- // title
    local title = Instance.new("TextLabel");
    title.Name = "Title";
    title.BackgroundTransparency = 1;
    title.Size = UDim2.new(1, -40, 1, 0);
    title.Position = UDim2.new(0, 10, 0, 0);
    title.Font = utils.fonts.bold;
    title.TextSize = 16;
    title.TextColor3 = utils.colors.text;
    title.TextXAlignment = Enum.TextXAlignment.Left;
    title.Text = "Settings";
    title.Parent = title_bar;
    
    -- // close button
    local close_btn = Instance.new("ImageButton");
    close_btn.Name = "CloseButton";
    close_btn.BackgroundTransparency = 1;
    close_btn.Size = UDim2.new(0, 30, 0, 30);
    close_btn.Position = UDim2.new(1, -30, 0, 0);
    close_btn.Image = "rbxassetid://9429430022";
    close_btn.ImageColor3 = utils.colors.text;
    close_btn.Parent = title_bar;
    
    utils:create_hover_effect(close_btn);
    
    -- // content
    local content = Instance.new("ScrollingFrame");
    content.Name = "Content";
    content.BackgroundColor3 = utils.colors.background;
    content.BackgroundTransparency = 1;
    content.Size = UDim2.new(1, -20, 1, -80);
    content.Position = UDim2.new(0, 10, 0, 40);
    content.ScrollBarThickness = 4;
    content.ScrollBarImageColor3 = utils.colors.accent;
    content.CanvasSize = UDim2.new(0, 0, 0, 650); -- // will be updated based on content
    content.Parent = settings_frame;
    
    -- // settings categories
    self:create_settings_ui(content);
    
    -- // save button
    local save_btn = ui_module.components.create_button(settings_frame, "Save Settings", function()
        self:save_settings();
        settings_gui:Destroy();
    end);
    save_btn.instance.Size = UDim2.new(0, 120, 0, 30);
    save_btn.instance.Position = UDim2.new(1, -130, 1, -40);
    
    -- // close event
    close_btn.MouseButton1Click:Connect(function()
        settings_gui:Destroy();
    end);
    
    -- // make draggable
    self:make_draggable(settings_frame, title_bar);
    
    return settings_gui;
end

-- // create settings UI
function ide:create_settings_ui(parent)
    local padding = 10;
    local y_pos = 0;
    
    -- // appearance section
    local appearance_label = Instance.new("TextLabel");
    appearance_label.Name = "AppearanceLabel";
    appearance_label.BackgroundTransparency = 1;
    appearance_label.Size = UDim2.new(1, 0, 0, 30);
    appearance_label.Position = UDim2.new(0, 0, 0, y_pos);
    appearance_label.Font = utils.fonts.bold;
    appearance_label.TextSize = 18;
    appearance_label.TextColor3 = utils.colors.accent;
    appearance_label.TextXAlignment = Enum.TextXAlignment.Left;
    appearance_label.Text = "Appearance";
    appearance_label.Parent = parent;
    
    y_pos = y_pos + 40;
    
    -- // theme selector
    local theme_names = themes_mgr:get_theme_names();
    local current_theme = themes_mgr:get_current_theme().name:lower();
    
    local theme_dropdown = ui_module.components.create_dropdown(
        parent, 
        "Theme", 
        theme_names, 
        current_theme, 
        function(selected)
            themes_mgr:set_theme(selected);
            -- // would apply theme changes to UI
        end
    );
    theme_dropdown.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    y_pos = y_pos + 80;
    
    -- // editor section
    local editor_label = Instance.new("TextLabel");
    editor_label.Name = "EditorLabel";
    editor_label.BackgroundTransparency = 1;
    editor_label.Size = UDim2.new(1, 0, 0, 30);
    editor_label.Position = UDim2.new(0, 0, 0, y_pos);
    editor_label.Font = utils.fonts.bold;
    editor_label.TextSize = 18;
    editor_label.TextColor3 = utils.colors.accent;
    editor_label.TextXAlignment = Enum.TextXAlignment.Left;
    editor_label.Text = "Editor";
    editor_label.Parent = parent;
    
    y_pos = y_pos + 40;
    
    -- // font size slider
    local font_slider = ui_module.components.create_slider(
        parent,
        "Font Size",
        8,
        24,
        config.editor.font_size,
        function(value)
            config.editor.font_size = value;
            -- // would apply font size changes
        end
    );
    font_slider.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    y_pos = y_pos + 60;
    
    -- // line height slider
    local line_height_slider = ui_module.components.create_slider(
        parent,
        "Line Height",
        1,
        2,
        config.editor.line_height,
        function(value)
            config.editor.line_height = value;
            -- // would apply line height changes
        end
    );
    line_height_slider.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    y_pos = y_pos + 60;
    
    -- // tab size slider
    local tab_slider = ui_module.components.create_slider(
        parent,
        "Tab Size",
        2,
        8,
        config.editor.tab_size,
        function(value)
            config.editor.tab_size = math.floor(value);
            -- // would apply tab size changes
        end
    );
    tab_slider.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    y_pos = y_pos + 60;
    
    -- // toggles
    local show_line_numbers = ui_module.components.create_toggle(
        parent,
        "Show Line Numbers",
        config.editor.show_line_numbers,
        function(value)
            config.editor.show_line_numbers = value;
            -- // would toggle line numbers
        end
    );
    show_line_numbers.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    y_pos = y_pos + 40;
    
    local highlight_line = ui_module.components.create_toggle(
        parent,
        "Highlight Current Line",
        config.editor.highlight_line,
        function(value)
            config.editor.highlight_line = value;
            -- // would toggle line highlight
        end
    );
    highlight_line.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    y_pos = y_pos + 40;
    
    local word_wrap = ui_module.components.create_toggle(
        parent,
        "Word Wrap",
        config.editor.word_wrap,
        function(value)
            config.editor.word_wrap = value;
            -- // would toggle word wrap
        end
    );
    word_wrap.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    y_pos = y_pos + 40;
    
    local auto_indent = ui_module.components.create_toggle(
        parent,
        "Auto Indent",
        config.editor.auto_indent,
        function(value)
            config.editor.auto_indent = value;
            -- // would toggle auto indent
        end
    );
    auto_indent.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    y_pos = y_pos + 40;
    
    local bracket_completion = ui_module.components.create_toggle(
        parent,
        "Auto Bracket Completion",
        config.editor.auto_bracket_completion,
        function(value)
            config.editor.auto_bracket_completion = value;
            -- // would toggle bracket completion
        end
    );
    bracket_completion.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    y_pos = y_pos + 60;
    
    -- // auto save section
    local autosave_label = Instance.new("TextLabel");
    autosave_label.Name = "AutosaveLabel";
    autosave_label.BackgroundTransparency = 1;
    autosave_label.Size = UDim2.new(1, 0, 0, 30);
    autosave_label.Position = UDim2.new(0, 0, 0, y_pos);
    autosave_label.Font = utils.fonts.bold;
    autosave_label.TextSize = 18;
    autosave_label.TextColor3 = utils.colors.accent;
    autosave_label.TextXAlignment = Enum.TextXAlignment.Left;
    autosave_label.Text = "Auto Save";
    autosave_label.Parent = parent;
    
    y_pos = y_pos + 40;
    
    local auto_save = ui_module.components.create_toggle(
        parent,
        "Enable Auto Save",
        config.auto_save.enabled,
        function(value)
            config.auto_save.enabled = value;
            -- // would toggle auto save
        end
    );
    auto_save.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    y_pos = y_pos + 40;
    
    local auto_save_interval = ui_module.components.create_slider(
        parent,
        "Auto Save Interval (seconds)",
        10,
        300,
        config.auto_save.interval,
        function(value)
            config.auto_save.interval = math.floor(value);
            -- // would update auto save interval
        end
    );
    auto_save_interval.instance.Position = UDim2.new(0, 0, 0, y_pos);
    
    -- // update canvas size based on content
    parent.CanvasSize = UDim2.new(0, 0, 0, y_pos + 100);
end

-- // save settings
function ide:save_settings()
    funcs.config:save_settings(config);
end

-- // initialize the IDE
function ide:init()
    self:create_main_window();
    
    -- // setup auto-save if enabled
    if config.auto_save.enabled and self.main_window and self.main_window.code_editor then
        spawn(function()
            while true do
                wait(config.auto_save.interval);
                if ide.current_file and self.main_window and self.main_window.code_editor.modified then
                    self.main_window.code_editor:save_file();
                end
            end
        end);
    end
    
    -- // auto-save session when game closes
    lp.OnTeleport:Connect(function()
        self:save_session();
    end);
    
    -- // create settings shortcut
    uis.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.F2 then
            self:create_settings_window();
        end
    end);
    
    return self;
end

-- // initialize and return the IDE instance
return ide:init();
