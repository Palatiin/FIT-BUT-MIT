from rbloom import Bloom

class BloomFilterPSI:
    """
    Bloom Filter based PSI
    """
    bloom_filters: list[Bloom]

    def __init__(self, filters: list[Bloom]):
        self.bloom_filters = filters
    
    def intersection(self) -> Bloom:
        assert len(self.bloom_filters) > 1, "At least two bloom filters are required"
        result = self.bloom_filters[0]
        for bloom_filter in self.bloom_filters[1:]:
            result = result & bloom_filter
        return result
