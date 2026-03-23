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

    local ghcup_bin, ghcup_env = find_ghcup(cmd)

    -- List available versions
    local output = cmd.exec(ghcup_bin .. " list -t " .. tool .. " -r", { env = ghcup_env })

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

--- Locate the local ghcup binary, bootstrapping if needed.
--- Returns the binary path and an env table to pass to cmd.exec.
--- GHCUP_INSTALL_BASE_PREFIX is always set so ghcup uses the plugin
--- directory, not defaults like C:\ghcup on Windows or ~/.ghcup on Unix.
--- @param cmd cmd
--- @return string ghcup_bin, table ghcup_env
function find_ghcup(cmd) -- luacheck: ignore
    local is_windows = RUNTIME.osType == "windows"
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
            local http = require("http")
            local ghcup_bin_dir = file.join_path(plugin_dir, "ghcup", "bin")
            cmd.exec("mkdir " .. ghcup_bin_dir)
            http.download_file(
                { url = "https://downloads.haskell.org/~ghcup/x86_64-mingw64-ghcup.exe" },
                ghcup_path
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

    -- Env vars needed for every invocation of the bootstrapped ghcup
    local ghcup_env = {
        GHCUP_INSTALL_BASE_PREFIX = plugin_dir,
        GHCUP_USE_XDG_DIRS = "",
    }

    return ghcup_path, ghcup_env
end
