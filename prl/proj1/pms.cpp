/*
 * Description: PRL - Project 1 - Pipeline Mergesort
 * Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
 * Date: 07.04.2024
 *
 * Additional note: The algorithm can process input of any size. It's bound only
 * by the OS's maximum number of assignable processes in the MPI environment.
 * The bound was 2048 on the school server merlin - 2049 failed.
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
    // Class for the processes of the parallel pipeline mergesort.
public:
    Process(){
        // Get rank and comm_size ~ make the process recognize itself.
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
        // Get input size from the master/p0 process.
        if (IS_MASTER){
            input_size = static_cast<int>(input_bytes.size());
        }
        // Broadcast input size from master to all other processes.
        MPI_Bcast(&input_size, 1, MPI_INT, MASTER, MPI_COMM_WORLD);
    }

    std::deque<uint8_t> pipeline_mergesort(std::deque<uint8_t> &bytes){
        // Skeleton for multiprocess pipeline mergesort, which distinguishes
        // between master and worker processes.
        std::deque<uint8_t> output;
        if (input_size == 1){
            // There is nothing to sort if there is only one byte.
            std::cout << static_cast<unsigned int>(bytes.front()) << std::endl;
            return bytes;
        }

        if (IS_MASTER){
            // 0th process code.
            master_pms(bytes);
        } else {
            // Worker processes code.
            output = worker_pms();
        }
        return output;
    }

    void master_pms(std::deque<uint8_t> &bytes){
        // 0th/master process prints input bytes, and sends them to the next (worker) process.
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
        // Worker processes receive bytes, store them in queues, and forward them to the next process.
        // The minimum number of received bytes for a worker to start processing/sorting/forwarding
        // is equal to 2^(rank-1) + 1 bytes. The number 2^(rank-1) refers to a "queue cycle", which
        // defines how many bytes are stored in the queue before switching to the other queue.
        // The "+1" refers to the first byte, which is received and stored in the second queue, which
        // is required by the definition of the Pipeline MergeSort. The "queue cycle" refers also
        // to the length of sorted subsequences in each queue, which are then merge sorted and forwarded
        // to the next process. The merge sorting works in cycles, which requires to store the remaining
        // length of subsequence in each queue. These are stored in "qN_window" variables. Once subsequences
        // are forwarded (merged), the "qN_window" is reinitialized ~~ moved to the next subsequences,
        // on which the algorithm repeats. The algorithm forwards the byte with the higher value from
        // the front of the queues within the current subsequence.

        std::deque<uint8_t> sorted_bytes;  // output queue - used only by the last process
        std::vector<std::deque<uint8_t> > queues(2);  // process's queues, where received bytes are stored
        int q_cycle = (int)pow(2, rank-1);  // queue cycle, and also length of subsequences
        bool q_switch = false;  // switcher pointing to the currently filled queue
        // Remaining length of subsequences in each queue.
        int q1_window = q_cycle;
        int q2_window = q_cycle;

        // Process input bytes, select, and send bytes to the next process.
        for (int i = 0; i <= input_size + q_cycle; ++i){
            // Receive, and store byte from the previous process.
            worker_receiver(i, q_cycle, q_switch, queues);

            // Select, and send byte to the next process once the condition is met. The condition
            // defines the minimum number of received bytes - which will result in queue 1 containing
            // 2^(rank-1) bytes, and queue 2 containing one byte.
            if (i > q_cycle) {
                // Select byte.
                uint8_t forward_byte = worker_processor(q_cycle, q1_window, q2_window, queues);

                if (!IS_LAST) {
                    // Send byte to the next process.
                    MPI_Send(&forward_byte, 1, MPI_UINT8_T, rank + 1, i - q_cycle - 1, MPI_COMM_WORLD);
                } else {
                    // The last process stores bytes in the output queue.
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

        // Consider the remaining length of the subsequences, and select byte to forward.
        bool can_use_q1 = q1_window > 0 && q1_size > 0;
        bool can_use_q2 = q2_window > 0 && q2_size > 0;

        if (can_use_q1 && !can_use_q2) {
            // Q2 can not be used, because its either empty, or all bytes from the current
            // subsequence were already selected, and forwarded.
            forward_byte = queues[0].front();
            queues[0].pop_front();
            q1_window--;
        } else if (!can_use_q1 && can_use_q2) {
            // Q1 can not be used, because ^.
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

        // Reinitialize queue select subsequences/windows if all values from both were forwarded.
        if (q1_window == 0 && q2_window == 0) {
            q1_window = q_cycle;
            q2_window = q_cycle;
        }
        return forward_byte;
    }

    void print_sorted_bytes(std::deque<uint8_t> &sorted_bytes){
        if (IS_LAST){
            for (; !sorted_bytes.empty(); sorted_bytes.pop_front()) {
                std::cout << static_cast<unsigned int>(sorted_bytes.front()) << std::endl;
            }
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

    std::deque<uint8_t> sorted_bytes = process.pipeline_mergesort(input_bytes);
    process.print_sorted_bytes(sorted_bytes);

    MPI_Finalize();
    return 0;
}
