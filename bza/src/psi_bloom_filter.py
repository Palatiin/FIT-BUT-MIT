import math
import hashlib


class Bloom:
    """
    Basic Bloom filter implementation for demo purposes.

    Can be replaced by a library, e.g. rbloom, which is faster (Rust implementation).
    """

    def __init__(self, expected_elements: int, false_positive_rate: float):
        self.n = expected_elements
        self.p = false_positive_rate
        self.m = self.optimal_m(self.n, self.p)  # size of the bit array
        self.k = self.optimal_k(self.n, self.m)  # number of hash functions
        self.bit_array = 0b0  # bit array

    def optimal_m(self, n: int, p: float) -> int:
        return int(-(n * math.log(p)) / (math.log(2) ** 2))

    def optimal_k(self, n: int, m: int) -> int:
        return int(math.log(2) * m / n)

    def hash(self, item: str) -> int:
        bloom_hash = 0b0
        for i in range(self.k):
            hash_value = (
                int.from_bytes(
                    hashlib.sha256(f"{item}{i}".encode()).digest(), byteorder="big"
                )
                % self.m
            )
            bloom_hash |= 1 << hash_value
        return bloom_hash

    def add(self, item: str):
        self.bit_array |= self.hash(item)

    def __and__(self, other: "Bloom"):
        result = Bloom(self.n, self.p)
        result.bit_array = self.bit_array & other.bit_array
        return result

    def __contains__(self, item: str) -> bool:
        bloom_hash = self.hash(item)
        return bloom_hash & self.bit_array == bloom_hash

    def print_bit_array(self):
        print(f"{self.bit_array:0{self.m}b}")


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
