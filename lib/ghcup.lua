local M = {}

local is_windows = RUNTIME.osType == "windows"

--- Base prefix for calls that only read ghcup's release metadata (`list`,
--- `--version`). ghcup caches the metadata YAML under `<base>/.ghcup`, so we
--- keep this inside the plugin dir to stay self-contained and reuse the cache
--- across runs. One dir per tool, so concurrent calls for different tools don't
--- race on the same cache. Nothing deep is written here, so the Windows
--- MAX_PATH limit is not a concern.
---
--- @param ghcup_id string The ghcup id of the tool (e.g. "ghc", "cabal")
--- @return string
function M.metadata_base_prefix(ghcup_id)
    local file = require("file")
    return file.join_path(RUNTIME.pluginDirPath, ghcup_id)
end

--- Run ghcup with its home (`<base_prefix>/.ghcup`) pointed at `base_prefix`.
--- Callers choose the base: metadata-only calls want a stable cache
--- (`metadata_base_prefix`), installs want mise's scratch dir so the bindist
--- staging is isolated per tool+version and cleaned up afterwards.
---
--- @param base_prefix string Value for GHCUP_INSTALL_BASE_PREFIX
--- @param args string
--- @return string
function M.call(base_prefix, args)
    local cmd = require("cmd")
    local fs = require("fs")

    fs.mkdir_p(cmd, base_prefix)

    return cmd.exec("ghcup " .. args, {
        env = {
            GHCUP_INSTALL_BASE_PREFIX = base_prefix,
        },
    })
end

--- Checks if ghcup is installed by trying to call it with `--version`.
--- @param base_prefix string Value for GHCUP_INSTALL_BASE_PREFIX
--- @return boolean
function M.is_installed(base_prefix)
    local success, _ = pcall(function()
        return M.call(base_prefix, "--version")
    end)

    return success
end

--- Asserts that ghcup is installed by trying to call it with `--version`.
--- @param base_prefix string Value for GHCUP_INSTALL_BASE_PREFIX
function M.assert_installed(base_prefix)
    if not M.is_installed(base_prefix) then
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
