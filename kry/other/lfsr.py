# Linear Feedback Shift Register

class LFSR:
    """Little Endian LFSR - taps and state = List[ MSB-LSB ]."""
    def __init__(self, taps: list, initial_state: list):
        # indexes of bits, which will be tapped
        self.taps = taps
        # state of the shift register
        self.state = initial_state

    def shift(self) -> int:
        bit = self.state[-1]
        feedback_bit = sum(self.state[tap] for tap in self.taps) % 2

        # shift right(drop lsb), push new bit from left
        self.state = [feedback_bit] + self.state[:-1]

        return bit


class RevLFSR(LFSR):
    """Big Endian LFSR - taps and state = List[ LSB-MSB ]."""
    def shift(self) -> int:
        bit = self.state[0]
        feedback_bit = sum(self.state[tap] for tap in self.taps) % 2

        # shift left(drop lsb), push new bit from right
        self.state = self.state[1:] + [feedback_bit]

        return bit


class BinaryLFSR:
    """Binary LFSR - taps and state = binary."""
    def __init__(self, taps: int, initial_state: int):
        self.taps = taps  # mask
        self.state = initial_state
        self.msb = max(taps.bit_length(), self.state.bit_length()) - 1

    def shift(self) -> int:
        bit = self.state & 0b1
        feedback_bit = ((self.state & self.taps).bit_count()) % 2
        # feedback_bit = (self.state ^ self.state >> 1) & 1
        self.state = feedback_bit << self.msb | self.state >> 1

        return bit


if __name__ == "__main__":
    BITS = 20

    lfsr = LFSR(taps=[2, 3], initial_state=[1, 0, 0, 1])
    num = sum(lfsr.shift() << i for i in range(BITS))
    print(f"LFSR:    {num} ({bin(num)})")

    rev_lfsr = RevLFSR(taps=[0, 1], initial_state=[1, 0, 0, 1])
    num = sum(rev_lfsr.shift() << i for i in range(BITS))
    print(f"RevLFSR: {num} ({bin(num)})")

    bin_lfsr = BinaryLFSR(taps=0b0011, initial_state=0b1001)
    num = sum(bin_lfsr.shift() << i for i in range(BITS))
    print(f"BinLFSR: {num} ({bin(num)})")
