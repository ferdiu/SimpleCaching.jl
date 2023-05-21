```@meta
CurrentModule = SimpleCaching
```

# SimpleCaching

```@contents
```

This package provides two macros used to cache result(s) of function calls.

The cached file will survive the julia session so it will be automatically loaded from the
disk even after a restart of the julia session.

#### Differences with other packages

Most packages that provide caching functionality offers macros that are strictly bounded to
function definitions (e.g. [Caching.jl](https://github.com/zgornel/Caching.jl))); this
means that if, for example, a `println` is added to a function definition the cached file
will not be loaded. To work around this problem, the macros exposed by this package only use
the function name and the value of the parameters at the time of the call to determine if
the result can be loaded from the cache, if any.

## Installation

This packages is registered so you can install it by executing the following commands in a
Julia REPL:

```julia
import Pkg
Pkg.add("SimpleCaching")
```

or, to install the developement version, run:

```julia
import Pkg
Pkg.add("https://github.com/ferdiu/SimpleCaching.jl#dev")
```

## Usage

Start using the macros as follow:

```julia-repl
julia> using SimpleCaching

julia> SimpleCaching.settings.log = true; # log when saving/loading cache

julia> @scache "cute-cube" "./" fill(0, 3, 3, 3)
● [ 2022-12-09 15:39:42 ] Computing cute-cube...
● [ 2022-12-09 15:39:42 ] Computed cute-cube in 0.009 seconds (00:00:00)
● [ 2022-12-09 15:39:44 ] Saving cute-cube to file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld[.tmp]...
3×3×3 Array{Int64, 3}:
[:, :, 1] =
 0  0  0
 0  0  0
 0  0  0

[:, :, 2] =
 0  0  0
 0  0  0
 0  0  0

[:, :, 3] =
 0  0  0
 0  0  0
 0  0  0

```

if the same function will be called again with the same parameters this will result in the
cache to be loaded instead of performing the calculation again.

The cache is saved on the disk so it will be loaded even in subsequent julia sessions making
these macros particularly useful whene executing long calculations inside cycles withing
Julia scripts).

```julia-repl

julia> @scache "cute-cube" "./" fill(0, 3, 3, 3)
● [ 2022-12-09 15:39:56 ] Loading cute-cube from file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld...
3×3×3 Array{Int64, 3}:
[:, :, 1] =
 0  0  0
 0  0  0
 0  0  0

[:, :, 2] =
 0  0  0
 0  0  0
 0  0  0

[:, :, 3] =
 0  0  0
 0  0  0
 0  0  0
```

See [`Macros`](@ref man-macros) section for more details on how to use them.

## Settings

Some behaviour of the macros can be tweaked chaning the values of the settings:

```@docs
SimpleCachingSettings
```
