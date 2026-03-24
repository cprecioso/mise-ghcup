local M = {}

local is_windows = RUNTIME.osType == "windows"

--- Create a directory and all parent directories.
--- @param cmd cmd
--- @param path string
function M.mkdir_p(cmd, path)
    local file = require("file")
    if is_windows then
        if not file.exists(path) then
            cmd.exec("mkdir " .. path)
        end
    else
        cmd.exec("mkdir -p " .. path)
    end
end

--- Move all top-level files from `source` into `dest`, creating `dest` first.
--- @param cmd cmd
--- @param source string
--- @param dest string
function M.move_top_level_files(cmd, source, dest)
    M.mkdir_p(cmd, dest)
    if is_windows then
        cmd.exec("move /Y " .. source .. "\\* " .. dest .. "\\")
    else
        cmd.exec("find " .. source .. " -maxdepth 1 -type f -exec mv {} " .. dest .. "/ \\;")
    end
end

--- Return a binary name with `.exe` appended on Windows.
--- @param name string
--- @return string
function M.exe_name(name)
    if is_windows then
        return name .. ".exe"
    else
        return name
    end
end

--- Return a directory name prefixed with `.` on Unix (hidden), bare on Windows.
--- @param name string
--- @return string
function M.hidden_dir(name)
    if is_windows then
        return name
    else
        return "." .. name
    end
end

return M
