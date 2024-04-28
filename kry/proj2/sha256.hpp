/*
 * KRY - Project 2 - MAC Using SHA-256 & Lenght Extension Attack
 * Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
 * Date: 15.04.2024
 * Description: Header file of the SHA-256 hash algorithm, and the MessageBlocks class.
 */

#ifndef KRY_SHA256_H
#define KRY_SHA256_H

#include <cstdlib>
#include <cstdint>
#include <iostream>
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
    // It accepts string messages, and does preprocessing required by SHA-256
    // - padding.
    friend class SHA256;
public:
    MessageBlocks(std::string message);
    ~MessageBlocks();

    void update_length(uint64_t new_size);
    void print_content_ext(uint64_t left_padding_length);
    void print_blocks();

    uint64_t get_size() { return size; }

protected:
    uint64_t size = BLOCK_SIZE;
    uint32_t length = BLOCK_SIZE_UINT32_COUNT;
    uint32_t *data = nullptr;
};


class SHA256 {
    // https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf
public:
    SHA256();
    ~SHA256();

    void update_hash(std::string hash);
    void digest(MessageBlocks &blocks);
    std::string hexdigest();

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

    // SHA256 functions.
    uint32_t rotr(uint32_t x, uint32_t n);
    uint32_t ch(uint32_t x, uint32_t y, uint32_t z);
    uint32_t maj(uint32_t x, uint32_t y, uint32_t z);
    uint32_t sum0(uint32_t x);
    uint32_t sum1(uint32_t x);
    uint32_t sigma0(uint32_t x);
    uint32_t sigma1(uint32_t x);
};

#endif
