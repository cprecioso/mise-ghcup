--- Lists available versions for a tool in this backend
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx BackendListVersionsCtx
--- @return BackendListVersionsResult
function PLUGIN:BackendListVersions(ctx)
    local tool = ctx.tool
    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end

    local cmd = require("cmd")
    local strings = require("strings")
    local semver = require("semver")

    local ghcup_bin = find_ghcup(cmd)

    -- List available versions
    local output = cmd.exec(ghcup_bin .. " list -t " .. tool .. " -r")

    local versions = {}
    for _, line in ipairs(strings.split(output, "\n")) do
        line = strings.trim_space(line)
        if line ~= "" then
            -- ghcup list output has version as the 2nd whitespace-delimited field
            local version = line:match("^%S+%s+(%S+)")
            if version then
                table.insert(versions, version)
            end
        end
    end

    if #versions == 0 then
        error("No versions found for " .. tool)
    end

    versions = semver.sort(versions)

    return { versions = versions }
end

--- Locate or bootstrap internal ghcup binary
--- @param cmd cmd
--- @return string path to ghcup binary
function find_ghcup(cmd) -- luacheck: ignore
    local plugin_dir = RUNTIME.pluginDirPath
    local file = require("file")
    local ghcup_path = file.join_path(plugin_dir, ".ghcup", "bin", "ghcup")

    if not file.exists(ghcup_path) then
        local log = require("log")
        log.info("Bootstrapping ghcup into " .. plugin_dir)
        cmd.exec(
            "curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | "
                .. "BOOTSTRAP_HASKELL_MINIMAL=1 "
                .. "BOOTSTRAP_HASKELL_NONINTERACTIVE=1 "
                .. "GHCUP_INSTALL_BASE_PREFIX="
                .. plugin_dir
                .. " "
                .. "GHCUP_USE_XDG_DIRS='' "
                .. "sh"
        )
    end

    return ghcup_path
end
