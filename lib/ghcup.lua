local M = {}

--- Locate the local ghcup binary and environment variables.
--- @param args string
--- @return string ghcup_bin, table ghcup_env
function M.call(args)
    local cmd = require("cmd")

    local log = require("log")
    log.info("HOLA!")
    if RUNTIME.osType == "windows" then
        log.info("in windows")
        log.info(cmd.exec("where ghcup"))
        log.info("out windows")
    else
        log.info("in other")
        log.info(cmd.exec("which ghcup"))
        log.info("out other")
    end
    log.info("ADIOS")

    return cmd.exec("ghcup " .. args, {
        env = {
            GHCUP_INSTALL_BASE_PREFIX = RUNTIME.pluginDirPath,
            GHCUP_USE_XDG_DIRS = "0",
        },
    })
end

--- Checks if ghcup is installed by trying to call it with `--version`.
--- @return boolean
function M.is_installed()
    M.call("--version")
    return true
end

--- Asserts that ghcup is installed by trying to call it with `--version`.
function M.assert_installed()
    if not M.is_installed() then
        error("ghcup is not installed")
    end
end

return M
