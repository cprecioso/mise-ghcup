--- Installs a specific version of a tool
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendinstall
--- @param ctx BackendInstallCtx
--- @return BackendInstallResult
function PLUGIN:BackendInstall(ctx)
    local tool = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path

    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end
    if not version or version == "" then
        error("Version cannot be empty")
    end
    if not install_path or install_path == "" then
        error("Install path cannot be empty")
    end

    local cmd = require("cmd")
    local file = require("file")
    local strings = require("strings")
    local log = require("log")
    local is_windows = RUNTIME.osType == "windows"

    if is_windows then
        cmd.exec("powershell -NoProfile -NonInteractive -Command \"New-Item -ItemType Directory -Force -Path '"
            .. install_path
            .. "'\"")
    else
        cmd.exec("mkdir -p " .. install_path)
    end

    local ghcup_bin, ghcup_env = find_ghcup(cmd, strings)

    -- Install the tool
    log.info("Installing " .. tool .. " " .. version .. " to " .. install_path)
    cmd.exec(ghcup_bin .. " install " .. tool .. " " .. version .. " -i " .. install_path, { env = ghcup_env })

    -- Post-install: ensure bin/ directory exists
    -- Some tools install binaries at the top level instead of in bin/
    local bin_path = file.join_path(install_path, "bin")
    if not file.exists(bin_path) then
        log.info("Creating bin directory and moving binaries")
        if is_windows then
            cmd.exec("powershell -NoProfile -NonInteractive -Command \""
                .. "New-Item -ItemType Directory -Force -Path '"
                .. bin_path
                .. "'; "
                .. "Get-ChildItem -Path '"
                .. install_path
                .. "' -File "
                .. "| Move-Item -Destination '"
                .. bin_path
                .. "'"
                .. '"')
        else
            cmd.exec("mkdir " .. bin_path)
            cmd.exec("find " .. install_path .. " -maxdepth 1 -type f -exec mv {} " .. bin_path .. "/ \\;")
        end
    end

    return {}
end

--- Locate ghcup binary: prefer system install, fallback to bootstrap.
--- Returns the binary path and an env table to pass to cmd.exec.
--- When using the bootstrapped ghcup, GHCUP_INSTALL_BASE_PREFIX must be
--- set on every invocation so ghcup uses the plugin directory, not defaults
--- like C:\ghcup on Windows.
--- @param cmd cmd
--- @param strings strings
--- @return string ghcup_bin, table|nil ghcup_env
function find_ghcup(cmd, strings) -- luacheck: ignore
    local is_windows = RUNTIME.osType == "windows"

    -- Check if ghcup is already on PATH
    local which_cmd = is_windows and "where.exe ghcup" or "command -v ghcup"
    local ok, result = pcall(cmd.exec, which_cmd)
    if ok and result then
        -- `where.exe` may return multiple lines; take the first
        local path = strings.split(strings.trim_space(result), "\n")[1]
        if path and path ~= "" then
            return strings.trim_space(path), nil
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

    -- Env vars needed for every invocation of the bootstrapped ghcup
    local ghcup_env = {
        GHCUP_INSTALL_BASE_PREFIX = plugin_dir,
        GHCUP_USE_XDG_DIRS = "",
    }

    return ghcup_path, ghcup_env
end
