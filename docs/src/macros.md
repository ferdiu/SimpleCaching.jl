```@meta
CurrentModule = SimpleCaching
```

# [Macros](@id man-macros)

All the macros can be described as one:

```julia
@scache[jld][_if condition] type cache_dir function_call
```

when `jld` is specified right after `@scache` then `JLD2` will be used instead of
`Serialization`; when `_if condition` are specified right after `@scache[jld]` then the
caching will be used only if `condition` is verified.

For more details consult [`Caching`](@ref man-macros-caching) and
[`Conditional caching`](@ref man-macros-conditional-caching) sections below.


## [Caching](@id man-macros-caching)

```@docs
@scache
@scachejld
```

## [Conditional caching](@id man-macros-conditional-caching)

```@docs
@scache_if
@scachejld_if
```
