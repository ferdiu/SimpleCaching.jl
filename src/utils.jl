
"""
	_start_timer()

Same as `using Dates; now()`.
"""
_start_timer() = Dates.now()

"""
	_stop_timer(d)

Same as `using Dates; now() - d` where `d` is a DateTime object.
"""
_stop_timer(d::DateTime) = Dates.now() - d

"""
	get_hash_sha256(var)

Get the hash of the content of `var` using SHA256 algorithm.
"""
function get_hash_sha256(var)::String
	io = IOBuffer();
	serialize(io, var)
	result = bytes2hex(sha256(take!(io)))
	close(io)

	result
end

"""
	printcheckpoint([io::IO], any...; format)

Print `any...` to `io` and flush preceeded by the current DateTime in `format`.

A line starter can be specified by the keyword argument `start`. Default is "● ".
"""
function printcheckpoint(
	io::IO, string::AbstractString...;
	format = "dd/mm/yyyy HH:MM:SS",
	start = "● "
)
	println(io, start, Dates.format(now(), "[ $(format) ] "), string...)
	flush(io)
end
printcheckpoint(string::AbstractString...; kwargs...) = printcheckpoint(stdout, string...; kwargs...)
printcheckpoint(io::IO, any::Any...; kwargs...) = printcheckpoint(io, string(any...); kwargs...)
printcheckpoint(any::Any...; kwargs...) = printcheckpoint(stdout, any...; kwargs...)

"""
	human_readable_time(milliseconds)

Print elapsed time in format "HH:MM:SS".
"""
function human_readable_time(ms::Dates.Millisecond)::String
	result = ms.value / 1000
	seconds = round(Int64, result % 60)
	result /= 60
	minutes = round(Int64, result % 60)
	result /= 60
	hours = round(Int64, result % 24)
	string(string(hours; pad=2), ":", string(minutes; pad=2), ":", string(seconds; pad=2))
end

"""
	human_readable_time_s(milliseconds)

Print elapsed time in seconds.
"""
function human_readable_time_s(ms::Dates.Millisecond)::String
	string(ms.value / 1000)
end

"""
	throw_n_log(message; error_type = ErrorException)

Call `@error msg` before throwning.
"""
function throw_n_log(msg::AbstractString; error_type::Type{<:Exception} = ErrorException)
	@error msg
	throw(error_type(msg))
end

## conversion utilities ##

"""
	_strarg(arg)

A utility function used to generate a String representing the final Expr that will cause
the cached file to be loaded.
This means that the following calls will produce the same strings:

```
x = 10
@scache "my-cute-vector" "./" fill(0, 10)
@scache "my-cute-vector" "./" fill(0, x)
@scache "my-cute-vector" "./" fill(0, 5 + 5)
```

This function is called inside [`@_scache`](@ref) to generate the string that will fill the
column `COMMAND` in the cache record (if generated).
"""
_strarg(arg::Any) = string(arg)
_strarg(arg::Symbol) = @eval Main $arg
_strarg(arg::QuoteNode) = typeof(arg.value) == Symbol ? string(":$(arg.value)") : _strarg(arg.value)
_strarg(arg::AbstractString) = arg
function _strarg(arg::Expr)
	if arg.head == :escape
		return _strarg(arg.args[1])
	elseif arg.head == :call
		_args = filter(x -> !(typeof(x) == Expr && (x.head == :parameters || x.head == :kw)), arg.args[2:end])

		_params = filter(x -> typeof(x) == Expr && x.head == :parameters, arg.args[2:end])
		_kw =
			if length(_params) > 0
				vcat([p.args for p in _params]...)
			else
				[]
			end
		append!(_kw, filter(x -> typeof(x) == Expr && x.head == :kw, arg.args[2:end]))

		return "$(arg.args[1])(" * join([@eval $a for a in _args], ", ") * "$(length(_kw) > 0 ? "; " * join(_strarg.(_kw), ", ") : ""))"
	elseif arg.head == :kw
		return "$(arg.args[1]) = $(_strarg(arg.args[2]))"
	elseif arg.head == :parameters
		return join(_strarg.(arg.args), ", ")
	else
		string(@eval Main $arg)
	end
end

"""
	_convert_input(arg)

A utility function used to generate a stable Tuple containing the information that will be
used to generate the hash of the cached file.

The resulting object is a NamedTuple{(:args,:keargs),Tuple{T,D}} where T isa a ordered
Tuple containing the arguments passed to the function called and D is a Dict{Symbol,Any}
containing the keyword arguments passed.

Note: a dictionary is used for the keyword arguments because otherwise the hash would change
based on the their order.
"""
_convert_input(arg::Any) = arg
_convert_input(arg::Symbol) = @eval Main $arg
_convert_input(arg::QuoteNode) = typeof(arg.value) == Symbol ? arg.value : _convert_input(arg.value)
function _convert_input(arg::Expr)
	if arg.head == :escape
		return _convert_input(arg.args[1])
	elseif arg.head == :call
		_args = filter(x -> !(typeof(x) == Expr && (x.head == :parameters || x.head == :kw)), arg.args[2:end])

		_params = filter(x -> typeof(x) == Expr && x.head == :parameters, arg.args[2:end])
		_kw =
			if length(_params) > 0
				vcat([p.args for p in _params]...)
			else
				[]
			end
		append!(_kw, filter(x -> typeof(x) == Expr && x.head == :kw, arg.args[2:end]))

		return (args = [@eval $a for a in _args], kwargs = Dict{Symbol,Any}(_convert_input.(_kw)))
	elseif arg.head == :kw
		return arg.args[1] => _convert_input(arg.args[2])
	elseif arg.head == :parameters
		return _convert_input.(arg.args)
	else
		@eval Main $arg
	end
end

## escaping utilities ##

isescaped(ex::Any) = false
isescaped(ex::Expr) = typeof(ex) == Expr && ex.head == :escape
unesc(ex::Expr) = ex.args[1]
safeunesc(ex::Expr) = isescaped(ex) ? unesc(ex) : ex
function escdepth(ex::Expr)
	res::Int = 0
	curr_ex = ex
	while (isescaped(curr_ex))
		curr_ex = unesc(curr_ex)
		res += 1
	end
	return res
end
function esc(ex::Expr, n::Integer)
	res = ex
	for i in 1:n
		res = esc(res)
	end
	return res
end
function unesc_comp(ex::Expr)
	res = ex
	while (isescaped(res))
		res = unesc(res)
	end
	return res
end
