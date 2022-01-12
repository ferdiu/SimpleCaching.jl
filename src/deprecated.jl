
macro scachefast(type, common_cache_dir, ex)
	Base.depwarn("`scachefast` is deprecated, use `scache` instead.", :scachefast)

	:(@scache $(esc(type)) $(esc(common_cache_dir)) $(esc(ex)))
end
