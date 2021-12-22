using SimpleCaching
using Documenter

DocMeta.setdocmeta!(SimpleCaching, :DocTestSetup, :(using SimpleCaching); recursive=true)

makedocs(;
    modules=[SimpleCaching],
    authors="Federico Manzella",
    repo="https://github.com/aclai-lab/SimpleCaching.jl/blob/{commit}{path}#{line}",
    sitename="SimpleCaching.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aclai-lab.github.io/SimpleCaching.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/aclai-lab/SimpleCaching.jl",
    devbranch="main",
)
