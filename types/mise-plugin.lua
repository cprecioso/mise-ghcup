--- LuaCATS type definitions for mise vfox plugins
--- These annotations provide IDE support via lua-language-server.
--- See https://luals.github.io/wiki/annotations/

------------------------------------------------------------------------
-- Globals
------------------------------------------------------------------------

---@class Runtime
---@field osType string Operating system type (e.g. "linux", "darwin", "windows")
---@field archType string Architecture type (e.g. "amd64", "arm64")
---@field envType string? libc environment ("gnu" on glibc Linux, "musl" on musl Linux, nil elsewhere)
---@field version string Runtime version
---@field pluginDirPath string Path to the plugin directory
RUNTIME = {}

--- @deprecated Use RUNTIME.osType instead
---@type string
OS_TYPE = ""

--- @deprecated Use RUNTIME.archType instead
---@type string
ARCH_TYPE = ""

------------------------------------------------------------------------
-- PLUGIN table & hook method signatures
------------------------------------------------------------------------

---@class AvailableVersion
---@field version string Version string
---@field note? string Optional note about the version
---@field rolling? boolean If true, this is a rolling release (e.g. "nightly")
---@field checksum? string Checksum for detecting changes in rolling releases

---@class AvailableCtx
---@field args string[] Command-line arguments

---@class PreInstallResult
---@field version string Version string
---@field url? string Download URL
---@field note? string Optional note
---@field sha256? string SHA-256 checksum
---@field md5? string MD5 checksum
---@field sha1? string SHA-1 checksum
---@field sha512? string SHA-512 checksum
---@field attestation? PreInstallAttestation Optional attestation parameters

---@class PreInstallAttestation
---@field github_owner? string GitHub repository owner
---@field github_repo? string GitHub repository name
---@field github_signer_workflow? string GitHub Actions signer workflow
---@field cosign_sig_or_bundle_path? string Path to cosign signature or bundle
---@field cosign_public_key_path? string Path to cosign public key
---@field slsa_provenance_path? string Path to SLSA provenance
---@field slsa_min_level? integer Minimum SLSA level

---@class PreInstallCtx
---@field args string[] Command-line arguments
---@field version string Requested version

---@class PostInstallCtx
---@field rootPath string Installation root path
---@field runtimeVersion string Runtime version
---@field sdkInfo table<string, SdkInfo> SDK info for installed versions

---@class SdkInfo
---@field path string Installation path
---@field version string Installed version
---@field note? string Optional note

---@class EnvKey
---@field key string Environment variable name
---@field value string Environment variable value

---@class EnvKeysCtx
---@field version string Installed version
---@field path string Installation path
---@field sdkInfo table<string, SdkInfo> SDK info for installed versions
---@field main SdkInfo Main SDK info
---@field options table Plugin options from mise.toml

---@class ParseLegacyFileCtx
---@field args string[] Command-line arguments
---@field filename string Basename of the legacy file
---@field filepath string Full path to the legacy file
---@field getInstalledVersions fun(): string[] Returns list of installed versions

---@class ParseLegacyFileResult
---@field version? string Parsed version string

---@class MiseEnvCtx
---@field options table Plugin options from mise.toml

---@class MiseEnvResult
---@field env? EnvKey[] Environment variables to set
---@field cacheable? boolean Whether the result can be cached (default false)
---@field watch_files? string[] Files to watch for cache invalidation

---@class MisePathCtx
---@field options table Plugin options from mise.toml

--- Tool options from `mise.toml`. TOML values keep their types: strings stay
--- strings, arrays become sequence tables, tables become map tables.
---@alias BackendOptions table<string, any>

---@class BackendListVersionsCtx
---@field tool string Tool name
---@field options BackendOptions Tool options from mise.toml

---@class BackendListVersionsResult
---@field versions string[] List of available versions, ascending (mise does not re-sort)

---@class BackendInstallCtx
---@field tool string Tool name
---@field version string Version to install
---@field install_path string Path where the tool should be installed
---@field download_path string Scratch directory for downloads
---@field options BackendOptions Tool options from mise.toml

---@class BackendInstallResult

---@class BackendExecEnvCtx
---@field tool string Tool name
---@field version string Installed version
---@field install_path string Installation path
---@field options BackendOptions Tool options from mise.toml

---@class BackendExecEnvResult
---@field env_vars EnvKey[] Environment variables to set

--- A single `PLUGIN.systemDependencies` entry: a system prerequisite mise checks
--- before installing. Exactly one of bin/pkgconfig/sharedlib/command must be set.
--- Note there is no per-OS filter: only `sharedlib` is Linux-only (auto-satisfied
--- elsewhere), the others are checked on every platform.
---@class SystemDependency
---@field bin? string Executable that must resolve on PATH
---@field pkgconfig? string Module discoverable via `pkg-config --exists`
---@field sharedlib? string Soname the dynamic linker must resolve (Linux only)
---@field command? string Shell command whose exit status 0 means satisfied
---@field version? string Constraint for bin/pkgconfig, e.g. ">=3.0" (bare "3.0" means ">=3.0")
---@field optional? string Reason this is wanted; missing optional deps never prompt or fail
---@field packages? table<string, string> Package manager name (brew, apt, dnf, pacman, apk, ...) to package name

---@class Plugin
---@field name string Plugin name
---@field version string Plugin version
---@field description? string
---@field author? string
---@field license? string
---@field homepage? string
---@field legacyFilenames? string[] Idiomatic version files this plugin can parse
---@field depends? string[] Tools whose bin paths should be available during hooks
---@field systemDependencies? SystemDependency[] System prerequisites checked before install
---@field Available? fun(self: Plugin, ctx: AvailableCtx): AvailableVersion[]
---@field PreInstall? fun(self: Plugin, ctx: PreInstallCtx): PreInstallResult
---@field PostInstall? fun(self: Plugin, ctx: PostInstallCtx)
---@field EnvKeys? fun(self: Plugin, ctx: EnvKeysCtx): EnvKey[]
---@field ParseLegacyFile? fun(self: Plugin, ctx: ParseLegacyFileCtx): ParseLegacyFileResult
---@field MiseEnv? fun(self: Plugin, ctx: MiseEnvCtx): MiseEnvResult|EnvKey[]
---@field MisePath? fun(self: Plugin, ctx: MisePathCtx): string[]
---@field BackendListVersions? fun(self: Plugin, ctx: BackendListVersionsCtx): BackendListVersionsResult
---@field BackendInstall? fun(self: Plugin, ctx: BackendInstallCtx): BackendInstallResult
---@field BackendExecEnv? fun(self: Plugin, ctx: BackendExecEnvCtx): BackendExecEnvResult
PLUGIN = {}

------------------------------------------------------------------------
-- Built-in modules (available via require)
------------------------------------------------------------------------

-- http module --------------------------------------------------------

---@class HttpRequestOpts
---@field url string Request URL
---@field headers? table<string, string> HTTP headers

---@class HttpResponse
---@field status_code integer HTTP status code
---@field headers table<string, string> Response headers
---@field body string Response body (only for get, not head)

--- The plain get/head/download_file raise a Lua error on transport failures
--- (timeout, DNS, connection refused). Since pcall cannot catch errors from these
--- async functions, use the try_ variants to handle failures yourself.
---@class http
---@field get fun(opts: HttpRequestOpts): HttpResponse Send a GET request (raises on failure)
---@field try_get fun(opts: HttpRequestOpts): HttpResponse?, string? Send a GET request, returns (resp, nil) or (nil, err)
---@field head fun(opts: HttpRequestOpts): HttpResponse Send a HEAD request, no body (raises on failure)
---@field try_head fun(opts: HttpRequestOpts): HttpResponse?, string? Send a HEAD request, returns (resp, nil) or (nil, err)
---@field download_file fun(opts: HttpRequestOpts, path: string) Download a file to disk (raises on failure)
---@field try_download_file fun(opts: HttpRequestOpts, path: string): boolean?, string? Download a file, returns (true, nil) or (nil, err)
local http = {}

-- json module --------------------------------------------------------

---@class json
---@field encode fun(value: any): string Encode a value as JSON
---@field decode fun(str: string): any Decode a JSON string
local json = {}

-- file module --------------------------------------------------------

---@class FileStat
---@field size integer Size in bytes
---@field is_file boolean
---@field is_dir boolean
---@field is_symlink boolean
---@field modified integer? Unix timestamp in seconds
---@field accessed integer? Unix timestamp in seconds
---@field created integer? Unix timestamp in seconds
---@field mode string? Octal permission string on Unix, nil on Windows

---@class file
---@field read fun(path: string): string Read file contents
---@field exists fun(path: string): boolean Check if a file exists
---@field stat fun(path: string): FileStat? Metadata of a path, or nil if it does not exist
---@field list fun(path: string): string[] Immediate entries of a directory, sorted
---@field glob fun(pattern: string): string[] Paths matching a glob, sorted
---@field move fun(src: string, dst: string) Move a file or directory, creating parent dirs
---@field symlink fun(src: string, dst: string) Create a symbolic link
---@field join_path fun(...: string): string Join path components
local file = {}

-- cmd module ---------------------------------------------------------

---@class CmdExecOpts
---@field cwd? string Working directory
---@field env? table<string, string> Environment variables
---@field timeout? integer Timeout in milliseconds

---@class cmd
---@field exec fun(command: string, opts?: CmdExecOpts): string Execute a shell command
local cmd = {}

-- env module ---------------------------------------------------------

---@class env
---@field setenv fun(key: string, val: string) Set an environment variable
---@field getenv fun(key: string): string? Get an environment variable
local env = {}

-- archiver module ----------------------------------------------------

---@class archiver
---@field decompress fun(archive: string, dest: string) Decompress an archive (.zip, .tar.gz, .tar.xz, .tar.bz2)
local archiver = {}

-- semver module ------------------------------------------------------

---@class semver
---@field compare fun(v1: string, v2: string): integer Compare two version strings (-1, 0, 1)
---@field parse fun(version: string): integer[] Parse a version string into numeric parts
---@field sort fun(versions: string[]): string[] Sort version strings in ascending order
---@field sort_by fun(arr: table[], field: string): table[] Sort tables by a version field
local semver = {}

-- strings module -----------------------------------------------------

---@class strings
---@field split fun(s: string, sep: string): string[] Split a string by separator
---@field has_prefix fun(s: string, prefix: string): boolean Check if string starts with prefix
---@field has_suffix fun(s: string, suffix: string): boolean Check if string ends with suffix
---@field trim fun(s: string, suffix: string): string Trim suffix from end of string
---@field trim_space fun(s: string): string Trim whitespace from both ends
---@field contains fun(s: string, substr: string): boolean Check if string contains substring
---@field join fun(arr: any[], sep: string): string Join array elements with separator
local strings = {}

-- html module --------------------------------------------------------

---@class HtmlNode
---@field find fun(self: HtmlNode, selector: string): HtmlNode Find descendant nodes matching a CSS selector
---@field first fun(self: HtmlNode): HtmlNode Get the first node
---@field eq fun(self: HtmlNode, idx: integer): HtmlNode Get node at zero-based index
---@field each fun(self: HtmlNode, fn: fun(idx: integer, node: HtmlNode)) Iterate over nodes
---@field text fun(self: HtmlNode): string Get the text content
---@field attr fun(self: HtmlNode, key: string): string Get an attribute value

---@class html
---@field parse fun(html_str: string): HtmlNode Parse an HTML string into a node tree
local html = {}

-- log module ---------------------------------------------------------

---@class log
---@field trace fun(...: any) Log at trace level
---@field debug fun(...: any) Log at debug level
---@field info fun(...: any) Log at info level
---@field warn fun(...: any) Log at warn level
---@field error fun(...: any) Log at error level
local log = {}

return nil
