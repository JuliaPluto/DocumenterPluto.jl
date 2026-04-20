using Documenter
using DocumenterPluto

makedocs(;
    sitename = "DocumenterPluto.jl",
    authors  = "Fons van der Plas and contributors",
    format   = Documenter.HTML(;
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    pages = [
        "Home"  => "index.md",
        "Demo (hosted URL)" => "demo_url.md",
        "Demo (local notebook)" => "demo_local.md",
    ],
    remotes = nothing,
)

deploydocs(;
    repo = "github.com/JuliaPluto/DocumenterPluto.jl.git",
    push_preview = true,
)
