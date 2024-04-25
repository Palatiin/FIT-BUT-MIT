# FLP 2024 - Logical Project - Turing Machine

---
**Author:** Matúš Remeň (xremen01)\
**Academic year:** 2023/2024\
**Assignment:** Turing Machine
---

## Method
Firstly, the program reads the input and parses it into a list of rules, and identifies the input tape. The tape is
represented as a list of symbols (`a-z`, ` ` - blank). Rule is a structure `rule(State, Symbol, NewState, Action)`,
where `State` is the source state, `Sybmol` is the symbol on the tape, where the read/write head is, `NewState` is
the target state, and `Action` represents either movement of the head (`L` - left, `R` - right) or rewriting the
symbol under the head (`a-z`, ` `).

The predicate `machine_simulate/6` starts the simulation of the Turing machine. Its arguments are the tape,
the list of rules, current state, current position of the R/W head, current sequence of configurations, and
the final sequence of configurations. The final sequence of configurations is set and returned when the machine
halts - reaches the final state `F`. A configuration is a tuple `(Tape, State, Index)`.

Finally, if the machine halts, the program prints the sequence of configurations. If the machine halts abnormally,
the program returns code `1`, otherwise `0`. If it does not halt, the program does not halt either (halting problem).

Flow:
1. Read, and parse input - rules and tape.
2. Start the simulation of the Turing machine.
   1. Check if current state is the final state `F`, if yes, append the last configuration, and return the
   sequence of configurations.
   2. Otherwise, validate the bounds of the current index (>= 0).
   3. Fetch the current symbol under the head.
   4. Find rules matching the conditions.
   5. Apply a matching rule, and append the last configuration to the sequence of configurations.
   6. Recursively simulate the next step.
3. Print the final sequence of configurations, if it exists and the machine halts.

## Usage
- Compilation: `make` - creates executable `flp23-log`

After a successful compilation:
- Example run: `./flp23-log < tests/test1.in` - runs the program on the example from the assignment, prints result to the `STDOUT`
- Run on arbitrary input: `./flp23-log [< INFILE] [> OUTFILE]`
- Run student tests: `./test.sh` - runs the program on `tests/*.in` files and compares the output with `tests/*.out` files, prints results
- Cleanup: `make clean` - removes the executable


- Alternative tests run: `make test` - compiles the program (if needed), and runs `./test.sh`

## Extensions
None.

## Limitations
- Halting problem... Program can end up cycling forever.

## Directory contents
- `README.md` - documentation, usage
- `turing.pl` - source code of the assignment
- `tests/` - directory with test inputs and outputs
    - `*.in` - example input files (`test1.in` is the example from the assignment)
    - `*.out` - example output files to the corresponding input files (`test1.out` - from assignment)
- `test.sh` - script for running the program on all test inputs and comparing the outputs with the expected output
- `Makefile` - makefile for compilation of the source code, running tests, packing the project, and for cleanup
