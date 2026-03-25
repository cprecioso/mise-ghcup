--- Installs a specific version of a tool
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendinstall
--- @param ctx BackendInstallCtx
--- @return BackendInstallResult
function PLUGIN:BackendInstall(ctx)
    local tools = require("tools")

    local tool = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path

    if not tools[tool] then
        error("Tool '" .. tool .. "' not recognized")
    end

    local cmd = require("cmd")
    local log = require("log")
    local fs = require("fs")
    local ghcup = require("ghcup")

    local ghcup_bin, ghcup_env = ghcup.find_ghcup()

    -- Install the tool
    log.info("Installing " .. tool .. " " .. version .. " to " .. install_path)

    fs.mkdir_p(cmd, install_path)
    cmd.exec(
        ghcup_bin .. " install " .. tool .. " " .. version .. " -i " .. install_path,
        { env = ghcup_env }
    )

    return {}
end
