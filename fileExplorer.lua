-- // file explorer for code ide
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/username/RobloxCodeIDE/main/utils.lua"))();
local config = loadstring(game:HttpGet("https://raw.githubusercontent.com/username/RobloxCodeIDE/main/config.lua"))();

local plrs = game:GetService("Players");
local tweenservice = game:GetService("TweenService");

local explorer = {};
explorer.__index = explorer;

-- // file icons by extension
local file_icons = {
    ["lua"] = "rbxassetid://9430740606", -- // lua script icon
    ["txt"] = "rbxassetid://9430779801", -- // text file icon
    ["json"] = "rbxassetid://9430864963", -- // json file icon
    ["folder"] = "rbxassetid://9430822579", -- // folder icon
    ["default"] = "rbxassetid://9430740606" -- // default file icon
};

-- // create a new file explorer instance
function explorer.new(parent)
    local self = setmetatable({}, explorer);
    
    self.parent = parent;
    self.files = {};
    self.folders = {};
    self.current_path = "";
    self.selected_item = nil;
    
    -- // initialize ui
    self:init_ui();
    
    return self;
end

-- // initialize the ui elements
function explorer:init_ui()
    -- // container
    self.container = Instance.new("Frame");
    self.container.Name = "FileExplorer";
    self.container.BackgroundColor3 = utils.colors.background;
    self.container.BorderSizePixel = 0;
    self.container.Size = UDim2.new(0, config.file_explorer.width, 1, 0);
    self.container.Parent = self.parent;
    
    -- // header
    self.header = Instance.new("Frame");
    self.header.Name = "Header";
    self.header.BackgroundColor3 = utils.colors.primary;
    self.header.BorderSizePixel = 0;
    self.header.Size = UDim2.new(1, 0, 0, 30);
    self.header.Parent = self.container;
    
    utils:create_corner(self.header, 4);
    
    self.title = Instance.new("TextLabel");
    self.title.Name = "Title";
    self.title.BackgroundTransparency = 1;
    self.title.Size = UDim2.new(1, -10, 1, 0);
    self.title.Position = UDim2.new(0, 10, 0, 0);
    self.title.Font = utils.fonts.semibold;
    self.title.TextSize = 14;
    self.title.TextColor3 = utils.colors.text;
    self.title.TextXAlignment = Enum.TextXAlignment.Left;
    self.title.Text = "Files";
    self.title.Parent = self.header;
    
    -- // toolbar
    self.toolbar = Instance.new("Frame");
    self.toolbar.Name = "Toolbar";
    self.toolbar.BackgroundColor3 = utils.colors.primary;
    self.toolbar.BorderSizePixel = 0;
    self.toolbar.Size = UDim2.new(1, 0, 0, 30);
    self.toolbar.Position = UDim2.new(0, 0, 0, 35);
    self.toolbar.Parent = self.container;
    
    utils:create_corner(self.toolbar, 4);
    
    -- // create new file button
    self.new_file_btn = Instance.new("ImageButton");
    self.new_file_btn.Name = "NewFileButton";
    self.new_file_btn.BackgroundColor3 = utils.colors.secondary;
    self.new_file_btn.Size = UDim2.new(0, 25, 0, 25);
    self.new_file_btn.Position = UDim2.new(0, 5, 0, 2.5);
    self.new_file_btn.Image = "rbxassetid://9430740606";
    self.new_file_btn.Parent = self.toolbar;
    
    utils:create_corner(self.new_file_btn, 4);
    utils:create_hover_effect(self.new_file_btn);
    utils:create_pop_effect(self.new_file_btn);
    
    -- // create new folder button
    self.new_folder_btn = Instance.new("ImageButton");
    self.new_folder_btn.Name = "NewFolderButton";
    self.new_folder_btn.BackgroundColor3 = utils.colors.secondary;
    self.new_folder_btn.Size = UDim2.new(0, 25, 0, 25);
    self.new_folder_btn.Position = UDim2.new(0, 35, 0, 2.5);
    self.new_folder_btn.Image = "rbxassetid://9430822579";
    self.new_folder_btn.Parent = self.toolbar;
    
    utils:create_corner(self.new_folder_btn, 4);
    utils:create_hover_effect(self.new_folder_btn);
    utils:create_pop_effect(self.new_folder_btn);
    
    -- // refresh button
    self.refresh_btn = Instance.new("ImageButton");
    self.refresh_btn.Name = "RefreshButton";
    self.refresh_btn.BackgroundColor3 = utils.colors.secondary;
    self.refresh_btn.Size = UDim2.new(0, 25, 0, 25);
    self.refresh_btn.Position = UDim2.new(0, 65, 0, 2.5);
    self.refresh_btn.Image = "rbxassetid://9429892163";
    self.refresh_btn.Parent = self.toolbar;
    
    utils:create_corner(self.refresh_btn, 4);
    utils:create_hover_effect(self.refresh_btn);
    utils:create_pop_effect(self.refresh_btn);
    
    -- // navigate up button
    self.up_btn = Instance.new("ImageButton");
    self.up_btn.Name = "UpButton";
    self.up_btn.BackgroundColor3 = utils.colors.secondary;
    self.up_btn.Size = UDim2.new(0, 25, 0, 25);
    self.up_btn.Position = UDim2.new(0, 95, 0, 2.5);
    self.up_btn.Image = "rbxassetid://9429892492";
    self.up_btn.Parent = self.toolbar;
    
    utils:create_corner(self.up_btn, 4);
    utils:create_hover_effect(self.up_btn);
    utils:create_pop_effect(self.up_btn);
    
    -- // files container
    self.scroll_frame = Instance.new("ScrollingFrame");
    self.scroll_frame.Name = "FilesContainer";
    self.scroll_frame.BackgroundColor3 = utils.colors.background;
    self.scroll_frame.BorderSizePixel = 0;
    self.scroll_frame.Size = UDim2.new(1, 0, 1, -70);
    self.scroll_frame.Position = UDim2.new(0, 0, 0, 70);
    self.scroll_frame.ScrollBarThickness = 4;
    self.scroll_frame.ScrollBarImageColor3 = utils.colors.accent;
    self.scroll_frame.CanvasSize = UDim2.new(0, 0, 0, 0);
    self.scroll_frame.Parent = self.container;
    
    -- // list layout for files
    self.list_layout = Instance.new("UIListLayout");
    self.list_layout.SortOrder = Enum.SortOrder.Name;
    self.list_layout.Padding = UDim.new(0, 2);
    self.list_layout.Parent = self.scroll_frame;
    
    -- // connect events
    self:connect_events();
end

-- // connect ui events
function explorer:connect_events()
    self.new_file_btn.MouseButton1Click:Connect(function()
        self:create_new_file();
    end);
    
    self.new_folder_btn.MouseButton1Click:Connect(function()
        self:create_new_folder();
    end);
    
    self.refresh_btn.MouseButton1Click:Connect(function()
        self:refresh();
    end);
    
    self.up_btn.MouseButton1Click:Connect(function()
        self:navigate_up();
    end);
    
    -- // update canvas size when contents change
    self.list_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.scroll_frame.CanvasSize = UDim2.new(0, 0, 0, self.list_layout.AbsoluteContentSize.Y);
    end);
end

-- // create a file item in the explorer
function explorer:create_file_item(name, is_folder, path)
    local item = Instance.new("Frame");
    item.Name = name;
    item.BackgroundColor3 = utils.colors.secondary;
    item.BackgroundTransparency = 0.8;
    item.Size = UDim2.new(1, -10, 0, 25);
    item.Parent = self.scroll_frame;
    
    utils:create_corner(item, 4);
    
    local icon = Instance.new("ImageLabel");
    icon.Name = "Icon";
    icon.BackgroundTransparency = 1;
    icon.Size = UDim2.new(0, 16, 0, 16);
    icon.Position = UDim2.new(0, 5, 0, 4);
    
    if is_folder then
        icon.Image = file_icons.folder;
    else
        local ext = name:match("%.([^%.]+)$") or "";
        icon.Image = file_icons[ext:lower()] or file_icons.default;
    end
    
    icon.Parent = item;
    
    local label = Instance.new("TextLabel");
    label.Name = "Label";
    label.BackgroundTransparency = 1;
    label.Size = UDim2.new(1, -30, 1, 0);
    label.Position = UDim2.new(0, 25, 0, 0);
    label.Font = utils.fonts.regular;
    label.TextSize = 14;
    label.TextColor3 = utils.colors.text;
    label.TextXAlignment = Enum.TextXAlignment.Left;
    label.Text = name;
    label.TextTruncate = Enum.TextTruncate.AtEnd;
    label.Parent = item;
    
    -- // handle item selection
    item.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:select_item(item, path .. "/" .. name, is_folder);
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:show_context_menu(item, path .. "/" .. name, is_folder);
        end
    end);
    
    -- // handle double click
    local last_click = 0;
    item.MouseButton1Click:Connect(function()
        local now = tick();
        if now - last_click < 0.5 then
            -- // double click
            if is_folder then
                self:navigate_to(path .. "/" .. name);
            else
                self:open_file(path .. "/" .. name);
            end
        end
        last_click = now;
    end);
    
    utils:create_hover_effect(item);
    
    return item;
end

-- // create a new file
function explorer:create_new_file()
    -- // prompt for file name
    -- // add logic to create file
    -- // would use an external prompt UI
    -- // refresh directory after creation
end

-- // create a new folder
function explorer:create_new_folder()
    -- // prompt for folder name
    -- // add logic to create folder
    -- // would use an external prompt UI
    -- // refresh directory after creation
end

-- // navigate up one directory
function explorer:navigate_up()
    local path = self.current_path;
    local parent = path:match("(.+)/[^/]+$");
    
    if parent then
        self:navigate_to(parent);
    else
        self:navigate_to("");
    end
end

-- // navigate to a specific directory
function explorer:navigate_to(path)
    self.current_path = path;
    self:refresh();
end

-- // refresh the current directory
function explorer:refresh()
    -- // clear current items
    for _, child in pairs(self.scroll_frame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy();
        end
    end
    
    -- // would need to read files from filesystem, simplified here
    -- // this would use specific Roblox exploit file API calls
    
    -- // update path display
    self.title.Text = self.current_path == "" and "Files" or self.current_path;
end

-- // select a file or folder
function explorer:select_item(item, path, is_folder)
    if self.selected_item then
        self.selected_item.BackgroundColor3 = utils.colors.secondary;
        self.selected_item.BackgroundTransparency = 0.8;
    end
    
    item.BackgroundColor3 = utils.colors.accent;
    item.BackgroundTransparency = 0.5;
    self.selected_item = item;
    
    -- // callback for selection
    if self.on_select then
        self.on_select(path, is_folder);
    end
end

-- // show context menu for a file or folder
function explorer:show_context_menu(item, path, is_folder)
    -- // would implement context menu with options like:
    -- // rename, delete, copy, move, etc.
end

-- // open a file
function explorer:open_file(path)
    -- // callback for file open
    if self.on_file_open then
        self.on_file_open(path);
    end
end

-- // delete a file or folder
function explorer:delete_item(path, is_folder)
    -- // add logic to delete file or folder
    -- // would use exploit file API calls
    -- // refresh directory after deletion
end

-- // set callback for file selection
function explorer:set_select_callback(callback)
    self.on_select = callback;
end

-- // set callback for file open
function explorer:set_file_open_callback(callback)
    self.on_file_open = callback;
end

return explorer;
