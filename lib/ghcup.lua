local M = {}

--- Locate the local ghcup binary and environment variables.
--- @return string ghcup_bin, table ghcup_env
M.find_ghcup = function()
  return "ghcup", {
    GHCUP_INSTALL_BASE_PREFIX = RUNTIME.pluginDirPath,
    GHCUP_USE_XDG_DIRS = "0"
  }
end

return M
