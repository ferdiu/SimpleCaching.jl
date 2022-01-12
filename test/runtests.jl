using SimpleCaching
using Test

const testing_cache_dir = mktempdir(prefix = "SimpleCaching_test_")
const cached_type = "testing_object"

module A
    using SimpleCaching

    export heavy_computation

    function heavy_computation(cached_type, testing_cache_dir, x, s::Integer...)
        return @scachefast cached_type testing_cache_dir fill(x, s...)
    end
end

@testset "SimpleCaching.jl" begin
    # test @scache
    res1 = @scache cached_type testing_cache_dir fill(0.0, 10, 10, 10)
    res2 = @scache cached_type testing_cache_dir fill(0.0, 10, 10, 10)
    res3 = @scache cached_type testing_cache_dir fill(Float64(1 - 1), 10, 10, 10)
    res4 = @scache cached_type testing_cache_dir fill(res3[1,1,1], 10, 10, 10)

    res = fill(0.0, 10, 10, 10)

    @test res1 == res
    @test res2 == res
    @test res3 == res
    @test res4 == res

    # test @scachejld
    res1 = @scachejld cached_type testing_cache_dir fill(0.0, 20, 20, 20)
    res2 = @scachejld cached_type testing_cache_dir fill(0.0, 20, 20, 20)
    res3 = @scachejld cached_type testing_cache_dir fill(Float64(1 - 1), 20, 20, 20)
    res4 = @scachejld cached_type testing_cache_dir fill(res3[1,1,1], 20, 20, 20)

    res = fill(0.0, 20, 20, 20)

    @test res1 == res
    @test res2 == res
    @test res3 == res
    @test res4 == res

    # test using macro within another module
    using .A
    hc = heavy_computation(cached_type, testing_cache_dir, 0.0, 20, 20, 20)

    @test hc == res

    # test with local variables
    begin
        local n = 10

        @scache cached_type testing_cache_dir vcat(fill(1, n), fill(2, 2n))
    end
end
