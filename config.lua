-- // configuration for roblox code ide
local config = {
    version = "1.0.0";
    
    -- // ui settings
    ui = {
        width = 800;
        height = 600;
        min_width = 400;
        min_height = 300;
        title = "Roblox Code IDE";
        draggable = true;
        resizable = true;
    };
    
    -- // editor settings
    editor = {
        font_size = 14;
        line_height = 1.5;
        tab_size = 4;
        show_line_numbers = true;
        auto_indent = true;
        highlight_line = true;
        word_wrap = false;
        auto_bracket_completion = true;
    };
    
    -- // file explorer settings
    file_explorer = {
        width = 200;
        show_hidden_files = false;
        default_folder = "scripts";
    };
    
    -- // theme settings (default moonlight)
    theme = {
        background = Color3.fromRGB(30, 30, 40);
        primary = Color3.fromRGB(60, 50, 80);
        secondary = Color3.fromRGB(80, 70, 100);
        accent = Color3.fromRGB(140, 120, 200);
        text = Color3.fromRGB(230, 230, 240);
        
        -- // syntax highlighting
        syntax = {
            keywords = Color3.fromRGB(190, 150, 255);     -- // function, local, if, etc
            strings = Color3.fromRGB(200, 200, 120);      -- // "text"
            comments = Color3.fromRGB(100, 110, 130);     -- // -- comments
            numbers = Color3.fromRGB(255, 150, 100);      -- // 123, 3.14
            operators = Color3.fromRGB(200, 200, 240);    -- // +, -, *, /
            globals = Color3.fromRGB(150, 200, 255);      -- // print, table, math
            brackets = Color3.fromRGB(180, 180, 200);     -- // (), [], {}
            functions = Color3.fromRGB(100, 200, 200);    -- // function calls
            variables = Color3.fromRGB(230, 230, 240);    -- // normal variables
        };
    };
    
    -- // keyboard shortcuts
    shortcuts = {
        save = {
            {"Ctrl", "S"};
        };
        save_as = {
            {"Ctrl", "Shift", "S"};
        };
        open = {
            {"Ctrl", "O"};
        };
        new_file = {
            {"Ctrl", "N"};
        };
        find = {
            {"Ctrl", "F"};
        };
        replace = {
            {"Ctrl", "H"};
        };
        undo = {
            {"Ctrl", "Z"};
        };
        redo = {
            {"Ctrl", "Y"};
            {"Ctrl", "Shift", "Z"};
        };
        run_code = {
            {"F5"};
        };
    };
    
    -- // auto save settings
    auto_save = {
        enabled = true;
        interval = 60; -- // seconds
    };
    
    -- // backup settings
    backup = {
        enabled = true;
        interval = 300; -- // 5 minutes
        max_backups = 5;
    };
};

return config;
