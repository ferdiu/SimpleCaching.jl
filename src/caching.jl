
_default_table_file_name(type::AbstractString) = "$(type)_cached.tsv"
_default_jld_file_name(type::AbstractString, hash::AbstractString) = string("$(type)_$(hash).jld")

function cached_obj_exists(
	type::AbstractString, common_cache_dir::AbstractString, hash::AbstractString
)::Bool
	return isdir(common_cache_dir) &&
		isfile(joinpath(common_cache_dir, _default_jld_file_name(type, hash)))
end

function cache_obj(
	type::AbstractString,
	common_cache_dir::AbstractString,
	obj::Any,
	hash::AbstractString,
	args_string::AbstractString;
	column_separator::AbstractString = "\t",
	time_spent::Dates.Millisecond,
	use_serialize::Bool = false
)

	total_save_path = joinpath(common_cache_dir, _default_jld_file_name(type, hash))
	mkpath(dirname(total_save_path))

	cache_table_exists = isfile(joinpath(common_cache_dir, _default_table_file_name(type)))

	# cache record
	if settings.create_cache_record
		table_file = open(joinpath(common_cache_dir, _default_table_file_name(type)), "a+")

		if !cache_table_exists
			write(table_file,
				join([
					"TIMESTAMP",
					"FILE NAME",
					"COMP TIME",
					"COMMAND",
					"TYPE",
					"JULIA_VERSION",
					"\n"
				], column_separator))
		end

		write(table_file, string(
				Dates.format(Dates.now(), "dd/mm/yyyy HH:MM:SS"), column_separator,
				_default_jld_file_name(type, hash), column_separator,
				human_readable_time(time_spent), column_separator,
				args_string, column_separator,
				typeof(obj), column_separator,
				VERSION, column_separator,
				"\n"))
		close(table_file)
	end

	# log
	if settings.log
		printcheckpoint(
				settings.log_output,
				"Saving $(type) to file $(total_save_path)[.tmp]...";
				format = settings.date_format
			)
	end

	if use_serialize
		Serialization.serialize("$(total_save_path).tmp", obj)
	else
		@save "$(total_save_path).tmp" obj
	end
	mv("$(total_save_path).tmp", "$(total_save_path)"; force = true)
end

function load_cached_obj(
	type::AbstractString, common_cache_dir::AbstractString, hash::AbstractString
)
	total_load_path = joinpath(common_cache_dir, _default_jld_file_name(type, hash))

	if settings.log
		printcheckpoint(SimpleCaching.settings.log_output, "Loading $(type) from file " *
			"$(total_load_path)..."; format = settings.date_format)
	end

	obj = nothing

	# TODO use magic number check instead of try/catch
	try
		@load total_load_path obj
	catch e
		try
			obj = Serialization.deserialize(total_load_path)
		catch e
			throw_n_log("File $(total_load_path) is neither in JLD2 format nor a " *
				"Serialized object", ArgumentError)
		end
	end

	obj
end

macro _scache(type, common_cache_dir, ex)
	will_use_serialize = _use_serialize

	esc_times = escdepth(ex)
	ex = unesc_comp(ex)

	(typeof(ex) != Expr || ex.head != :call) && (throw(ArgumentError("`@scache[jld]` can " *
		"be used only with function calls: passed $(ex)")))

	# hyigene
	type = esc(type)
	common_cache_dir = esc(common_cache_dir)
	ex = esc(ex, esc_times)

	t = _convert_input(ex, true)

	rel_esc(ex) = esc(ex, esc_times+1)
	as, ks, vs, res = (_toexpr(t.args), _toexpr(t.kwargs)..., t.res)

	# TODO: make a function that interprets `res` to be inserted in `args` or `kwargs`
	return quote
		_hash = get_hash_sha256((
			args = $(rel_esc(as)),
			kwargs = merge(
				Dict{Symbol,Any}(
					zip(
						$(rel_esc(ks)),
						$(rel_esc(vs))
					)
				),
				Dict{Symbol,Any}(
					pairs($(rel_esc(res)))
				)
			)
		))

		if cached_obj_exists($(type), $(common_cache_dir), _hash)
			load_cached_obj($(type), $(common_cache_dir), _hash)
		else
			if settings.log
				printcheckpoint(
					settings.log_output, "Computing " * $(type) * "...";
					format = settings.date_format,
					start = settings.line_starter
				)
			end

			_started = _start_timer()
			_result_value = $(esc(ex))
			_finish_time = _stop_timer(_started)

			if settings.log
				printcheckpoint(
					settings.log_output,
					"Computed " * $(type) * " in " * human_readable_time_s(_finish_time) *
						" seconds (" * human_readable_time(_finish_time) * ")";
					format = settings.date_format,
					start = settings.line_starter
				)
			end

			cache_obj(
				$(type),
				$(common_cache_dir),
				_result_value,
				_hash,
				$(rel_esc(_strarg(ex, true))),
				time_spent = _finish_time,
				use_serialize = $(esc(will_use_serialize))
			)

			_result_value
		end
	end
end

const _ext_docs = """!!! note

	The file extension will be `.jld` when using both [`scache`](@ref) and
	[`scachejld`](@ref).
"""

const _same_args_docs = """Expressions in function argument will be computed as first step
so the cached file will be loaded even if the arguments are different but will evaluate to
the same result.
"""

"""
	scache(type, cache_dir, function_call)

Cache the result of `function_call` in directory `cache_dir` prefixing the saved file with
`type`.

This macro uses `Serialize` `serialize` and `deserialize` functions to save and load cached
files so it is faster and more memory efficent than [`scachejld`](@ref) macro which uses
`JLD2` which, on the other hand, is more portable between different julia versions.

$_ext_docs

## Examples
```
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

shell> ls -l cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld
-rw-r--r--. 1 user user 232  9 dic 15.39 cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld

```

$_same_args_docs

```
julia> @scache "cute-cube" "./" fill(0, 3, parse(Int, "3"), 3)
● [ 2022-12-09 09:41:54 ] Loading cute-cube from file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld...
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
"""
macro scache(type, common_cache_dir, ex)
	global _use_serialize = true

	:(@_scache $(esc(type)) $(esc(common_cache_dir)) $(esc(ex)))
end


"""
	scachejld(type, cache_dir, function_call)

Cache the result of `function_call` in directory `cache_dir` prefixing the saved file with
`type`.

This macro uses `JLD2` `@save` and `@load` macros to save and load cached files so it is
slower and less memory efficent than [`scache`](@ref) macro which uses `serialize`
which, on the other hand, is less portable between different julia versions.

$_ext_docs

## Examples
```
julia> using SimpleCaching

julia> SimpleCaching.settings.log = true;

julia> @scachejld "cute-cube" "./" fill(0, 3, 3, 3)
● [ 2022-12-09 15:56:09 ] Computing cute-cube...
● [ 2022-12-09 15:56:09 ] Computed cute-cube in 0.0 seconds (00:00:00)
● [ 2022-12-09 15:56:09 ] Saving cute-cube to file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld[.tmp]...
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
● [ 2022-12-09 15:56:19 ] Loading cute-cube from file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld...
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

shell> ls -l cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld
-rw-r--r--. 1 user user 1000  9 dic 15.56 cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld

```

$_same_args_docs

```
julia> @scachejld "cute-cube" "./" fill(0, 3, round(Int64, 1.5 * 2), 3)
● [ 2022-12-09 15:59:13 ] Loading cute-cube from file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld...
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
"""
macro scachejld(type, common_cache_dir, ex)
	global _use_serialize = false

	:(@_scache $(esc(type)) $(esc(common_cache_dir)) $(esc(ex)))
end

"""
	scache_if(condition, type, cache_dir, function_call)

Cache the result of `function_call` only if `condition` is `true`.

Note that will not be loaded the cached result even if present.

For other parameters docs see [`scache_if`](@ref).

## Examples
```
julia> using SimpleCaching

julia> SimpleCaching.settings.log = true;

julia> @scache_if true "cute-cube" "./" fill(0, 3, 3, 3)
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

shell> ls -lh cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld
-rw-r--r--. 1 user user 1000 9 dic 09.54 cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld

```

but passing a `false` `condition` (note there is no loading log):

```
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
"""
macro scache_if(condition, type, common_cache_dir, ex)
	return quote
		if $(esc(condition))
			@scache $(esc(type)) $(esc(common_cache_dir)) $(esc(ex))
		else
			$(esc(ex))
		end
	end
end

"""
	scachejld_if(condition, type, cache_dir, function_call)

Cache the result of `function_call` only if `condition` is `true`.

Note that will not be loaded the cached result even if present.

For other parameters docs see [`scachejld`](@ref).

## Examples
```
julia> using SimpleCaching

julia> SimpleCaching.settings.log = true;

julia> @scachejld_if true "cute-cube" "./" fill(0, 3, 3, 3)
● [ 2022-12-09 16:06:42 ] Computing cute-cube...
● [ 2022-12-09 16:06:42 ] Computed cute-cube in 0.009 seconds (00:00:00)
● [ 2022-12-09 16:06:44 ] Saving cute-cube to file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld[.tmp]...
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

julia> @scachejld_if true "cute-cube" "./" fill(0, 3, 3, 3)
● [ 2022-12-09 16:07:04 ] Loading cute-cube from file ./cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld...
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

shell> ls -lh cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld
-rw-r--r--. 1 user user 1000 9 dic 16.07 cute-cube_4bbf9c2851f2c2b3954448f1a8085f6e3d40085add71f19640343885a8b7bd6a.jld

```

but passing a `false` `condition` (note there is no loading log):

```
julia> @scachejld_if false "cute-cube" "./" fill(0, 3, 3, 3)
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
"""
macro scachejld_if(condition, type, common_cache_dir, ex)
	return quote
		if $(esc(condition))
			@scachejld $(esc(type)) $(esc(common_cache_dir)) $(esc(ex))
		else
			$(esc(ex))
		end
	end
end
