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
    local log = require("log")
    local fs = require("fs")

    -- Install the tool
    log.info("Installing " .. tool .. " " .. version .. " to " .. install_path)

    fs.mkdir_p(cmd, install_path)
    cmd.exec("ghcup install " .. tool .. " " .. version .. " -i " .. install_path)

    return {}
end
