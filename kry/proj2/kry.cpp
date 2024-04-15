/*
 * Description: KRY - Project 2 - MAC Using SHA-256 & Lenght Extension Attack
 * Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
 * Date: 15.04.2024
 */

#include "sha256.hpp"


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

