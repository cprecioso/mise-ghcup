local M = {}

--- Locate the local ghcup binary and environment variables.
--- @param args string
--- @return string ghcup_bin, table ghcup_env
function M.call(args)
    local cmd = require("cmd")

    return cmd.exec("ghcup " .. args, {
        env = {
            GHCUP_INSTALL_BASE_PREFIX = RUNTIME.pluginDirPath,
            GHCUP_USE_XDG_DIRS = "0",
        },
    })
end

return M
