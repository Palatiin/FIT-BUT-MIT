/*
 * KRY - Project 2 - MAC Using SHA-256 & Lenght Extension Attack
 * Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
 * Date: 15.04.2024
 * Description: Implementation of SHA256 algorithm, and the MessageBlocks class.
 */

#include "sha256.hpp"


MessageBlocks::MessageBlocks(std::string message) {
    // Calculate size of the blocks, and allocate memory for it.
    uint32_t message_length = static_cast<uint32_t>(message.size());
    uint64_t required_bits = message_length * BYTE_BITS + MESSAGE_LENGTH_BITS + 1;
    while (size < required_bits) {
        size += BLOCK_SIZE;
        length += BLOCK_SIZE_UINT32_COUNT;
    }
    data = (uint32_t *) calloc(size, 1);
    if (data == nullptr) {
        std::cerr << "Memory allocation failed.\n";
        exit(ERROR_ALLOCATION);
    }

    // Store message into the blocks, which makes them ready for SHA-256.
    uint32_t word = 0;
    char shift;
    for (uint32_t i = 0; i < message_length; ++i) {
        shift = (4 - (i % 4 + 1)) * BYTE_BITS;
        uint32_t msg_32b = static_cast<uint32_t>(message[i]);
        word |= (msg_32b << shift);
        if (((i + 1) % 4) == 0){
            data[i / 4] = word;
            word = 0;
        }
    }
    shift = (4 - (message_length % 4 + 1)) * BYTE_BITS;
    word |= 0x80 << shift;
    uint32_t last_index = message_length / 4;
    data[last_index] = word;
    uint64_t message_bits = static_cast<uint64_t>(message_length) * BYTE_BITS;
    data[length - 2] = message_bits >> 32;
    data[length - 1] = message_bits & 0xFFFFFFFF;
}


MessageBlocks::~MessageBlocks() {
    if (data != nullptr) {
        free(data);
        data = nullptr;
    }
}

void MessageBlocks::print_blocks() {
    for (uint32_t i = 0; i < length; i++) {
        std::bitset<BLOCK_PRINT_ROW_BITS> binary(data[i]);
        std::cout << binary << std::endl;
    }
}


SHA256::SHA256() {
    // Initialize hash values.
    hash[0] = 0x6a09e667;
    hash[1] = 0xbb67ae85;
    hash[2] = 0x3c6ef372;
    hash[3] = 0xa54ff53a;
    hash[4] = 0x510e527f;
    hash[5] = 0x9b05688c;
    hash[6] = 0x1f83d9ab;
    hash[7] = 0x5be0cd19;
}

SHA256::~SHA256() {}

void SHA256::digest(MessageBlocks &blocks) {
    // Actual SHA-256 algorithm.
    uint32_t w[64] = {0,};  // Message schedule - W_t.
    uint32_t a, b, c, d, e, f, g, h;  // Working variables.
    uint32_t tmp1, tmp2;  // Temporary variables.

    for (uint32_t i = 0; i < blocks.size / BLOCK_SIZE; ++i) {
        // Prepare message schedule - W_t.
        for (uint32_t t = 0; t < BLOCK_SIZE_UINT32_COUNT; ++t) {
            w[t] = blocks.data[i * BLOCK_SIZE_UINT32_COUNT + t];
        }
        for (uint32_t t = BLOCK_SIZE_UINT32_COUNT; t < 64; ++t) {
            w[t] = sigma1(w[t - 2]) + w[t - 7] + sigma0(w[t - 15]) + w[t - 16];
        }

        // Initialize working variables.
        a = hash[0]; b = hash[1]; c = hash[2]; d = hash[3];
        e = hash[4]; f = hash[5]; g = hash[6]; h = hash[7];

        // Main loop.
        for (uint32_t t = 0; t < 64; ++t) {
            tmp1 = h + sum1(e) + ch(e, f, g) + K[t] + w[t];
            tmp2 = sum0(a) + maj(a, b, c);
            // Update working variables.
            h = g; g = f; f = e; e = d + tmp1;
            d = c; c = b; b = a; a = tmp1 + tmp2;
        }

        // Compute the i-th intermediate hash value.
        hash[0] += a; hash[1] += b; hash[2] += c; hash[3] += d;
        hash[4] += e; hash[5] += f; hash[6] += g; hash[7] += h;
    }
}

std::string SHA256::hexdigest() {
    // Convert hash to string (hex).
    std::stringstream ss;
    for (uint32_t i = 0; i < 8; ++i) {
        ss << std::hex << std::setfill('0') << std::setw(2) << ((hash[i] >> 24) & 0xFF);
        ss << std::hex << std::setfill('0') << std::setw(2) << ((hash[i] >> 16) & 0xFF);
        ss << std::hex << std::setfill('0') << std::setw(2) << ((hash[i] >> 8) & 0xFF);
        ss << std::hex << std::setfill('0') << std::setw(2) << (hash[i] & 0xFF);
    }
    return ss.str();
}

// SHA-256 functions.

// Rotate right.
uint32_t SHA256::rotr(uint32_t x, uint32_t n) {
    return (x >> n) | (x << (32 - n));
}

uint32_t SHA256::ch(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) ^ (~x & z);
}

uint32_t SHA256::maj(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) ^ (x & z) ^ (y & z);
}

uint32_t SHA256::sum0(uint32_t x) {
    return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
}

uint32_t SHA256::sum1(uint32_t x) {
    return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
}

uint32_t SHA256::sigma0(uint32_t x) {
    return rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
}

uint32_t SHA256::sigma1(uint32_t x) {
    return rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);
}
