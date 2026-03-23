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

    cmd.exec("mkdir -p " .. install_path)

    local ghcup_bin = find_ghcup(cmd)

    -- Install the tool
    log.info("Installing " .. tool .. " " .. version .. " to " .. install_path)
    cmd.exec(ghcup_bin .. " install " .. tool .. " " .. version .. " -i " .. install_path)

    -- Post-install: ensure bin/ directory exists
    -- Some tools install binaries at the top level instead of in bin/
    local bin_path = file.join_path(install_path, "bin")
    if not file.exists(bin_path) then
        log.info("Creating bin directory and moving binaries")
        cmd.exec("mkdir " .. bin_path)
        cmd.exec("find " .. install_path .. " -maxdepth 1 -type f -exec mv {} " .. bin_path .. "/ \\;")
    end

    return {}
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
