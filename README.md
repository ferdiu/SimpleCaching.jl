# SimpleCaching

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ferdiu.github.io/SimpleCaching.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ferdiu.github.io/SimpleCaching.jl/dev)
[![Build Status](https://travis-ci.com/ferdiu/SimpleCaching.jl.svg?branch=main)](https://travis-ci.com/ferdiu/SimpleCaching.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/ferdiu/SimpleCaching.jl?svg=true)](https://ci.appveyor.com/project/ferdiu/SimpleCaching-jl)
[![Build Status](https://api.cirrus-ci.com/github/ferdiu/SimpleCaching.jl.svg)](https://cirrus-ci.com/github/ferdiu/SimpleCaching.jl)
[![Coverage](https://codecov.io/gh/ferdiu/SimpleCaching.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ferdiu/SimpleCaching.jl)
[![Coverage](https://coveralls.io/repos/github/ferdiu/SimpleCaching.jl/badge.svg?branch=main)](https://coveralls.io/github/ferdiu/SimpleCaching.jl?branch=main)

This package provides two macros used to cache result(s) of function calls.

The cached file will survive the julia session so it will be automatically loaded from the disk even after a restart of the julia session.

# Usage

## Installation

```Julia
using Pkg
Pkg.add(url="https://github.com/ferdiu/SimpleCaching.jl.git")
using SimpleCaching
```

## Caching function result using JLD2

```Julia
julia> SimpleCaching.settings.log = true
true

julia> @scache "cute-cube" "./" fill(0, 3, 3, 3)
● [ 31/12/2021 09:54:08 ] Computing cute-cube...
● [ 31/12/2021 09:54:08 ] Computed cute-cube in 0.044 seconds (00:00:00)
● [ 31/12/2021 09:54:13 ] Saving cute-cube to file ./cute-cube_8ad46882688c6820fc0b59db89cfe7f6ca494e3045d7ece8acba1027c4c03c45.jld[.tmp]...

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
 ● [ 31/12/2021 09:54:24 ] Loading cute-cube from file ./cute-cube_8ad46882688c6820fc0b59db89cfe7f6ca494e3045d7ece8acba1027c4c03c45.jld...
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

## Caching function result using Serialize

For large files or complicated structers it is advised to cache results using the macro `@scachefast` which provides faster serialization and smaller files on disk at the cost of less portability (see [Serialization](https://docs.julialang.org/en/v1/stdlib/Serialization/)).

```Julia
julia> SimpleCaching.settings.log = true
true

julia> @scachefast "cute-cube" "./" fill(0, 3, 3, 3)
● [ 31/12/2021 09:54:08 ] Computing cute-cube...
● [ 31/12/2021 09:54:08 ] Computed cute-cube in 0.044 seconds (00:00:00)
● [ 31/12/2021 09:54:13 ] Saving cute-cube to file ./cute-cube_8ad46882688c6820fc0b59db89cfe7f6ca494e3045d7ece8acba1027c4c03c45.jld[.tmp]...

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
 ● [ 31/12/2021 09:54:24 ] Loading cute-cube from file ./cute-cube_8ad46882688c6820fc0b59db89cfe7f6ca494e3045d7ece8acba1027c4c03c45.jld...
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
