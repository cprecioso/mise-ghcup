local M = {}

local is_windows = RUNTIME.osType == "windows"

local GITHUB_LATEST_URL = "https://api.github.com/repos/haskell/ghcup-hs/releases/latest"

--- Map RUNTIME arch/os values to GHCup's release asset naming.
--- @return string
local function get_asset_name()
	local arch_map = { amd64 = "x86_64", arm64 = "aarch64", ["386"] = "i386" }
	local arch = arch_map[RUNTIME.archType] or RUNTIME.archType

	local platform
	if RUNTIME.osType == "darwin" then
		platform = "apple-darwin"
	elseif RUNTIME.osType == "windows" then
		platform = "mingw64"
	else
		platform = RUNTIME.osType
	end

	return arch .. "-" .. platform .. "-ghcup"
end

--- Get the path where the ghcup binary should live.
--- @return string
local function get_binary_path()
	local file = require("file")
	local fs = require("fs")

	return file.join_path(RUNTIME.pluginDirPath, fs.hidden_dir("ghcup"), "bin", fs.exe_name("ghcup"))
end

local ghcup_env = {
	GHCUP_INSTALL_BASE_PREFIX = RUNTIME.pluginDirPath,
	GHCUP_USE_XDG_DIRS = "",
}

--- Download ghcup binary from GitHub releases if not already installed.
--- @return string binary_path
local function ensure_installed()
	local cmd = require("cmd")
	local file = require("file")
	local fs = require("fs")
	local http = require("http")
	local json = require("json")
	local log = require("log")

	local binary_path = get_binary_path()
	if file.exists(binary_path) then
		return binary_path
	end

	log.info("Downloading ghcup from GitHub releases...")

	-- Get the latest release version
	local response = http.get({ url = GITHUB_LATEST_URL })
	local release = json.decode(response.body)
	local semver = require("semver")
	local version_parts = semver.parse(release.tag_name)
	local version = table.concat(version_parts, ".")

	-- Build the download URL
	local asset_name = get_asset_name()
	if is_windows then
		asset_name = asset_name .. "-" .. version .. ".exe"
	else
		asset_name = asset_name .. "-" .. version
	end
	local download_url = "https://github.com/haskell/ghcup-hs/releases/download/"
		.. release.tag_name
		.. "/"
		.. asset_name

	log.info("Downloading " .. download_url)

	-- Ensure the bin directory exists
	local bin_dir = file.join_path(RUNTIME.pluginDirPath, fs.hidden_dir("ghcup"), "bin")
	fs.mkdir_p(cmd, bin_dir)

	-- Download the binary
	http.download_file({ url = download_url }, binary_path)

	-- Make executable on Unix
	if not is_windows then
		cmd.exec("chmod +x " .. binary_path)
	end

	if not file.exists(binary_path) then
		error("ghcup download failed: binary not found at " .. binary_path)
	end

	return binary_path
end

--- Execute a ghcup command.
--- @param args string
--- @return string output
function M.call(args)
	local cmd = require("cmd")

	local binary_path = ensure_installed()

	return cmd.exec(binary_path .. " " .. args, {
		env = ghcup_env,
	})
end

return M
