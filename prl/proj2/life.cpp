/*
 * Description: PRL - Project 2 - Game of Life
 * Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
 * Date: 13.04.2024
 *
 * Note from the assignment: Square grids with even number of rows&columns.
 * Note: Grid is not infinite.
 */

#include <fstream>
#include <iostream>
#include <vector>
#include <cstdlib>
#include <mpi.h>

#define MASTER 0
#define IS_MASTER (MASTER == rank)
#define IS_WORKER (MASTER != rank)


std::vector<std::vector<char> > load_board(const int rank, const std::string &filename) {
    std::vector<std::vector<char> > board;
    if (IS_WORKER) {
        return board;
    }

    // Open the file for reading.
    std::ifstream file(filename, std::ios::in);
    if (!file.is_open()) {
        std::cerr << "load_board.error: can't open input file '" << std::endl;
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    // Read the board.
    std::string line;
    while (std::getline(file, line)) {
        std::vector<char> row;
        for (int i = 0; i < line.size(); ++i) {
            // Load the board tiles as binary values.
            row.push_back(line[i] == '1' ? 1 : 0);
        }
        board.push_back(row);
    }
    file.close();
    return board;
}

void broadcast_dimensions(
    const int rank,
    const std::vector<std::vector<char> > &board,
    u_int &row_dim,
    u_int &col_dim
) {
    if (IS_MASTER) {
        row_dim = board.size();
        if (row_dim > 0) {
            col_dim = board[0].size();
        }
    }
    MPI_Bcast(&row_dim, 1, MPI_UNSIGNED, MASTER, MPI_COMM_WORLD);
    MPI_Bcast(&col_dim, 1, MPI_UNSIGNED, MASTER, MPI_COMM_WORLD);
}

void share_board(
    const int rank,
    const int size,
    u_int &row_dim,
    const u_int col_dim,
    std::vector<std::vector<char> > &board
) {
    int rows_per_process = row_dim / size;
    int rows_remainder = row_dim % size;
    int current_rank_rows = rows_per_process;
    if (rank < rows_remainder) {
        // if there is some remainder first 'rows_remainder' processes will get one more row
        current_rank_rows++;
    }

    if (IS_MASTER) {
        // Send the board parts to the workers.
        int next_rank_row = current_rank_rows;
        int recipient_rank = 0;
        int msg_tag = 0;
        for (unsigned int r = current_rank_rows; r < row_dim; ++r) {
            if (r == next_rank_row){
                msg_tag = 0;
                recipient_rank++;
                next_rank_row += rows_per_process + (recipient_rank < rows_remainder ? 1 : 0);
            }
            MPI_Send(board[r].data(), col_dim, MPI_CHAR, recipient_rank, msg_tag, MPI_COMM_WORLD);
            msg_tag++;
        }
        // Truncate the master's board to contain only its tiles.
        board.resize(current_rank_rows);
    } else {
        // Receive the board from the master.
        board.resize(current_rank_rows);
        for (unsigned int r = 0; r < current_rank_rows; ++r) {
            board[r].resize(col_dim);
            MPI_Recv(board[r].data(), col_dim, MPI_CHAR, MASTER, r, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        }
    }
    row_dim = current_rank_rows;
}

void print_board(
    const int rank,
    const int size,
    const u_int row_dim,
    const u_int col_dim,
    const std::vector<std::vector<char> > &board
) {
    for (int current_rank = MASTER; current_rank < size; ++current_rank) {
        if (size > 1) {MPI_Barrier(MPI_COMM_WORLD);}
        if (current_rank == rank) {
            for (int r = 0; r < row_dim; ++r) {
                std::cout << rank << ": ";
                for (int c = 0; c < col_dim; ++c) {
                    std::cout << ((board[r][c] & 0b1) ? "1" : "0");
                }
                std::cout << std::endl;
            }
        }
    }
}

char count_neighbours(
    const std::vector<std::vector<char> > &board,
    const u_int row_dim,
    const u_int col_dim,
    const u_int r,
    const u_int c
) {
    char neighbors = 0;

    int left = c - 1, right = c + 1;
    // Check the 8 neighboring tiles.
    if (c == 0){
        left = col_dim - 1;
        right = c + 1;
    } else if (c == col_dim - 1){
        left = c - 1;
        right = 0;
    }
    neighbors += board[r - 1][left] & 0x01; // Left.
    neighbors += board[r - 1][c] & 0x01; // Top.
    neighbors += board[r - 1][right] & 0x01; // Top right.
    neighbors += board[r][left] & 0x01; // Left.
    neighbors += board[r][right] & 0x01; // Right.
    neighbors += board[r + 1][left] & 0x01; // Bottom left.
    neighbors += board[r + 1][c] & 0x01; // Bottom.
    neighbors += board[r + 1][right] & 0x01; // Bottom right.

    return neighbors;
}

void live(
    const int rank,
    const int size,
    const u_int row_dim,
    const u_int col_dim,
    std::vector<std::vector<char> > &board,
    const u_int iteration
) {
    // Communicate between neighboring processes.
    int prev_rank = IS_MASTER ? size - 1 : rank - 1;
    int next_rank = rank + 1 < size ? rank + 1 : MASTER;

    // Send.
    int message_send_tag = 10000 * iteration + 10 * rank;
    MPI_Send(board[0].data(), col_dim, MPI_CHAR, prev_rank, message_send_tag, MPI_COMM_WORLD);
    MPI_Send(board[row_dim - 1].data(), col_dim, MPI_CHAR, next_rank, message_send_tag + 1, MPI_COMM_WORLD);

    // Receive.
    std::vector<char> prev_row(col_dim);
    std::vector<char> next_row(col_dim);
    int message_tag_prev = 10000 * iteration + 10 * prev_rank;
    int message_tag_next = 10000 * iteration + 10 * next_rank;
    MPI_Recv(prev_row.data(), col_dim, MPI_CHAR, prev_rank, message_tag_prev + 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    MPI_Recv(next_row.data(), col_dim, MPI_CHAR, next_rank, message_tag_next, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

    // Create a temporary board with the neighboring rows.
    std::vector<std::vector<char> > tmp_board = board;
    tmp_board.insert(tmp_board.begin(), prev_row);
    tmp_board.push_back(next_row);

    // Apply rules.
    for (u_int r = 0; r < row_dim; ++r) {
        for (u_int c = 0; c < col_dim; ++c) {
            char neighbors = count_neighbours(tmp_board, row_dim, col_dim, r + 1, c);
            board[r][c] = (board[r][c] & 0x01) | (neighbors << 1);
        }
    }
    for (u_int r = 0; r < row_dim; ++r) {
        for (u_int c = 0; c < col_dim; ++c) {
            char cell = board[r][c];
            if (cell & 0x01) {
                // Alive.
                if ((cell >> 1) < 2 || (cell >> 1 )> 3) {
                    // Die.
                    board[r][c] = 0;
                }
            } else {
                // Dead.
                if ((cell >> 1) == 3) {
                    // Live.
                    board[r][c] = 1;
                }
            }
        }
    }
}


int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);

    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <input_file> <iterations>" << std::endl;
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    u_int iterations = static_cast<u_int>(std::strtol(argv[2], nullptr, 10));

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // Load, and distribute the board.
    std::vector<std::vector<char> > board = load_board(rank, argv[1]);
    u_int row_dim, col_dim;
    broadcast_dimensions(rank, board, row_dim, col_dim);
    share_board(rank, size, row_dim, col_dim, board);

    // Simulate the game of life.
    for (u_int i = 1; i <= iterations; ++i) {
        live(rank, size, row_dim, col_dim, board, i);
    }

    print_board(rank, size, row_dim, col_dim, board);

    MPI_Finalize();
    return 0;
}
