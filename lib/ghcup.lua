local M = {}

local is_windows = RUNTIME.osType == "windows"

--- Each tool gets its own ghcup home. Separating the base dir allows parallel
--- installs without race conditions.
--- On Windows, we use a short base since GHC has deeply-nested files that might
--- exceed the 260-char MAX_PATH limit. Elsewhere, we keep it inside the plugin
--- dir to stay self-contained.
---
--- @param ghcup_id string The ghcup id of the tool (e.g. "ghc", "cabal")
--- @return string
local function install_base_prefix(ghcup_id)
    local file = require("file")
    if is_windows then
        return "C:\\" .. ghcup_id
    else
        return file.join_path(RUNTIME.pluginDirPath, ghcup_id)
    end
end

--- Locate the local ghcup binary and environment variables.
--- @param ghcup_id string The ghcup id whose isolated home to use
--- @param args string
--- @return string
function M.call(ghcup_id, args)
    local cmd = require("cmd")
    local fs = require("fs")

    local base_prefix = install_base_prefix(ghcup_id)
    fs.mkdir_p(cmd, base_prefix)

    return cmd.exec("ghcup " .. args, {
        env = {
            GHCUP_INSTALL_BASE_PREFIX = base_prefix,
        },
    })
end

--- Checks if ghcup is installed by trying to call it with `--version`.
--- @param ghcup_id string The ghcup id whose isolated home to use
--- @return boolean
function M.is_installed(ghcup_id)
    local success, _ = pcall(function()
        return M.call(ghcup_id, "--version")
    end)

    return success
end

--- Asserts that ghcup is installed by trying to call it with `--version`.
--- @param ghcup_id string The ghcup id whose isolated home to use
function M.assert_installed(ghcup_id)
    if not M.is_installed(ghcup_id) then
        error("ghcup is not installed")
    end

    local cmd = require("cmd")
    local log = require("log")

    if is_windows then
        local ghcup_path = cmd.exec("where ghcup")
        log.debug("ghcup path: " .. ghcup_path)
    else
        local ghcup_path = cmd.exec("which ghcup")
        log.debug("ghcup path: " .. ghcup_path)
    end
end

return M
