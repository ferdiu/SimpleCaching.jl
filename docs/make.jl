using SimpleCaching
using Documenter

DocMeta.setdocmeta!(SimpleCaching, :DocTestSetup, :(using SimpleCaching); recursive=true)

makedocs(;
    modules=[SimpleCaching],
    authors="Federico Manzella",
    repo="https://github.com/ferdiu/SimpleCaching.jl/blob/{commit}{path}#{line}",
    sitename="SimpleCaching.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ferdiu.github.io/SimpleCaching.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Macros" => "macros.md",
    ],
)

deploydocs(;
    repo="github.com/ferdiu/SimpleCaching.jl",
    devbranch="main",
)
