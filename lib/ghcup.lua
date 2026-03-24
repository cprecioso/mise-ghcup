local M = {}

--- Locate the local ghcup binary, bootstrapping if needed.
--- Returns the binary path and an env table to pass to cmd.exec.
--- GHCUP_INSTALL_BASE_PREFIX is always set so ghcup uses the plugin
--- directory, not defaults like C:\ghcup on Windows or ~/.ghcup on Unix.
--- @param cmd cmd
--- @return string ghcup_bin, table ghcup_env
function M.find_ghcup(cmd)
    local plugin_dir = RUNTIME.pluginDirPath

    local http = require("http")
    local file = require("file")
    local fs = require("fs")

    local ghcup_installer_path = file.join_path(plugin_dir, "ghcup-installer")

    local ghcup_path = file.join_path(plugin_dir, fs.hidden_dir("ghcup"))
    local ghcup_bin_path = file.join_path(ghcup_path, "bin", fs.exe_name("ghcup"))

    if not file.exists(ghcup_bin_path) then
        local log = require("log")
        log.info("Bootstrapping ghcup into " .. plugin_dir)

        if RUNTIME.osType == "windows" then
            http.download_file(
                { url = "https://www.haskell.org/ghcup/sh/bootstrap-haskell.ps1" },
                ghcup_installer_path .. ".ps1"
            )
            cmd.exec(
                "powershell -ExecutionPolicy Bypass -File "
                .. ghcup_installer_path .. ".ps1"
                .. " -Minimal"
                .. " -DisableCurl"
                .. " -InstallDir " .. plugin_dir
                .. " -DontAdjustBashRc"
                ,
                {
                    env = {
                        BOOTSTRAP_HASKELL_MINIMAL = "1",
                        BOOTSTRAP_HASKELL_NONINTERACTIVE = "1",
                        GHCUP_INSTALL_BASE_PREFIX = plugin_dir,
                        GHCUP_USE_XDG_DIRS = "0"
                    }
                }
            )
        else
            http.download_file({ url = "https://www.haskell.org/ghcup/sh/bootstrap-haskell" }, ghcup_installer_path)
            cmd.exec(
                "sh " .. ghcup_installer_path,
                {
                    env = {
                        BOOTSTRAP_HASKELL_MINIMAL = "1",
                        BOOTSTRAP_HASKELL_NONINTERACTIVE = "1",
                        GHCUP_INSTALL_BASE_PREFIX = plugin_dir,
                        GHCUP_USE_XDG_DIRS = "0"
                    }
                }
            )
        end
    end

    -- Env vars needed for every invocation of the bootstrapped ghcup
    local ghcup_env = {
        GHCUP_INSTALL_BASE_PREFIX = plugin_dir,
        GHCUP_USE_XDG_DIRS = "0",
    }

    return ghcup_bin_path, ghcup_env
end

return M
