-- // code editor for ide
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/testing2122/RobloxCodeIDE/main/utils.lua"))();
local config = loadstring(game:HttpGet("https://raw.githubusercontent.com/testing2122/RobloxCodeIDE/main/config.lua"))();

local plrs = game:GetService("Players");
local uis = game:GetService("UserInputService");
local ts = game:GetService("TweenService");

local editor = {};
editor.__index = editor;

-- // lua syntax patterns for highlighting
local syntax = {
    keywords = {
        "and", "break", "do", "else", "elseif", "end", "false", "for", 
        "function", "if", "in", "local", "nil", "not", "or", "repeat", 
        "return", "then", "true", "until", "while"
    };
    
    builtins = {
        "assert", "collectgarbage", "error", "getfenv", "getmetatable", 
        "ipairs", "loadstring", "newproxy", "next", "pairs", "pcall", 
        "print", "rawequal", "rawget", "rawset", "select", "setfenv", 
        "setmetatable", "tonumber", "tostring", "type", "unpack", "xpcall"
    };
    
    -- // roblox specific globals
    roblox_globals = {
        "game", "workspace", "script", "math", "string", "table", "coroutine", 
        "os", "warn", "spawn", "Instance", "Vector2", "Vector3", "CFrame", 
        "Color3", "BrickColor", "Enum", "task", "wait", "delay", "tick"
    };
};

-- // create a new code editor instance
function editor.new(parent)
    local self = setmetatable({}, editor);
    
    self.parent = parent;
    self.current_file = nil;
    self.content = "";
    self.lines = {};
    self.line_count = 0;
    self.modified = false;
    self.cursor_pos = {line = 1, col = 1};
    self.selection = nil;
    self.scroll_pos = {x = 0, y = 0};
    self.undo_stack = {};
    self.redo_stack = {};
    self.tab_size = config.editor.tab_size;
    
    -- // initialize ui
    self:init_ui();
    
    return self;
end

-- // initialize the ui elements
function editor:init_ui()
    -- // main container
    self.container = Instance.new("Frame");
    self.container.Name = "CodeEditor";
    self.container.BackgroundColor3 = utils.colors.background;
    self.container.BorderSizePixel = 0;
    self.container.Size = UDim2.new(1, 0, 1, 0);
    self.container.Parent = self.parent;
    
    -- // editor toolbar
    self.toolbar = Instance.new("Frame");
    self.toolbar.Name = "Toolbar";
    self.toolbar.BackgroundColor3 = utils.colors.primary;
    self.toolbar.BorderSizePixel = 0;
    self.toolbar.Size = UDim2.new(1, 0, 0, 30);
    self.toolbar.Parent = self.container;
    
    utils:create_corner(self.toolbar, 4);
    
    -- // file name label
    self.file_label = Instance.new("TextLabel");
    self.file_label.Name = "FileLabel";
    self.file_label.BackgroundTransparency = 1;
    self.file_label.Size = UDim2.new(1, -200, 1, 0);
    self.file_label.Font = utils.fonts.semibold;
    self.file_label.TextSize = 14;
    self.file_label.TextColor3 = utils.colors.text;
    self.file_label.TextXAlignment = Enum.TextXAlignment.Left;
    self.file_label.Text = "Untitled";
    self.file_label.TextTruncate = Enum.TextTruncate.AtEnd;
    self.file_label.Position = UDim2.new(0, 10, 0, 0);
    self.file_label.Parent = self.toolbar;
    
    -- // save button
    self.save_btn = Instance.new("TextButton");
    self.save_btn.Name = "SaveButton";
    self.save_btn.BackgroundColor3 = utils.colors.secondary;
    self.save_btn.Size = UDim2.new(0, 60, 0, 24);
    self.save_btn.Position = UDim2.new(1, -140, 0, 3);
    self.save_btn.Font = utils.fonts.regular;
    self.save_btn.TextSize = 14;
    self.save_btn.TextColor3 = utils.colors.text;
    self.save_btn.Text = "Save";
    self.save_btn.Parent = self.toolbar;
    
    utils:create_corner(self.save_btn, 4);
    utils:create_hover_effect(self.save_btn);
    utils:create_pop_effect(self.save_btn);
    
    -- // run button
    self.run_btn = Instance.new("TextButton");
    self.run_btn.Name = "RunButton";
    self.run_btn.BackgroundColor3 = utils.colors.accent;
    self.run_btn.Size = UDim2.new(0, 60, 0, 24);
    self.run_btn.Position = UDim2.new(1, -70, 0, 3);
    self.run_btn.Font = utils.fonts.regular;
    self.run_btn.TextSize = 14;
    self.run_btn.TextColor3 = utils.colors.text;
    self.run_btn.Text = "Run";
    self.run_btn.Parent = self.toolbar;
    
    utils:create_corner(self.run_btn, 4);
    utils:create_hover_effect(self.run_btn);
    utils:create_pop_effect(self.run_btn);
    
    -- // editor container (with line numbers and code view)
    self.editor_frame = Instance.new("Frame");
    self.editor_frame.Name = "EditorFrame";
    self.editor_frame.BackgroundColor3 = utils.colors.background;
    self.editor_frame.BorderSizePixel = 0;
    self.editor_frame.Size = UDim2.new(1, 0, 1, -35);
    self.editor_frame.Position = UDim2.new(0, 0, 0, 35);
    self.editor_frame.Parent = self.container;
    
    -- // line numbers
    self.line_numbers = Instance.new("ScrollingFrame");
    self.line_numbers.Name = "LineNumbers";
    self.line_numbers.BackgroundColor3 = utils.darken_color(utils.colors.background, 0.05);
    self.line_numbers.BorderSizePixel = 0;
    self.line_numbers.Size = UDim2.new(0, 40, 1, 0);
    self.line_numbers.ScrollBarThickness = 0;
    self.line_numbers.ScrollingEnabled = false;
    self.line_numbers.Parent = self.editor_frame;
    
    -- // line numbers list layout
    self.line_numbers_layout = Instance.new("UIListLayout");
    self.line_numbers_layout.SortOrder = Enum.SortOrder.LayoutOrder;
    self.line_numbers_layout.Padding = UDim.new(0, 0);
    self.line_numbers_layout.Parent = self.line_numbers;
    
    -- // code view
    self.code_view = Instance.new("ScrollingFrame");
    self.code_view.Name = "CodeView";
    self.code_view.BackgroundColor3 = utils.colors.background;
    self.code_view.BorderSizePixel = 0;
    self.code_view.Size = UDim2.new(1, -40, 1, 0);
    self.code_view.Position = UDim2.new(0, 40, 0, 0);
    self.code_view.ScrollBarThickness = 6;
    self.code_view.ScrollingDirection = Enum.ScrollingDirection.XY;
    self.code_view.CanvasSize = UDim2.new(0, 0, 0, 0);
    self.code_view.ScrollBarImageColor3 = utils.colors.accent;
    self.code_view.Parent = self.editor_frame;
    
    -- // code view list layout
    self.code_layout = Instance.new("UIListLayout");
    self.code_layout.SortOrder = Enum.SortOrder.LayoutOrder;
    self.code_layout.Padding = UDim.new(0, 0);
    self.code_layout.Parent = self.code_view;
    
    -- // text input
    self.text_input = Instance.new("TextBox");
    self.text_input.Name = "TextInput";
    self.text_input.BackgroundTransparency = 1;
    self.text_input.Size = UDim2.new(0, 0, 0, 0);
    self.text_input.Position = UDim2.new(0, 0, 0, 0);
    self.text_input.TextTransparency = 1;
    self.text_input.ClearTextOnFocus = false;
    self.text_input.Parent = self.editor_frame;
    
    -- // cursor
    self.cursor = Instance.new("Frame");
    self.cursor.Name = "Cursor";
    self.cursor.BackgroundColor3 = utils.colors.text;
    self.cursor.BorderSizePixel = 0;
    self.cursor.Size = UDim2.new(0, 2, 0, config.editor.font_size * config.editor.line_height);
    self.cursor.Visible = false;
    self.cursor.Parent = self.code_view;
    
    -- // connect events
    self:connect_events();
    
    -- // create initial empty content
    self:set_content("");
end

-- // connect ui events
function editor:connect_events()
    -- // toolbar button events
    self.save_btn.MouseButton1Click:Connect(function()
        self:save_file();
    end);
    
    self.run_btn.MouseButton1Click:Connect(function()
        self:run_code();
    end);
    
    -- // sync scrolling between line numbers and code view
    self.code_view:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        self.line_numbers.CanvasPosition = Vector2.new(0, self.code_view.CanvasPosition.Y);
    end);
    
    -- // update canvas size when content changes
    self.code_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local content_size = self.code_layout.AbsoluteContentSize;
        local padding = 50; -- // extra padding at bottom
        self.code_view.CanvasSize = UDim2.new(0, content_size.X + 300, 0, content_size.Y + padding);
    end);
    
    -- // clipboard shortcut handling
    uis.InputBegan:Connect(function(input, processed)
        if processed then return end
        if not self.code_view:IsDescendantOf(game) then return end
        
        -- // handle shortcuts (ctrl+s, ctrl+c, ctrl+v, etc)
        if input.KeyCode == Enum.KeyCode.S and uis:IsKeyDown(Enum.KeyCode.LeftControl) then
            self:save_file();
        elseif input.KeyCode == Enum.KeyCode.V and uis:IsKeyDown(Enum.KeyCode.LeftControl) then
            self:paste_text();
        elseif input.KeyCode == Enum.KeyCode.C and uis:IsKeyDown(Enum.KeyCode.LeftControl) then
            self:copy_text();
        elseif input.KeyCode == Enum.KeyCode.X and uis:IsKeyDown(Enum.KeyCode.LeftControl) then
            self:cut_text();
        elseif input.KeyCode == Enum.KeyCode.Z and uis:IsKeyDown(Enum.KeyCode.LeftControl) then
            self:undo();
        elseif input.KeyCode == Enum.KeyCode.Y and uis:IsKeyDown(Enum.KeyCode.LeftControl) then
            self:redo();
        elseif input.KeyCode == Enum.KeyCode.F5 then
            self:run_code();
        end
    end);
    
    -- // text input handling
    self.text_input.FocusLost:Connect(function(enter_pressed)
        -- // handle text input when focus is lost
    end);
    
    -- // cursor blinking
    local blink = true;
    game:GetService("RunService").Heartbeat:Connect(function()
        if tick() % 1 < 0.5 then
            if not blink then
                blink = true;
                self.cursor.Visible = self.cursor.Visible;
            end
        else
            if blink then
                blink = false;
                self.cursor.Visible = not self.cursor.Visible;
            end
        end
    end);
    
    -- // focus handling
    self.code_view.MouseButton1Click:Connect(function()
        self.text_input:CaptureFocus();
    end);
end

-- // create a line number label
function editor:create_line_number(num)
    local label = Instance.new("TextLabel");
    label.Name = "Line" .. num;
    label.BackgroundTransparency = 1;
    label.Size = UDim2.new(1, 0, 0, config.editor.font_size * config.editor.line_height);
    label.Font = utils.fonts.monospace;
    label.TextSize = config.editor.font_size;
    label.TextColor3 = utils.colors.comments;
    label.Text = tostring(num);
    label.TextXAlignment = Enum.TextXAlignment.Center;
    label.TextYAlignment = Enum.TextYAlignment.Center;
    label.LayoutOrder = num;
    label.Parent = self.line_numbers;
    return label;
end

-- // create a code line
function editor:create_code_line(text, line_num)
    local line = Instance.new("TextLabel");
    line.Name = "Line" .. line_num;
    line.BackgroundTransparency = 1;
    line.Size = UDim2.new(1, 0, 0, config.editor.font_size * config.editor.line_height);
    line.Font = utils.fonts.monospace;
    line.TextSize = config.editor.font_size;
    line.TextColor3 = utils.colors.text;
    line.Text = text;
    line.RichText = true;
    line.TextXAlignment = Enum.TextXAlignment.Left;
    line.TextYAlignment = Enum.TextYAlignment.Center;
    line.LayoutOrder = line_num;
    
    -- // highlight line if it's the current line
    if config.editor.highlight_line and line_num == self.cursor_pos.line then
        line.BackgroundColor3 = utils.lighten_color(utils.colors.background, 0.05);
        line.BackgroundTransparency = 0;
    end
    
    -- // syntax highlighting
    if text ~= "" then
        line.Text = self:highlight_syntax(text);
    end
    
    line.Parent = self.code_view;
    return line;
end

-- // highlight lua syntax
function editor:highlight_syntax(text)
    local colored_text = text;
    
    -- // apply syntax highlighting
    
    -- // highlight keywords
    for _, keyword in ipairs(syntax.keywords) do
        colored_text = colored_text:gsub("([^%w_])()" .. keyword .. "([^%w_])",
            "%1<font color=\"" .. utils:color_to_rgb_string(config.theme.syntax.keywords) .. "\">%2" .. keyword .. "</font>%3");
    end
    
    -- // highlight builtin functions
    for _, builtin in ipairs(syntax.builtins) do
        colored_text = colored_text:gsub("([^%w_])()" .. builtin .. "([^%w_])",
            "%1<font color=\"" .. utils:color_to_rgb_string(config.theme.syntax.globals) .. "\">%2" .. builtin .. "</font>%3");
    end
    
    -- // highlight roblox globals
    for _, global in ipairs(syntax.roblox_globals) do
        colored_text = colored_text:gsub("([^%w_])()" .. global .. "([^%w_])",
            "%1<font color=\"" .. utils:color_to_rgb_string(config.theme.syntax.globals) .. "\">%2" .. global .. "</font>%3");
    end
    
    -- // highlight strings
    colored_text = colored_text:gsub("(\".-[^\\]\")", 
        "<font color=\"" .. utils:color_to_rgb_string(config.theme.syntax.strings) .. "\">%1</font>");
    colored_text = colored_text:gsub("('.-[^\\]')", 
        "<font color=\"" .. utils:color_to_rgb_string(config.theme.syntax.strings) .. "\">%1</font>");
    
    -- // highlight numbers
    colored_text = colored_text:gsub("([^%w_])(%d+%.?%d*)", 
        "%1<font color=\"" .. utils:color_to_rgb_string(config.theme.syntax.numbers) .. "\">%2</font>");
    
    -- // highlight comments
    colored_text = colored_text:gsub("(%-%-.-\n)", 
        "<font color=\"" .. utils:color_to_rgb_string(config.theme.syntax.comments) .. "\">%1</font>");
    colored_text = colored_text:gsub("(%-%-.*$)", 
        "<font color=\"" .. utils:color_to_rgb_string(config.theme.syntax.comments) .. "\">%1</font>");
    
    return colored_text;
end

-- // set editor content
function editor:set_content(content)
    self.content = content;
    self.lines = self:split_into_lines(content);
    self.line_count = #self.lines;
    self.modified = false;
    
    -- // clear existing lines
    for _, child in pairs(self.line_numbers:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy();
        end
    end
    
    for _, child in pairs(self.code_view:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy();
        end
    end
    
    -- // create line numbers and code lines
    for i, line_text in ipairs(self.lines) do
        self:create_line_number(i);
        self:create_code_line(line_text, i);
    end
    
    -- // ensure minimum of one line
    if self.line_count == 0 then
        self:create_line_number(1);
        self:create_code_line("", 1);
        self.line_count = 1;
        self.lines = {""};
    end
    
    -- // update cursor position
    self.cursor_pos = {line = 1, col = 1};
    self:update_cursor();
end

-- // split text into lines
function editor:split_into_lines(text)
    local lines = {};
    for line in (text .. "\n"):gmatch("(.-)\n") do
        table.insert(lines, line);
    end
    return lines;
end

-- // update the cursor position
function editor:update_cursor()
    -- // ensure cursor position is valid
    if self.cursor_pos.line < 1 then
        self.cursor_pos.line = 1;
    end
    if self.cursor_pos.line > self.line_count then
        self.cursor_pos.line = self.line_count;
    end
    
    local line_text = self.lines[self.cursor_pos.line] or "";
    if self.cursor_pos.col < 1 then
        self.cursor_pos.col = 1;
    end
    if self.cursor_pos.col > #line_text + 1 then
        self.cursor_pos.col = #line_text + 1;
    end
    
    -- // update cursor visual position
    local line_height = config.editor.font_size * config.editor.line_height;
    local char_width = config.editor.font_size * 0.6; -- // approximate character width
    
    local x_pos = (self.cursor_pos.col - 1) * char_width;
    local y_pos = (self.cursor_pos.line - 1) * line_height;
    
    self.cursor.Position = UDim2.new(0, x_pos, 0, y_pos);
    self.cursor.Size = UDim2.new(0, 2, 0, line_height);
    self.cursor.Visible = true;
    
    -- // update highlighted line
    if config.editor.highlight_line then
        for _, child in pairs(self.code_view:GetChildren()) do
            if child:IsA("TextLabel") then
                if child.LayoutOrder == self.cursor_pos.line then
                    child.BackgroundColor3 = utils.lighten_color(utils.colors.background, 0.05);
                    child.BackgroundTransparency = 0;
                else
                    child.BackgroundTransparency = 1;
                end
            end
        end
    end
    
    -- // scroll into view if needed
    local viewport_height = self.code_view.AbsoluteSize.Y;
    local current_scroll = self.code_view.CanvasPosition.Y;
    
    if y_pos < current_scroll then
        -- // scroll up to show cursor
        self.code_view.CanvasPosition = Vector2.new(self.code_view.CanvasPosition.X, y_pos);
    elseif y_pos + line_height > current_scroll + viewport_height then
        -- // scroll down to show cursor
        self.code_view.CanvasPosition = Vector2.new(
            self.code_view.CanvasPosition.X, 
            y_pos + line_height - viewport_height
        );
    end
end

-- // save current file
function editor:save_file()
    if not self.current_file then
        -- // need to prompt for a file name
        -- // would implement a file save dialog
        return;
    end
    
    -- // use writefile exploit function to save file
    local success, err = pcall(function()
        writefile(self.current_file, self.content);
    end);
    
    if success then
        self.modified = false;
        self.file_label.Text = self.current_file:match("[^/]+$") or "Untitled";
    else
        -- // show error message
        print("Failed to save file: " .. tostring(err));
    end
end

-- // load a file into the editor
function editor:load_file(file_path)
    if not isfile(file_path) then
        -- // show error message
        print("File not found: " .. file_path);
        return false;
    end
    
    local success, content = pcall(function()
        return readfile(file_path);
    end);
    
    if success then
        self.current_file = file_path;
        self:set_content(content);
        self.file_label.Text = file_path:match("[^/]+$") or "Untitled";
        return true;
    else
        -- // show error message
        print("Failed to read file: " .. file_path);
        return false;
    end
end

-- // run the current code
function editor:run_code()
    if self.content == "" then return end
    
    -- // save first if modified
    if self.modified and self.current_file then
        self:save_file();
    end
    
    -- // execute the code
    local success, err = pcall(function()
        return loadstring(self.content)();
    end);
    
    if not success then
        -- // show error message
        print("Error executing code: " .. tostring(err));
    end
end

-- // undo last action
function editor:undo()
    if #self.undo_stack == 0 then return end
    
    local action = table.remove(self.undo_stack);
    table.insert(self.redo_stack, {
        content = self.content,
        cursor = {line = self.cursor_pos.line, col = self.cursor_pos.col}
    });
    
    self:set_content(action.content);
    self.cursor_pos = {line = action.cursor.line, col = action.cursor.col};
    self:update_cursor();
end

-- // redo last undone action
function editor:redo()
    if #self.redo_stack == 0 then return end
    
    local action = table.remove(self.redo_stack);
    table.insert(self.undo_stack, {
        content = self.content,
        cursor = {line = self.cursor_pos.line, col = self.cursor_pos.col}
    });
    
    self:set_content(action.content);
    self.cursor_pos = {line = action.cursor.line, col = action.cursor.col};
    self:update_cursor();
end

-- // paste text at cursor position
function editor:paste_text()
    local clipboard = getclipboard();
    if not clipboard or clipboard == "" then return end
    
    -- // save for undo
    table.insert(self.undo_stack, {
        content = self.content,
        cursor = {line = self.cursor_pos.line, col = self.cursor_pos.col}
    });
    self.redo_stack = {};
    
    -- // insert clipboard text at cursor position
    local lines = self:split_into_lines(clipboard);
    
    if #lines == 1 then
        -- // single line paste
        local line = self.lines[self.cursor_pos.line];
        local before = line:sub(1, self.cursor_pos.col - 1);
        local after = line:sub(self.cursor_pos.col);
        
        self.lines[self.cursor_pos.line] = before .. lines[1] .. after;
        self.cursor_pos.col = self.cursor_pos.col + #lines[1];
    else
        -- // multi-line paste
        local current_line = self.lines[self.cursor_pos.line];
        local before = current_line:sub(1, self.cursor_pos.col - 1);
        local after = current_line:sub(self.cursor_pos.col);
        
        -- // replace current line with first part + first line of paste
        self.lines[self.cursor_pos.line] = before .. lines[1];
        
        -- // insert remaining lines
        for i = 2, #lines - 1 do
            table.insert(self.lines, self.cursor_pos.line + i - 1, lines[i]);
        end
        
        -- // add last line + remaining part of current line
        table.insert(self.lines, self.cursor_pos.line + #lines - 1, lines[#lines] .. after);
        
        -- // update cursor position
        self.cursor_pos.line = self.cursor_pos.line + #lines - 1;
        self.cursor_pos.col = #lines[#lines] + 1;
    end
    
    -- // update content and refresh
    self.content = table.concat(self.lines, "\n");
    self.line_count = #self.lines;
    self.modified = true;
    
    self:set_content(self.content);
    self:update_cursor();
end

-- // copy selected text
function editor:copy_text()
    -- // if we have a selection, copy it
    if self.selection then
        -- // would implement text selection and copying
    else
        -- // copy current line if no selection
        local line = self.lines[self.cursor_pos.line] or "";
        setclipboard(line);
    end
end

-- // cut selected text
function editor:cut_text()
    self:copy_text();
    
    -- // if we have a selection, remove it
    if self.selection then
        -- // would implement text selection and cutting
    end
end

return editor;
