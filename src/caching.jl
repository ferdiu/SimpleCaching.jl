
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
				join(["TIMESTAMP", "FILE NAME", "COMP TIME", "COMMAND", "\n"], column_separator))
		end

		write(table_file, string(
				Dates.format(Dates.now(), "dd/mm/yyyy HH:MM:SS"), column_separator,
				_default_jld_file_name(type, hash), column_separator,
				human_readable_time(time_spent), column_separator,
				args_string, column_separator,
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
		printcheckpoint(SimpleCaching.settings.log_output, "Loading $(type) from file $(total_load_path)..."; format = settings.date_format)
	end

	obj = nothing

	# TODO use magic number check instead of try/catch
	try
		@load total_load_path obj
	catch e
		try
			obj = Serialization.deserialize(total_load_path)
		catch e
			throw_n_log("File $(total_load_path) is neither in JLD2 format nor a Serialized object", ArgumentError)
		end
	end

	obj
end

macro _scache(type, common_cache_dir, ex)
	will_use_serialize = _use_serialize

	esc_times = escdepth(ex)
	ex = unesc_comp(ex)

	(typeof(ex) != Expr || ex.head != :call) && (throw(ArgumentError("`@scache` can be used only with function calls: passed $(ex)")))

	# hyigene
	type = esc(type)
	common_cache_dir = esc(common_cache_dir)
	ex = esc(ex, esc_times)

	return quote
		_hash = get_hash_sha256(_convert_input($(QuoteNode(unesc(ex))) ))

		if cached_obj_exists($(type), $(common_cache_dir), _hash)
			load_cached_obj($(type), $(common_cache_dir), _hash)
		else
			if settings.log
				printcheckpoint(
					settings.log_output, "Computing " * $(type) * "...";
					format = settings.date_format,
					start = setings.line_starter
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
					start = setings.line_starter
				)
			end

			cache_obj(
				$(type),
				$(common_cache_dir),
				_result_value,
				_hash,
				_strarg($(QuoteNode(unesc(ex)))),
				time_spent = _finish_time,
				use_serialize = $(esc(will_use_serialize))
			)

			_result_value
		end
	end
end

"""
	scache(type, cache_dir, function_call)
"""
macro scache(type, common_cache_dir, ex)
	global _use_serialize = false

	:(@_scache $(esc(type)) $(esc(common_cache_dir)) $(esc(ex)))
end

"""
	scachefast(type, cache_dir, function_call)
"""
macro scachefast(type, common_cache_dir, ex)
	global _use_serialize = true

	:(@_scache $(esc(type)) $(esc(common_cache_dir)) $(esc(ex)))
end
