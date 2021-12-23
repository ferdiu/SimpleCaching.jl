module SimpleCaching

using SHA
using Dates
using Serialization
using JLD2

import Base: esc

# export caching macros
export @scache, @scachefast

include("settings.jl")
include("utils.jl")
include("caching.jl")
include("init.jl")

end # module
