/*
 * Description: PRL - Project 1 - Pipeline Mergesort
 * Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
 * Date: 07.04.2024
 */

#include <iostream>
#include <vector>
#include <deque>
#include <fstream>
#include <cmath>  // <math.h>

#include <mpi.h>

#define INPUT_FILE "numbers"
#define NUMBER_BYTES 1
#define MASTER 0

#define IS_MASTER (MASTER == rank)
#define IS_WORKER (MASTER != rank)
#define IS_LAST (comm_size - 1 == rank)


class Process {
public:
    Process(){
        MPI_Comm_rank(MPI_COMM_WORLD, &rank);
        MPI_Comm_size(MPI_COMM_WORLD, &comm_size);
    }

    std::deque<uint8_t> read_input(){
        std::deque<uint8_t> bytes;
        if (IS_WORKER){
            return bytes;
        }

        // Open the file in binary read mode.
        std::ifstream file(INPUT_FILE, std::ios::binary | std::ios::in);
        if (!file.is_open()) {
            std::cerr << "read_input.error: can't open input file" << std::endl;
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        // Read bytes.
        while (file) {
            char byte;
            file.read(&byte, NUMBER_BYTES);
            if (file.gcount() > 0) {  // to detect EOF
                bytes.push_back(static_cast<uint8_t>(byte));
            }
        }
        file.close();
        return bytes;
    }

    void broadcast_input_size(std::deque<uint8_t> &input_bytes){
        if (IS_MASTER){
            input_size = static_cast<int>(input_bytes.size());
        }
        // Broadcast input size from master to all other processes.
        MPI_Bcast(&input_size, 1, MPI_INT, MASTER, MPI_COMM_WORLD);
    }

    std::deque<uint8_t> pipeline_mergesort(std::deque<uint8_t> &bytes){
        std::deque<uint8_t> output;
        if (input_size == 1){
            return bytes;
        }

        if (IS_MASTER){
            master_pms(bytes);
        } else {
            output = worker_pms();
        }
        return output;
    }

    void master_pms(std::deque<uint8_t> &bytes){
        uint8_t processed_byte;
        for (int message_tag = 0; message_tag < input_size; ++message_tag) {
            processed_byte = bytes.front();
            std::cout << static_cast<unsigned int>(processed_byte) << " ";
            bytes.pop_front();
            MPI_Send(&processed_byte, 1, MPI_UINT8_T, rank + 1, message_tag, MPI_COMM_WORLD);
        }
        std::cout << std::endl;
    }

    std::deque<uint8_t> worker_pms(){
        std::deque<uint8_t> sorted_bytes;
        std::vector<std::deque<uint8_t> > queues(2);
        int q_cycle = (int)pow(2, rank-1);
        bool q_switch = false;
        int q1_window = q_cycle;
        int q2_window = q_cycle;

        // Process input bytes, and send bytes to the next process.
        for (int i = 0; i <= input_size + q_cycle; ++i){
            worker_receiver(i, q_cycle, q_switch, queues);

            if (i > q_cycle) {
                uint8_t forward_byte = worker_processor(q_cycle, q1_window, q2_window, queues);

                if (!IS_LAST) {
                    // Send byte to the next process.
                    MPI_Send(&forward_byte, 1, MPI_UINT8_T, rank + 1, i - q_cycle - 1, MPI_COMM_WORLD);
                } else {
                    // Store byte at the front of the output queue.
                    sorted_bytes.push_front(forward_byte);
                }
            }
        }

        return sorted_bytes;
    }

    void worker_receiver(
        int i, int q_cycle, bool &q_switch, std::vector<std::deque<uint8_t> > &queues
    ){
        if (i >= input_size){
            // If all bytes are received, return.
            return;
        }
        // Receive, and store byte to the queue according to the queue cycle.
        // Queue cycle defines how many bytes are stored in the queue before switching to the other queue.
        uint8_t received_byte;
        MPI_Recv(&received_byte, 1, MPI_UINT8_T, rank - 1, i, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        // Store received byte at the end of the queue, and switch queues every cycle.
        queues[q_switch].push_back(received_byte);
        q_switch = ((i + 1) % q_cycle == 0) ? !q_switch : q_switch;
    }

    uint8_t worker_processor(int q_cycle, int &q1_window, int &q2_window, std::vector<std::deque<uint8_t> > &queues){
        uint8_t forward_byte;
        size_t q1_size = queues[0].size();
        size_t q2_size = queues[1].size();

        // Consider current subsequence, and select byte to forward.
        bool can_use_q1 = q1_window > 0 && q1_size > 0;
        bool can_use_q2 = q2_window > 0 && q2_size > 0;

        if (can_use_q1 && !can_use_q2) {
            forward_byte = queues[0].front();
            queues[0].pop_front();
            q1_window--;
        } else if (!can_use_q1 && can_use_q2) {
            forward_byte = queues[1].front();
            queues[1].pop_front();
            q2_window--;
        } else {
            // Select the byte from the front of the queue with the higher value.
            if (queues[0].front() >= queues[1].front()) {
                forward_byte = queues[0].front();
                queues[0].pop_front();
                q1_window--;
            } else {
                forward_byte = queues[1].front();
                queues[1].pop_front();
                q2_window--;
            }
        }

        // Reinitialize queue select sequences/windows if all values from both were forwarded.
        if (q1_window == 0 && q2_window == 0) {
            q1_window = q_cycle;
            q2_window = q_cycle;
        }
        return forward_byte;
    }

    void print_sorted_bytes(std::deque<uint8_t> &sorted_bytes){
        if (IS_LAST && input_size != 1){
            for (; !sorted_bytes.empty(); sorted_bytes.pop_front()) {
                std::cout << static_cast<unsigned int>(sorted_bytes.front()) << std::endl;
            }
        } else if (input_size == 1 && IS_MASTER) {
            std::cout << static_cast<unsigned int>(sorted_bytes.front()) << std::endl;  // as input
            std::cout << static_cast<unsigned int>(sorted_bytes.front()) << std::endl;  // as output
        }
    }
private:
    int rank;
    int comm_size;
    int input_size;
};


int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);

    Process process;
    std::deque<uint8_t> input_bytes = process.read_input();
    process.broadcast_input_size(input_bytes);

	if (input_bytes.size() == 1){
        process.print_sorted_bytes(input_bytes);
        MPI_Finalize();
        return 0;
    }

    std::deque<uint8_t> sorted_bytes = process.pipeline_mergesort(input_bytes);
    process.print_sorted_bytes(sorted_bytes);

    MPI_Finalize();
    return 0;
}
