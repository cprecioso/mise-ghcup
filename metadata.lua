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

    -- Prerequisites mise checks before installing, so a missing one is reported
    -- up front instead of halfway through a bindist build.
    systemDependencies = {
        -- GHC links against gmp at runtime, and a missing libgmp is the classic
        -- "ghc: error while loading shared libraries" on minimal Linux images.
        -- `sharedlib` checks only run on Linux (auto-satisfied elsewhere), which
        -- is what we want: this is a Linux packaging problem.
        {
            sharedlib = "libgmp.so.10",
            packages = { apt = "libgmp-dev", dnf = "gmp-devel", pacman = "gmp", apk = "gmp-dev" },
        },

        -- Installing a GHC bindist runs `./configure && make install`, and GHC
        -- shells out to a C compiler to link. These are marked optional on
        -- purpose: they are genuinely needed on Linux and macOS, but mise has no
        -- per-OS filter on these entries and resolves `bin` without PATHEXT, so a
        -- required check would false-alarm on Windows. Optional entries never
        -- prompt or fail, they just print a hint when missing.
        {
            bin = "make",
            optional = "installing a GHC bindist on Linux/macOS",
            packages = { apt = "make", dnf = "make", pacman = "make", apk = "make" },
        },
        {
            bin = "gcc",
            optional = "the C toolchain GHC uses to compile and link",
            packages = { apt = "build-essential", dnf = "gcc", pacman = "gcc", apk = "gcc" },
        },
    },
}
