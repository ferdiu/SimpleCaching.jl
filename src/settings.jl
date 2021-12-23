
"""
SimpleCachingSettings is a struct containing settings for exported macros `@scache` and
`@scachefast`.

## Fields

- `log`: a Bool indicating whether to log or not operations like computing, saving and
loading. Default is `false`.
- `log_output`: a IO containing the file descriptor the log will be written to; ignored if
`log` is `false`. Default is `stdout`.
- `date_format`: a String representing the format the DateTime will be printed when logging;
ignored if `log` is `false`. Default is `"dd/mm/yyyy HH:MM:SS"`.
- `line_started`: a String that will be placed at the beginning of the log; ignored if `log`
is `false`. Default is `"● "`.
- `create_cache_record`: a Bool indicating whether to create a tsv file containing human
readable informations about the saved file. Default is `true`.
"""
mutable struct SimpleCachingSettings
    log::Bool
    log_output::IO
    date_format::AbstractString
    line_starter::AbstractString
    create_cache_record::Bool
end

const settings = SimpleCachingSettings(false, stdout, "dd/mm/yyyy HH:MM:SS", "● ", true)

_use_serialize = false

_closelog(io::IO) = nothing
_closelog(io::IOStream) = close(io)
_closelog(io::Channel) = close(io)

_closelog() = _closelog(settings.log_output)
