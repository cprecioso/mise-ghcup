-- metadata.lua
-- Backend plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html

PLUGIN = { -- luacheck: ignore
    -- Required: Plugin name (will be the backend name users reference)
    name = "ghcup",

    -- Required: Plugin version (not the tool versions)
    version = "1.0.0",

    -- Required: Brief description of the backend and tools it manages
    description = "A mise backend plugin for Haskell tools via ghcup",

    -- Required: Plugin author/maintainer
    author = "cprecioso",

    -- Optional: Plugin homepage/repository URL
    homepage = "https://github.com/cprecioso/mise-ghcup",

    -- Optional: Plugin license
    license = "MIT",

    -- Optional: Important notes for users
    notes = {
        "Supports ghc, cabal, hls, and stack",
        "Needs ghcup already installed in the system",
    },
}
