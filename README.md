# SimpleCaching

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ferdiu.github.io/SimpleCaching.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ferdiu.github.io/SimpleCaching.jl/dev)
[![Build Status](https://api.cirrus-ci.com/github/ferdiu/SimpleCaching.jl.svg)](https://cirrus-ci.com/github/ferdiu/SimpleCaching.jl)

This package provides two macros used to cache result(s) of function calls.

The cached file will survive the julia session so it will be automatically loaded from the
disk even after a restart of the julia session.

# Usage

## Installation

```Julia
using Pkg
Pkg.add(url="https://github.com/ferdiu/SimpleCaching.jl.git")
using SimpleCaching
```

## Caching function result using Serialize

For large files or complicated structers it is advised to cache results using the macro
`@scache` which provides faster serialization and smaller files on disk at the cost of less
portability (see [Serialization](https://docs.julialang.org/en/v1/stdlib/Serialization/)).

```Julia
julia> using SimpleCaching

julia> SimpleCaching.settings.log = true;

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

### Conditional caching

It is possible to cache the result of a function call based on the value returned by an
expression using the macro "@scache_if" as follows:

```Julia
julia> @scache_if true "cute-cube" "./" fill(0, 3, 3, 3)
● [ 2022-12-09 15:41:54 ] Loading cute-cube from file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld...
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

but passing a `false` `condition` (note there is no loading log):

```Julia
julia> @scache_if false "cute-cube" "./" fill(0, 3, 3, 3)
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

just substitute an expression for `true` and `false`.

## Caching function result using JLD2

```Julia
julia> using SimpleCaching

julia> SimpleCaching.settings.log = true;

julia> @scachejld "cute-cube" "./" fill(0, 3, 3, 3)
● [ 2022-12-09 15:40:45 ] Computing cute-cube...
● [ 2022-12-09 15:40:45 ] Computed cute-cube in 0.0 seconds (00:00:00)
● [ 2022-12-09 15:40:45 ] Saving cute-cube to file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld[.tmp]...
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

julia> @scachejld "cute-cube" "./" fill(0, 3, 3, 3)
● [ 2022-12-09 15:40:47 ] Loading cute-cube from file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld...
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

Conditional caching is possible for JLD2 macro using `@scachejld_if`.
