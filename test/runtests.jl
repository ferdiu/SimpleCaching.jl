using SimpleCaching
using Test

@testset "SimpleCaching.jl" begin
    testing_cache_dir = mktempdir(prefix = "SimpleCaching_test_")
    cached_type = "testing_object"

    res1 = @scache cached_type testing_cache_dir fill(0.0, 10, 10, 10)
    res2 = @scache cached_type testing_cache_dir fill(0.0, 10, 10, 10)
    res3 = @scache cached_type testing_cache_dir fill(Float64(1 - 1), 10, 10, 10)

    res = fill(0.0, 10, 10, 10)

    @test res1 == res
    @test res2 == res
    @test res3 == res

    res1 = @scachefast cached_type testing_cache_dir fill(0.0, 20, 20, 20)
    res2 = @scachefast cached_type testing_cache_dir fill(0.0, 20, 20, 20)
    res3 = @scachefast cached_type testing_cache_dir fill(Float64(1 - 1), 20, 20, 20)

    res = fill(0.0, 20, 20, 20)

    @test res1 == res
    @test res2 == res
    @test res3 == res
end
