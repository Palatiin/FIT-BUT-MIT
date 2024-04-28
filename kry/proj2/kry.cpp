/*
 * Description: KRY - Project 2 - MAC Using SHA-256 & Lenght Extension Attack
 * Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
 * Date: 15.04.2024
 */

#include <getopt.h>
#include "sha256.hpp"


struct Arguments {
    bool c = false;
    bool s = false;
    bool v = false;
    bool e = false;

    std::string k;
    std::string m;
    std::string a;
    uint64_t n = 0;
};

void print_usage() {
    std::cout << "Usage: \n";
    std::cout << "  ./kry [OPTIONS]\n";
    std::cout << "\n";
    std::cout << "Description: \n";
    std::cout << "  All outputs are printed on STDOUT.\n";
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

int check_args(Arguments args) {
    // Check if only one option is selected.
    if (args.c + args.s + args.v + args.e != 1) {
        std::cerr << "Only one option can be selected." << std::endl;
        return 3;
    }

    // Check if required arguments are present.
    if (args.s && args.k.empty()) {
        std::cerr << "Option -s requires -k KEY." << std::endl;
        return 3;
    }
    if (args.v && (args.k.empty() || args.m.empty())) {
        std::cerr << "Option -v requires -k KEY, and -m CHS." << std::endl;
        return 3;
    }
    if (args.e && (args.m.empty() || args.n <= 0 || args.a.empty())) {
        std::cerr << "Option -e requires -m CHS, -n NUM, and -a MSG." << std::endl;
        return 3;
    }
    if (!(args.m.empty()) && args.m.size() != 64) {
        std::cerr << "Invalid MAC. It must be 64 characters long." << std::endl;
        return 3;
    }

    return 0;
}

std::string read_input() {
    // Read the input message from STDIN.
    std::string message;
    int c;
    while ((c=fgetc(stdin)) != EOF) {
        message += (char)c;
    }
    return message;
}

void calculate_sha256() {
    // Load message, and parse it into blocks.
    std::string message = read_input();
    MessageBlocks blocks(message);

    // Calculate the SHA-256, and print it.
    SHA256 sha256;
    sha256.digest(blocks);
    std::cout << sha256.hexdigest() << std::endl;
}

void calculate_mac(std::string key) {
    // MAC = SHA256(key + message)
    // Load message, and parse it into blocks.
    std::string message = read_input();
    MessageBlocks blocks(key + message);

    // Calculate the MAC, and print it.
    SHA256 sha256;
    sha256.digest(blocks);
    std::cout << sha256.hexdigest() << std::endl;
}

int verify_mac(std::string key, std::string mac) {
    // Load message, and parse it into blocks.
    std::string message = read_input();
    MessageBlocks blocks(key + message);

    // Calculate the MAC, and validate the one from the input.
    SHA256 sha256;
    sha256.digest(blocks);
    std::string calculated_mac = sha256.hexdigest();
    if (calculated_mac == mac) {
        return 0;
    } else {
        return 1;
    }
}

void length_extension_attack(std::string mac, uint64_t n, std::string append) {
    std::string message = read_input();
    // Tmp padding for the secret key, will be skipped in print_content_ext.
    for (uint64_t i = 0; i < n; ++i) {
        message = "0" + message;
    }
    MessageBlocks original_blocks(message);

    // Craft the append blocks.
    MessageBlocks ext_blocks(append);
    ext_blocks.update_length(static_cast<uint64_t>(append.size() * BYTE_BITS) + original_blocks.get_size());

    // Initialize the SHA-256 with the original MAC, and digest appended blocks.
    SHA256 sha256;
    sha256.update_hash(mac);
    sha256.digest(ext_blocks);

    // Print the new MAC, and the crafted message.
    std::cout << sha256.hexdigest() << std::endl;
    original_blocks.print_content_ext(n);
    std::cout << append << std::endl;
}

int main(int argc, char **argv) {
    // Parse, and validate arguments.
    if (argc == 1) {
        print_usage();
        return ERROR_HELP;
    }

    Arguments args;
    int opt;
    while ((opt = getopt(argc, argv, "csvek:m:n:a:")) != -1) {
        switch (opt) {
            case 'c':
                args.c = true;
                break;
            case 's':
                args.s = true;
                break;
            case 'v':
                args.v = true;
                break;
            case 'e':
                args.e = true;
                break;
            case 'k':
                args.k = optarg;
                break;
            case 'm':
                args.m = optarg;
                break;
            case 'n':
                args.n = std::strtoull(optarg, nullptr, 10);
                break;
            case 'a':
                args.a = optarg;
                break;
            default:
                // Invalid option.
                return 3;
        }
    }
    if (check_args(args) != 0) {
        return 3;
    }

    // Perform the selected function.
    if (args.c){
        calculate_sha256();
    } else if (args.s) {
        calculate_mac(args.k);
    } else if (args.v) {
        return verify_mac(args.k, args.m);
    } else if (args.e) {
        length_extension_attack(args.m, args.n, args.a);
    }

    return 0;
}

