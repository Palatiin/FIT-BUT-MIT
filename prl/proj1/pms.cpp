/*
 * Description: PRL - Project 1 - Pipeline Mergesort
 * Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
 * Date: 06.04.2024
 */

#include <iostream>
#include <vector>
#include <queue>
#include <fstream>
#include <cmath>  // <math.h>

#include <mpi.h>

#define INPUT_FILE "numbers"
#define NUMBER_BYTES 1
#define MASTER 0

#define IS_MASTER (MASTER == rank)
#define IS_WORKER (MASTER != rank)


std::queue<uint8_t> read_input(const int rank){
    if (IS_WORKER){
        return std::queue<uint8_t>();
    }

    // Open the file in binary read mode
    std::ifstream file(INPUT_FILE, std::ios::binary | std::ios::in);
    if (!file.is_open()) {
        std::cerr << "read_input.error: can't open input file" << std::endl;
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    std::queue<uint8_t> bytes;
    while (file) {
        char byte;
        file.read(&byte, NUMBER_BYTES);
        if (file.gcount() > 0) {
            bytes.push(static_cast<uint8_t>(byte));
        }
    }
    file.close();

    return bytes;
}


int broadcast_input_size(const int rank, std::queue<uint8_t> &input_bytes){
    u_long size;

    if (IS_MASTER) {
        size = input_bytes.size();
    }
    // Broadcast input size from master to all other processes
    MPI_Bcast(&size, 1, MPI_UNSIGNED_LONG, MASTER, MPI_COMM_WORLD);

    return static_cast<int>(size);
}


std::vector<uint8_t> pipeline_mergesort(
        const int rank,
        const int comm_size,
        int input_size,
        std::queue<uint8_t> bytes
){
    std::vector<uint8_t> output;
    if (IS_MASTER) {
        // P_0
        uint8_t processed_byte;
        for (int message_tag = 0; message_tag < input_size; ++message_tag) {
            processed_byte = bytes.front();
            std::cout << static_cast<unsigned int>(processed_byte) << " ";
            bytes.pop();
            MPI_Send(&processed_byte, 1, MPI_UINT8_T, rank + 1, message_tag, MPI_COMM_WORLD);
        }
        std::cout << std::endl;
    } else if (IS_WORKER) {
        // P_i (0 <= i < comm_size - 1)
        int q_cycle = (int)pow(2, rank-1);
        bool q_switch = false;
        bool is_last_process = rank == comm_size - 1;
        int fwd_tag = 0;
        int rcv_tag = 0;
        int q1_seq = q_cycle;
        int q2_seq = q_cycle;
        std::vector<std::queue<uint8_t> > queues(2);

        for (int i = 0; i < input_size + q_cycle + 1; ++i) {
            // Receive, and store byte
            if (i < input_size) {
                uint8_t received_byte;
                MPI_Recv(&received_byte, 1, MPI_UINT8_T, rank - 1, rcv_tag, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                rcv_tag++;

                // Store received byte in the queue, and switch queues every cycle
                queues[q_switch].push(received_byte);
                q_switch = ((i + 1) % q_cycle == 0) ? !q_switch : q_switch;
            }

            // Send byte to the next process
            if (i > q_cycle) {
                uint8_t forward_byte;
                size_t q1_size = queues[0].size();
                size_t q2_size = queues[1].size();

                // Select byte to forward
                bool can_use_q1 = q1_seq > 0 && q1_size > 0;
                bool can_use_q2 = q2_seq > 0 && q2_size > 0;
                if (can_use_q1 && !can_use_q2) {
                    forward_byte = queues[0].front();
                    queues[0].pop();
                    q1_seq--;
                } else if (!can_use_q1 && can_use_q2) {
                    forward_byte = queues[1].front();
                    queues[1].pop();
                    q2_seq--;
                } else if (can_use_q1 && can_use_q2) {
                    if (queues[0].front() >= queues[1].front()) {
                        forward_byte = queues[0].front();
                        queues[0].pop();
                        q1_seq--;
                    } else {
                        forward_byte = queues[1].front();
                        queues[1].pop();
                        q2_seq--;
                    }
                }

                if (q1_seq == 0 && q2_seq == 0) {
                    q1_seq = q_cycle;
                    q2_seq = q_cycle;
                }

                if (!is_last_process) {
                    // Send byte to the next process
                    MPI_Send(&forward_byte, 1, MPI_UINT8_T, rank + 1, fwd_tag, MPI_COMM_WORLD);
                } else {
                    // Store byte in the output queue
                    output.insert(output.begin(), forward_byte);
                }
                fwd_tag++;
            }
        }
    }

    return output;
}


int main(int argc, char **argv){
    // Initialize execution environment, and
    MPI_Init(&argc, &argv);
    int rank, comm_size;

    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &comm_size);

    // Read input file (only in master process / P_0)
    std::queue<uint8_t> input_bytes = read_input(rank);

    // Broadcast input size, and initialize input queues in worker processes
    int input_size = broadcast_input_size(rank, input_bytes);

    // Sort input numbers using pipeline mergesort
    std::vector<uint8_t> sorted_bytes = pipeline_mergesort(rank, comm_size, input_size, input_bytes);

    if (rank == comm_size - 1){
        for (u_long i = 0; i < sorted_bytes.size(); ++i) {
            std::cout << static_cast<unsigned int>(sorted_bytes[i]) << std::endl;
        }
    }

    MPI_Finalize();
    return 0;
}