-- // functions for code ide
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/username/RobloxCodeIDE/main/utils.lua"))();
local config = loadstring(game:HttpGet("https://raw.githubusercontent.com/username/RobloxCodeIDE/main/config.lua"))();

local funcs = {};

-- // file system functions that interact with the roblox exploit fs api
funcs.fs = {};

-- // read a file
function funcs.fs:read_file(path)
    if not isfile(path) then
        return nil, "File does not exist";
    end
    
    local success, content = pcall(function()
        return readfile(path);
    end);
    
    if success then
        return content;
    else
        return nil, "Failed to read file: " .. content;
    end
end

-- // write to a file
function funcs.fs:write_file(path, content)
    local success, err = pcall(function()
        writefile(path, content);
    end);
    
    if success then
        return true;
    else
        return false, "Failed to write file: " .. err;
    end
end

-- // delete a file
function funcs.fs:delete_file(path)
    if not isfile(path) then
        return false, "File does not exist";
    end
    
    local success, err = pcall(function()
        delfile(path);
    end);
    
    if success then
        return true;
    else
        return false, "Failed to delete file: " .. err;
    end
end

-- // check if a file exists
function funcs.fs:file_exists(path)
    return isfile(path);
end

-- // make a directory
function funcs.fs:make_dir(path)
    local success, err = pcall(function()
        makefolder(path);
    end);
    
    if success then
        return true;
    else
        return false, "Failed to create directory: " .. err;
    end
end

-- // delete a directory
function funcs.fs:delete_dir(path)
    if not isfolder(path) then
        return false, "Directory does not exist";
    end
    
    local success, err = pcall(function()
        delfolder(path);
    end);
    
    if success then
        return true;
    else
        return false, "Failed to delete directory: " .. err;
    end
end

-- // check if a directory exists
function funcs.fs:dir_exists(path)
    return isfolder(path);
end

-- // list files and directories
function funcs.fs:list_dir(path)
    if not isfolder(path) then
        return nil, "Directory does not exist";
    end
    
    local success, contents = pcall(function()
        return listfiles(path);
    end);
    
    if success then
        local files = {};
        local dirs = {};
        
        for _, item_path in ipairs(contents) do
            local name = item_path:match("[^/\\]+$");
            if isfolder(item_path) then
                table.insert(dirs, {
                    name = name,
                    path = item_path,
                    is_dir = true
                });
            else
                table.insert(files, {
                    name = name,
                    path = item_path,
                    is_dir = false,
                    ext = name:match("%.([^%.]+)$") or ""
                });
            end
        end
        
        return {files = files, dirs = dirs};
    else
        return nil, "Failed to list directory: " .. contents;
    end
end

-- // rename a file or directory
function funcs.fs:rename(old_path, new_path)
    local success, err = pcall(function()
        if isfile(old_path) then
            local content = readfile(old_path);
            writefile(new_path, content);
            delfile(old_path);
        elseif isfolder(old_path) then
            makefolder(new_path);
            
            local contents = listfiles(old_path);
            for _, item_path in ipairs(contents) do
                local item_name = item_path:match("[^/\\]+$");
                local new_item_path = new_path .. "/" .. item_name;
                
                self:rename(item_path, new_item_path);
            end
            
            delfolder(old_path);
        else
            return false, "Path does not exist";
        end
    end);
    
    if success then
        return true;
    else
        return false, "Failed to rename: " .. tostring(err);
    end
end

-- // create backup of a file
function funcs.fs:create_backup(path)
    if not isfile(path) then
        return false, "File does not exist";
    end
    
    local content = readfile(path);
    local backup_path = path .. ".bak" .. os.time();
    
    local success, err = pcall(function()
        writefile(backup_path, content);
    end);
    
    if success then
        return backup_path;
    else
        return false, "Failed to create backup: " .. err;
    end
end

-- // get all backups for a file
function funcs.fs:get_backups(path)
    local dir = path:match("(.-)[^/\\]+$") or "";
    local filename = path:match("[^/\\]+$");
    
    local success, contents = pcall(function()
        return listfiles(dir);
    end);
    
    if success then
        local backups = {};
        local pattern = "^" .. filename .. "%.bak(%d+)$";
        
        for _, item_path in ipairs(contents) do
            local name = item_path:match("[^/\\]+$");
            local timestamp = name:match(pattern);
            
            if timestamp then
                table.insert(backups, {
                    path = item_path,
                    timestamp = tonumber(timestamp),
                    time_str = os.date("%Y-%m-%d %H:%M:%S", tonumber(timestamp))
                });
            end
        end
        
        -- // sort by timestamp (newest first)
        table.sort(backups, function(a, b)
            return a.timestamp > b.timestamp;
        end);
        
        return backups;
    else
        return nil, "Failed to list directory: " .. contents;
    end
end

-- // code execution functions
funcs.exec = {};

-- // execute lua code
function funcs.exec:run_lua(code)
    local success, result = pcall(function()
        return loadstring(code)();
    end);
    
    if success then
        return true, result;
    else
        return false, result;
    end
end

-- // check code for syntax errors without executing
function funcs.exec:check_syntax(code)
    local success, err = pcall(function()
        return loadstring(code);
    end);
    
    if success then
        return true;
    else
        return false, err;
    end
end

-- // configuration functions
funcs.config = {};

-- // save ide settings
function funcs.config:save_settings(settings)
    local json_data = utils:encode_json(settings);
    
    local success, err = pcall(function()
        writefile("codeidemoonlight_settings.json", json_data);
    end);
    
    if success then
        return true;
    else
        return false, "Failed to save settings: " .. err;
    end
end

-- // load ide settings
function funcs.config:load_settings()
    if not isfile("codeidemoonlight_settings.json") then
        return config; -- // return default config
    end
    
    local success, json_data = pcall(function()
        return readfile("codeidemoonlight_settings.json");
    end);
    
    if success then
        local loaded_config = utils:decode_json(json_data);
        
        -- // merge with default config
        for k, v in pairs(loaded_config) do
            config[k] = v;
        end
        
        return config;
    else
        return config, "Failed to load settings: " .. json_data;
    end
end

-- // reset ide settings to default
function funcs.config:reset_settings()
    if isfile("codeidemoonlight_settings.json") then
        delfile("codeidemoonlight_settings.json");
    end
    
    return config;
end

-- // save current session (open files, cursor positions, etc)
function funcs.config:save_session(session_data)
    local json_data = utils:encode_json(session_data);
    
    local success, err = pcall(function()
        writefile("codeidemoonlight_session.json", json_data);
    end);
    
    if success then
        return true;
    else
        return false, "Failed to save session: " .. err;
    end
end

-- // load last session
function funcs.config:load_session()
    if not isfile("codeidemoonlight_session.json") then
        return nil;
    end
    
    local success, json_data = pcall(function()
        return readfile("codeidemoonlight_session.json");
    end);
    
    if success then
        return utils:decode_json(json_data);
    else
        return nil, "Failed to load session: " .. json_data;
    end
end

return funcs;
