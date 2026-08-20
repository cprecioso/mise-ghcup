-- metadata.lua
-- Backend plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html

PLUGIN = { -- luacheck: ignore
    name = "mise-ghcup",

    version = "1.0.0",

    description = "A mise backend plugin for Haskell tools via ghcup",

    author = "wasp-lang",

    homepage = "https://github.com/wasp-lang/mise-ghcup",

    license = "MIT",

    notes = {
        "Supports ghc, cabal, hls, and stack",
        "Requires the ghcup tool",
    },

    depends = { "ghcup", "aqua:ghcup" },
}
