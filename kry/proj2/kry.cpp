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


void calculate_sha256() {
    std::string message;
    int c;
    while ((c=fgetc(stdin)) != EOF) {
        message += (char)c;
    }
    MessageBlocks blocks(message);

    SHA256 sha256;
    sha256.digest(blocks);
    std::cout << sha256.to_string() << std::endl;
}


int main(int argc, char **argv) {
    (void) argv;
    if (argc == 1) {
        print_usage();
        return ERROR_HELP;
    }
    if (argc == 2 && std::string(argv[1]) == "-c") {
        calculate_sha256();
        return 0;
    }

    return 0;
}

