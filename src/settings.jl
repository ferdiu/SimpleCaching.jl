
"""
SimpleCachingSettings is a struct containing settings for exported macros `@scache` and
`@scachefast`.

## Fields

- `log`: a Bool indicating whether to log or not operations like computing, saving and
    loading. Default is `false`.
- `log_output`: a IO containing the file descriptor the log will be written to; ignored if
    `log` is `false`. Default is `stdout`.
- `date_format`: a String representing the format the DateTime will be printed when logging;
    ignored if `log` is `false`. Default is `"yyyy-mm-dd HH:MM:SS"`.
- `line_started`: a String that will be placed at the beginning of the log; ignored if `log`
    is `false`. Default is `"● "`.
- `create_cache_record`: a Bool indicating whether to create a tsv file containing human
    readable informations about the saved file. Default is `false`;
- `cache_dir`: this is the default directory the cache will be saved in when not specified
    in the macro call. Default is `./_sc_cache`.
"""
mutable struct SimpleCachingSettings
    log::Bool
    log_output::IO
    date_format::AbstractString
    line_starter::AbstractString
    create_cache_record::Bool
    cache_dir::AbstractString
end

const settings = SimpleCachingSettings(false, stdout, "yyyy-mm-dd HH:MM:SS", "● ", false, "./_sc_cache")

_use_serialize = false

_closelog(::IO) = nothing
_closelog(io::IOStream) = close(io)
_closelog(io::Channel) = close(io)

_closelog() = _closelog(settings.log_output)
