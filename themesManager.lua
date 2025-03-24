-- // theme manager for code ide
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/testing2122/RobloxCodeIDE/main/utils.lua"))();
local config = loadstring(game:HttpGet("https://raw.githubusercontent.com/testing2122/RobloxCodeIDE/main/config.lua"))();

local plrs = game:GetService("Players");
local lp = plrs.LocalPlayer;

local themes_mgr = {};
local themes = {};

-- // predefined themes
themes.moonlight = {
    name = "Moonlight";
    author = "CodeIDE";
    background = Color3.fromRGB(30, 30, 40);
    primary = Color3.fromRGB(60, 50, 80);
    secondary = Color3.fromRGB(80, 70, 100);
    accent = Color3.fromRGB(140, 120, 200);
    text = Color3.fromRGB(230, 230, 240);
    syntax = {
        keywords = Color3.fromRGB(190, 150, 255);
        strings = Color3.fromRGB(200, 200, 120);
        comments = Color3.fromRGB(100, 110, 130);
        numbers = Color3.fromRGB(255, 150, 100);
        operators = Color3.fromRGB(200, 200, 240);
        globals = Color3.fromRGB(150, 200, 255);
        brackets = Color3.fromRGB(180, 180, 200);
        functions = Color3.fromRGB(100, 200, 200);
        variables = Color3.fromRGB(230, 230, 240);
    };
};

themes.dark = {
    name = "Dark";
    author = "CodeIDE";
    background = Color3.fromRGB(25, 25, 25);
    primary = Color3.fromRGB(40, 40, 40);
    secondary = Color3.fromRGB(60, 60, 60);
    accent = Color3.fromRGB(100, 100, 255);
    text = Color3.fromRGB(230, 230, 230);
    syntax = {
        keywords = Color3.fromRGB(150, 150, 255);
        strings = Color3.fromRGB(200, 200, 100);
        comments = Color3.fromRGB(100, 100, 100);
        numbers = Color3.fromRGB(255, 100, 100);
        operators = Color3.fromRGB(200, 200, 200);
        globals = Color3.fromRGB(100, 200, 255);
        brackets = Color3.fromRGB(180, 180, 180);
        functions = Color3.fromRGB(100, 200, 150);
        variables = Color3.fromRGB(220, 220, 220);
    };
};

themes.light = {
    name = "Light";
    author = "CodeIDE";
    background = Color3.fromRGB(240, 240, 245);
    primary = Color3.fromRGB(220, 220, 225);
    secondary = Color3.fromRGB(200, 200, 205);
    accent = Color3.fromRGB(100, 100, 200);
    text = Color3.fromRGB(30, 30, 30);
    syntax = {
        keywords = Color3.fromRGB(120, 80, 200);
        strings = Color3.fromRGB(180, 120, 50);
        comments = Color3.fromRGB(130, 130, 130);
        numbers = Color3.fromRGB(200, 80, 80);
        operators = Color3.fromRGB(50, 50, 50);
        globals = Color3.fromRGB(50, 120, 200);
        brackets = Color3.fromRGB(80, 80, 80);
        functions = Color3.fromRGB(50, 150, 150);
        variables = Color3.fromRGB(30, 30, 30);
    };
};

themes.synthwave = {
    name = "Synthwave";
    author = "CodeIDE";
    background = Color3.fromRGB(30, 20, 40);
    primary = Color3.fromRGB(50, 30, 70);
    secondary = Color3.fromRGB(70, 40, 100);
    accent = Color3.fromRGB(255, 80, 200);
    text = Color3.fromRGB(240, 220, 255);
    syntax = {
        keywords = Color3.fromRGB(255, 100, 255);
        strings = Color3.fromRGB(255, 180, 100);
        comments = Color3.fromRGB(100, 80, 130);
        numbers = Color3.fromRGB(255, 100, 150);
        operators = Color3.fromRGB(220, 180, 255);
        globals = Color3.fromRGB(100, 200, 255);
        brackets = Color3.fromRGB(200, 150, 255);
        functions = Color3.fromRGB(100, 255, 200);
        variables = Color3.fromRGB(240, 220, 255);
    };
};

-- // initialize with default theme from config
themes_mgr.current_theme = themes.moonlight;

-- // get available theme names
function themes_mgr:get_theme_names()
    local names = {};
    for name, _ in pairs(themes) do
        table.insert(names, name);
    end
    return names;
end

-- // set current theme by name
function themes_mgr:set_theme(theme_name)
    local theme = themes[theme_name:lower()];
    if theme then
        self.current_theme = theme;
        return true;
    end
    return false;
end

-- // get current theme
function themes_mgr:get_current_theme()
    return self.current_theme;
end

-- // add new custom theme
function themes_mgr:add_theme(name, theme_data)
    if type(name) ~= "string" or type(theme_data) ~= "table" then
        return false;
    end
    
    -- // validate theme data
    if not theme_data.background or not theme_data.primary or not theme_data.text then
        return false;
    end
    
    themes[name:lower()] = theme_data;
    return true;
end

-- // delete a custom theme
function themes_mgr:delete_theme(name)
    if name:lower() == "moonlight" or name:lower() == "dark" or 
       name:lower() == "light" or name:lower() == "synthwave" then
        return false; -- // prevent deleting default themes
    end
    
    if themes[name:lower()] then
        themes[name:lower()] = nil;
        return true;
    end
    return false;
end

-- // save custom themes to file
function themes_mgr:save_themes()
    local custom_themes = {};
    
    for name, theme in pairs(themes) do
        if name ~= "moonlight" and name ~= "dark" and name ~= "light" and name ~= "synthwave" then
            custom_themes[name] = theme;
        end
    end
    
    -- // convert colors to serializable format
    local serializable = {};
    for name, theme in pairs(custom_themes) do
        serializable[name] = {
            name = theme.name;
            author = theme.author;
            background = {theme.background.R, theme.background.G, theme.background.B};
            primary = {theme.primary.R, theme.primary.G, theme.primary.B};
            secondary = {theme.secondary.R, theme.secondary.G, theme.secondary.B};
            accent = {theme.accent.R, theme.accent.G, theme.accent.B};
            text = {theme.text.R, theme.text.G, theme.text.B};
            syntax = {};
        };
        
        for syntax_name, color in pairs(theme.syntax) do
            serializable[name].syntax[syntax_name] = {color.R, color.G, color.B};
        end
    end
    
    -- // encode and save
    local json_data = utils:encode_json(serializable);
    writefile("codeidemoonlight_themes.json", json_data);
    
    return true;
end

-- // load custom themes from file
function themes_mgr:load_themes()
    if isfile("codeidemoonlight_themes.json") then
        local json_data = readfile("codeidemoonlight_themes.json");
        local loaded = utils:decode_json(json_data);
        
        for name, theme_data in pairs(loaded) do
            -- // convert back to Color3
            local theme = {
                name = theme_data.name;
                author = theme_data.author;
                background = Color3.new(unpack(theme_data.background));
                primary = Color3.new(unpack(theme_data.primary));
                secondary = Color3.new(unpack(theme_data.secondary));
                accent = Color3.new(unpack(theme_data.accent));
                text = Color3.new(unpack(theme_data.text));
                syntax = {};
            };
            
            for syntax_name, color_array in pairs(theme_data.syntax) do
                theme.syntax[syntax_name] = Color3.new(unpack(color_array));
            end
            
            themes[name] = theme;
        end
        
        return true;
    end
    return false;
end

-- // export theme to clipboard
function themes_mgr:export_theme(theme_name)
    local theme = themes[theme_name:lower()];
    if not theme then return false; end
    
    -- // prepare theme for export
    local export_data = {
        name = theme.name;
        author = theme.author;
        background = {theme.background.R, theme.background.G, theme.background.B};
        primary = {theme.primary.R, theme.primary.G, theme.primary.B};
        secondary = {theme.secondary.R, theme.secondary.G, theme.secondary.B};
        accent = {theme.accent.R, theme.accent.G, theme.accent.B};
        text = {theme.text.R, theme.text.G, theme.text.B};
        syntax = {};
    };
    
    for syntax_name, color in pairs(theme.syntax) do
        export_data.syntax[syntax_name] = {color.R, color.G, color.B};
    end
    
    local json_data = utils:encode_json(export_data);
    setclipboard(json_data);
    
    return true;
end

-- // import theme from clipboard
function themes_mgr:import_theme()
    local clipboard = getclipboard();
    local success, theme_data = pcall(function()
        return utils:decode_json(clipboard);
    end);
    
    if success and theme_data and theme_data.name and theme_data.background then
        -- // convert color arrays to Color3
        local theme = {
            name = theme_data.name;
            author = theme_data.author or "Imported";
            background = Color3.new(unpack(theme_data.background));
            primary = Color3.new(unpack(theme_data.primary));
            secondary = Color3.new(unpack(theme_data.secondary));
            accent = Color3.new(unpack(theme_data.accent));
            text = Color3.new(unpack(theme_data.text));
            syntax = {};
        };
        
        for syntax_name, color_array in pairs(theme_data.syntax) do
            theme.syntax[syntax_name] = Color3.new(unpack(color_array));
        end
        
        local safe_name = theme.name:gsub("[^%w]", "_"):lower();
        themes[safe_name] = theme;
        
        return safe_name;
    end
    
    return false;
end

-- // try to load themes on initialization
pcall(function()
    themes_mgr:load_themes();
end);

return themes_mgr;
