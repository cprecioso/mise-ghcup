local M = {}

local is_windows = RUNTIME.osType == "windows"

local BOOTSTRAP_URL_UNIX = "https://www.haskell.org/ghcup/sh/bootstrap-haskell"
local BOOTSTRAP_URL_WINDOWS = "https://www.haskell.org/ghcup/sh/bootstrap-haskell.ps1"

--- Get the path where the ghcup binary should live.
--- @return string
local function get_binary_path()
    local file = require("file")
    local fs = require("fs")

    return file.join_path(RUNTIME.pluginDirPath, fs.hidden_dir("ghcup"), "bin", fs.exe_name("ghcup"))
end

local ghcup_env = {
    GHCUP_INSTALL_BASE_PREFIX = RUNTIME.pluginDirPath,
    GHCUP_USE_XDG_DIRS = "0",
    BOOTSTRAP_HASKELL_NONINTERACTIVE = "1",
    BOOTSTRAP_HASKELL_MINIMAL = "1",
}

--- Bootstrap ghcup if not already installed.
--- @return string binary_path
local function ensure_installed()
    local cmd = require("cmd")
    local file = require("file")
    local http = require("http")
    local log = require("log")

    local binary_path = get_binary_path()
    if file.exists(binary_path) then
        return binary_path
    end

    log.info("Bootstrapping ghcup...")

    local ls_cmd = is_windows and "dir " or "ls -la "

    log.info("Plugin dir before bootstrap:")
    log.info(cmd.exec(ls_cmd .. RUNTIME.pluginDirPath))

    if is_windows then
        local script_path = file.join_path(RUNTIME.pluginDirPath, "bootstrap-haskell.ps1")
        http.download_file({ url = BOOTSTRAP_URL_WINDOWS }, script_path)
        cmd.exec(
            "pwsh -NoProfile -ExecutionPolicy Bypass -File "
                .. script_path
                .. " -Minimal -InstallDir "
                .. RUNTIME.pluginDirPath,
            { env = ghcup_env }
        )
    else
        local script_path = file.join_path(RUNTIME.pluginDirPath, "bootstrap-haskell.sh")
        http.download_file({ url = BOOTSTRAP_URL_UNIX }, script_path)
        cmd.exec("sh " .. script_path, { env = ghcup_env })
    end

    log.info("Plugin dir after bootstrap:")
    log.info(cmd.exec(ls_cmd .. RUNTIME.pluginDirPath))

    if not file.exists(binary_path) then
        error("ghcup bootstrap failed: binary not found at " .. binary_path)
    end

    return binary_path
end

--- Execute a ghcup command.
--- @param args string
--- @return string output
function M.call(args)
    local cmd = require("cmd")

    local binary_path = ensure_installed()

    return cmd.exec(binary_path .. " " .. args, {
        env = ghcup_env,
    })
end

--- Ensures that ghcup is installed, bootstrapping if needed.
function M.assert_installed()
    ensure_installed()
end

return M
