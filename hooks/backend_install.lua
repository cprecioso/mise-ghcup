--- Installs a specific version of a tool
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendinstall
--- @param ctx BackendInstallCtx
--- @return BackendInstallResult
function PLUGIN:BackendInstall(ctx)
    local cmd = require("cmd")
    local fs = require("fs")
    local ghcup = require("ghcup")
    local log = require("log")
    local tools = require("tools")

    local tool = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path

    -- Give ghcup its home inside mise's scratch dir for this install. It is
    -- created for us, it is unique per tool+version (so parallel installs can't
    -- race on a shared ghcup home), and mise wipes it once we return, so the
    -- bindist staging doesn't outlive the install.
    local base_prefix = ctx.download_path

    local tool_data = tools.assert_valid_tool(tool)
    ghcup.assert_installed(base_prefix)

    -- Install the tool
    log.info("Installing " .. tool .. " " .. version .. " to " .. install_path)
    log.debug("ghcup home base prefix: " .. base_prefix)

    fs.mkdir_p(cmd, install_path)
    ghcup.call(base_prefix, "install " .. tool_data.ghcup_id .. " " .. version .. " -i " .. install_path)

    return {}
end
