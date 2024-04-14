/*
  FLP: Logical Project: Turing Machine
  Author: Matúš Remeň (xremen01)
  Date: 14.04.2024
*/

:- module(turing, [
    isEOF/1,
    isEOL/1,
    isSpace/1,
    read_line/1,
    read_input/1,
    parse_line/3,
    parse_input/3,
    print_tape/4,
    match_rule/4,
    replace/4,
    apply_rule/5,
    machine_simulate/4,
    start/0
]).

% Read, and parse input.
%% Helper functions.
isEOF(Char) :- Char == end_of_file.
isEOL(Char) :- char_code(Char, Code), Code==10.
isSpace(Char) :- char_code(Char, Code), Code == 32.

%% Read per char until `\n` or EOF.
read_line(Line) :-
    get_char(Char),
    (
        isEOF(Char) -> Line = Char
        ;
        isEOL(Char) -> Line = []
        ;
        read_line(RestLine),
        Line = [Char|RestLine]
    ).

%% Read stdin per line.
read_input(Lines) :-
    prompt(_, ''),
    read_line(Line),
    (   isEOF(Line) -> Lines = []
    ;   exclude(isSpace, Line, FilteredLine),  % filter out spaces
        read_input(RestLines),
        Lines = [FilteredLine|RestLines]
    ).

%% Parse Rules and Tape from the input.
parse_line(Line, rule, rule(State, Symbol, NextState, Action)) :-
    [State, Symbol, NextState, Action] = Line, !.
parse_line(Line, tape, Tape) :- Tape = Line.

parse_input([], [], []).
parse_input([H|T], [ParsedLine|ParsedRules], Tapes) :-
    parse_line(H, rule, ParsedLine),
    parse_input(T, ParsedRules, Tapes).
parse_input([H|_], Rules, Tape) :-
    parse_line(H, tape, Tape), Rules = [].

% Turing machine.
print_tape([], _, _, _) :- nl.
print_tape([H | T], State, Index, CurrIndex) :-
    Index == CurrIndex,
    format("~w~w", [State, H]),
    NextIndex is CurrIndex + 1,
    print_tape(T, State, Index, NextIndex).
print_tape([H | T], State, Index, CurrIndex) :-
    Index =\= CurrIndex,
    format("~w", [H]),
    NextIndex is CurrIndex + 1,
    print_tape(T, State, Index, NextIndex).

%% Rule matching.
%%% First try to match rule leading to final state.
match_rule(State, Symbol, Rules, Rule) :-
    member(rule(State, Symbol, 'F', Action), Rules),
    !,
    Rule = rule(State, Symbol, 'F', Action).
%%% Otherwise try to match any other rule, first matched will be used.
match_rule(State, Symbol, Rules, Rule) :-
    member(rule(State, Symbol, NextState, Action), Rules),
    Rule = rule(State, Symbol, NextState, Action).

%% Replace element on the given index.
replace([_|T], 0, X, [X|T]).
replace([H|T], Index, X, [H|NT]) :-
    Index > 0,
    NextIndex is Index - 1,
    replace(T, NextIndex, X, NT).

%% Apply rule.
apply_rule([], _, _, _, _).
apply_rule(Tape, Index, 'R', Tape, NextIndex) :-
    % Rule1 - move right.
    NextIndex is Index + 1, !.
apply_rule(Tape, Index, 'L', Tape, NextIndex) :-
    % Rule2 - move left.
    NextIndex is Index - 1, !.
apply_rule(Tape, Index, NewSymbol, NextTape, Index) :-
    % Rule3 - write symbol under the head of the Turing Machine.
    replace(Tape, Index, NewSymbol, NextTape).

%% Simulate Turing machine.
machine_simulate(Tape, _, 'F', Index) :-
    % Final state reached.
    print_tape(Tape, 'F', Index, 0), !.
machine_simulate(Tape, Rules, State, Index) :-
    % Check if the index is valid.
    Index >= 0,
    print_tape(Tape, State, Index, 0),
    nth0(Index, Tape, Symbol),
    match_rule(State, Symbol, Rules, rule(State, Symbol, NextState, Action)),
    apply_rule(Tape, Index, Action, NextTape, NextIndex),
    machine_simulate(NextTape, Rules, NextState, NextIndex).
machine_simulate(_, _, _, Index) :-
    % Index out of bounds, abnormal halting of the Machine.
    Index < 0, halt.

% Program entry point.
start :-
    % read and parse input
    read_input(Input),
    parse_input(Input, Rules, Tape),
    % run simulation
    machine_simulate(Tape, Rules, 'S', 0).
