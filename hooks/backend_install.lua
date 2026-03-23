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

    local ghcup_bin, ghcup_env = find_ghcup(cmd)

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
    local ghcup_dir, ghcup_path
    if is_windows then
        ghcup_dir = file.join_path(plugin_dir, "ghcup")
        ghcup_path = file.join_path(ghcup_dir, "bin", "ghcup.exe")
    else
        ghcup_dir = file.join_path(plugin_dir, ".ghcup")
        ghcup_path = file.join_path(ghcup_dir, "bin", "ghcup")
    end

    if not file.exists(ghcup_path) then
        local log = require("log")
        log.info("Bootstrapping ghcup into " .. plugin_dir)

        if is_windows then
            local ghcup_bin_dir = file.join_path(ghcup_dir, "bin")
            cmd.exec(
                "powershell -NoProfile -NonInteractive -Command \""
                    .. "New-Item -ItemType Directory -Force -Path '"
                    .. ghcup_bin_dir
                    .. "' | Out-Null; "
                    .. "Invoke-WebRequest -Uri 'https://downloads.haskell.org/~ghcup/x86_64-mingw64-ghcup.exe'"
                    .. " -OutFile '"
                    .. ghcup_path
                    .. "' -UseBasicParsing"
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
