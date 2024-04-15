/*
 * Description: KRY - Project 2 - MAC Using SHA-256 & Lenght Extension Attack
 * Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
 * Date: 15.04.2024
 */

#include <iostream>
#include <cstdlib>
#include <cstdint>
#include <sstream>
#include <iomanip>
#include <string>
#include <bitset>

#define ERROR_HELP 1
#define ERROR_ALLOCATION 2

#define BYTE_BITS 8
#define BLOCK_SIZE_UINT32_COUNT 16
#define MESSAGE_LENGTH_BITS 64
#define BLOCK_SIZE 512
#define BLOCK_PRINT_ROW_BITS 32


class MessageBlocks {
    // Class which represents a block of a message, which is used for SHA-256.
    // It accepts string messages, and stores them in format suitable for SHA-256
    // - padding.
    friend class SHA256;
public:
    MessageBlocks(std::string message) {
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
        data[(message_length + 1) / 4] = word;
        uint64_t message_bits = static_cast<uint64_t>(message_length) * BYTE_BITS;
        data[length - 2] = message_bits >> 32;
        data[length - 1] = message_bits & 0xFFFFFFFF;
    }
    ~MessageBlocks() {
        if (data != nullptr) {
            free(data);
            data = nullptr;
        }
    }

    void print_block() {
        for (uint32_t i = 0; i < length; i++) {
            std::bitset<BLOCK_PRINT_ROW_BITS> binary(data[i]);
            std::cout << binary << std::endl;
        }
    }
protected:
    uint64_t size = BLOCK_SIZE;
    uint32_t length = BLOCK_SIZE_UINT32_COUNT;
    uint32_t *data = nullptr;
};


class SHA256 {
    // https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf
public:
    SHA256() {
        hash[0] = 0x6a09e667;
        hash[1] = 0xbb67ae85;
        hash[2] = 0x3c6ef372;
        hash[3] = 0xa54ff53a;
        hash[4] = 0x510e527f;
        hash[5] = 0x9b05688c;
        hash[6] = 0x1f83d9ab;
        hash[7] = 0x5be0cd19;
    }
    ~SHA256() {}

    void digest(MessageBlocks &blocks) {
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

    std::string to_string() {
        std::stringstream ss;
        for (uint32_t i = 0; i < 8; ++i) {
            ss << std::hex << std::setfill('0') << std::setw(2) << ((hash[i] >> 24) & 0xFF);
            ss << std::hex << std::setfill('0') << std::setw(2) << ((hash[i] >> 16) & 0xFF);
            ss << std::hex << std::setfill('0') << std::setw(2) << ((hash[i] >> 8) & 0xFF);
            ss << std::hex << std::setfill('0') << std::setw(2) << (hash[i] & 0xFF);
        }
        return ss.str();
    }
private:
    uint32_t hash[8];
    static constexpr uint32_t K[64] = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
        0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
        0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
        0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
        0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
        0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
        0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
        0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
        0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    };
    uint32_t rotr(uint32_t x, uint32_t n) {
        return (x >> n) | (x << (32 - n));
    }
    uint32_t ch(uint32_t x, uint32_t y, uint32_t z) {
        return (x & y) ^ (~x & z);
    }
    uint32_t maj(uint32_t x, uint32_t y, uint32_t z) {
        return (x & y) ^ (x & z) ^ (y & z);
    }
    uint32_t sum0(uint32_t x) {
        return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
    }
    uint32_t sum1(uint32_t x) {
        return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
    }
    uint32_t sigma0(uint32_t x) {
        return rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
    }
    uint32_t sigma1(uint32_t x) {
        return rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);
    }
};


void print_usage() {
    std::cout << "Usage: \n";
    std::cout << "  ./kry [OPTIONS]\n";
    std::cout << "\n";
    std::cout << "Description: \n";
    std::cout << "  All outputs are print on STDOUT.\n";
    std::cout << "\n";
    std::cout << "  Available options:\n";
    std::cout << "  -c      Calculate, and print SHA-256 checksum of a message on STDIN.\n";
    std::cout << "  -s      Calculate, and print MAC of a message on STDIN. Requires -k KEY.\n";
    std::cout << "  -v      Verify MAC of a message on STDIN. Requires -k KEY, and -m CHS.\n";
    std::cout << "  -e      Execute length extension attack. Requires -m CHS, -n NUM, -a MSG.\n";
    std::cout << "\n";
    std::cout << "  Additional options:\n";
    std::cout << "  -k KEY  Specify private key for MAC calculation.\n";
    std::cout << "  -m CHS  Specify MAC of an input message.\n";
    std::cout << "  -n NUM  Specify length of private key.\n";
    std::cout << "  -a MSG  Specify length extension of an input message.\n";
}

int main(int argc, char **argv) {
    (void) argv;
    if (argc == 1) {
        print_usage();
        return ERROR_HELP;
    }
    std::string message = "Hello world!";
    MessageBlocks blocks(message);
    blocks.print_block();

    SHA256 sha256;
    sha256.digest(blocks);
    std::string hash_str = sha256.to_string();
    std::cout << "Message:      " << message << std::endl;
    std::cout << "SHA-256 hash: " << hash_str << std::endl;

    return 0;
}

