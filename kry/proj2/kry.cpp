/*
 * Description: KRY - Project 2 - MAC Using SHA-256 & Lenght Extension Attack
 * Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
 * Date: 15.04.2024
 */

#include <iostream>
#include <cstdlib>
#include <cstdint>
#include <string>
#include <bitset>

#define ERROR_HELP 1
#define ERROR_ALLOCATION 2

#define BYTE_BITS 8
#define BLOCK_SIZE_UINT32_COUNT 16
#define MESSAGE_LENGTH_BITS 64
#define BLOCK_SIZE 512
#define BLOCK_PRINT_ROW_BITS 32


class MessageBlock {
public:
    MessageBlock(std::string message) {
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
    ~MessageBlock() {
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
private:
    uint64_t size = BLOCK_SIZE;
    uint32_t length = BLOCK_SIZE_UINT32_COUNT;
    uint32_t *data = nullptr;
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
    MessageBlock block(message);
    block.print_block();
    return 0;
}

