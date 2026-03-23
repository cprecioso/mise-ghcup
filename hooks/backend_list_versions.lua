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

    local ghcup_bin = find_ghcup(cmd, strings)

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

--- Locate ghcup binary: prefer system install, fallback to bootstrap
--- @param cmd cmd
--- @param strings strings
--- @return string path to ghcup binary
function find_ghcup(cmd, strings) -- luacheck: ignore
    local is_windows = RUNTIME.osType == "windows"

    -- Check if ghcup is already on PATH
    local which_cmd = is_windows and "where.exe ghcup" or "command -v ghcup"
    local ok, result = pcall(cmd.exec, which_cmd)
    if ok and result then
        -- `where.exe` may return multiple lines; take the first
        local path = strings.split(strings.trim_space(result), "\n")[1]
        if path and path ~= "" then
            return strings.trim_space(path)
        end
    end

    -- Bootstrap ghcup into plugin directory
    local plugin_dir = RUNTIME.pluginDirPath
    local file = require("file")
    local ghcup_path
    if is_windows then
        ghcup_path = file.join_path(plugin_dir, "ghcup", "bin", "ghcup.exe")
    else
        ghcup_path = file.join_path(plugin_dir, ".ghcup", "bin", "ghcup")
    end

    if not file.exists(ghcup_path) then
        local log = require("log")
        log.info("Bootstrapping ghcup into " .. plugin_dir)

        if is_windows then
            cmd.exec(
                "powershell -NoProfile -NonInteractive -Command \""
                    .. "$env:BOOTSTRAP_HASKELL_MINIMAL = 1; "
                    .. "$env:BOOTSTRAP_HASKELL_NONINTERACTIVE = 1; "
                    .. "$env:GHCUP_INSTALL_BASE_PREFIX = '"
                    .. plugin_dir
                    .. "'; "
                    .. "$env:GHCUP_USE_XDG_DIRS = ''; "
                    .. "Set-ExecutionPolicy Bypass -Scope Process -Force; "
                    .. "[System.Net.ServicePointManager]::SecurityProtocol = "
                    .. "[System.Net.ServicePointManager]::SecurityProtocol -bor 3072; "
                    .. "Invoke-Command -ScriptBlock ([ScriptBlock]::Create("
                    .. "(Invoke-WebRequest https://www.haskell.org/ghcup/sh/bootstrap-haskell.ps1 -UseBasicParsing)"
                    .. ")) -ArgumentList $false,$false,$false,$false,$false,$false,$false,'','','',''"
                    .. '"'
            )
        else
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
    end

    return ghcup_path
end
