/*
  FLP: Logical Project: Turing Machine
  Author: Matúš Remeň (xremen01)
  Date: 14.04.2024
*/

% Read, and parse input.
%% Helper functions.
isEOF(Char) :- Char == end_of_file.
isEOL(Char) :- char_code(Char, Code), Code == 10.
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
    (
        isEOF(Line) -> Lines = []
    ;
        read_input(RestLines),
        Lines = [Line|RestLines]
    ).

%% Parse Rules and Tape from the input.
parse_line(Line, rule, rule(State, Symbol, NextState, Action)) :-
    [State, ' ', Symbol, ' ', NextState, ' ', Action] = Line, !.
parse_line(Line, tape, Tape) :- Tape = Line.

parse_input([], [], []).
parse_input([H|T], [ParsedLine|ParsedRules], Tapes) :-
    parse_line(H, rule, ParsedLine),
    parse_input(T, ParsedRules, Tapes).
parse_input([H|_], Rules, Tape) :-
    parse_line(H, tape, Tape), Rules = [].

% Turing machine.
%% Rule matching.
%%% First try to match rule leading to final state.
match_rules(State, Symbol, Rules, MatchedRules) :-
    findall(
        rule(State, Symbol, NextState, Action),
        member(rule(State, Symbol, NextState, Action), Rules),
        MatchedRules
    ).

%% Replace element on the given index.
replace([_|T], 0, X, [X|T]).
replace([H|T], Index, X, [H|NT]) :-
    Index > 0,
    NextIndex is Index - 1,
    replace(T, NextIndex, X, NT).

%% Append blank to the end of the tape if index is out of bounds.
resize_tape(Tape, Index, ResizedTape) :-
    length(Tape, Length),
    (
        Index >= Length -> append(Tape, [' '], ResizedTape)
        ;
        ResizedTape = Tape
    ).

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
    resize_tape(Tape, Index, ResizedTape),
    replace(ResizedTape, Index, NewSymbol, NextTape).

nth0_or_blank(Index, List, Element) :-
    nth0(Index, List, Element), !.
nth0_or_blank(_, _, ' ').

% Simulate Turing machine.
machine_simulate(Tape, _, 'F', Index, Configs, ConfigSequence) :-
    % Final state reached, the sequence of configurations leading to this state
    % becomes the final sequence of configurations (`ConfigSequence`). This will
    % also end the evaluation of other matching rules.
    append(Configs, [(Tape, 'F', Index)], ConfigSequence), !.
machine_simulate(Tape, Rules, State, Index, Configs, ConfigSequence) :-
    % Check if the index is valid.
    Index >= 0,
    nth0_or_blank(Index, Tape, Symbol),
    match_rules(State, Symbol, Rules, MatchedRules),
    % For each matching rule, simulate the machine.
    member(rule(_, _, NextState, Action), MatchedRules),
    apply_rule(Tape, Index, Action, NextTape, NextIndex),
    append(Configs, [(Tape, State, Index)], NewConfigs),
    machine_simulate(NextTape, Rules, NextState, NextIndex, NewConfigs, ConfigSequence).
machine_simulate(_, _, _, Index, _, _) :-
    % Index out of bounds, abnormal halting of the Machine.
    Index < 0, halt(1).

% Print tapes based on the given configuration. Includes the State non-terminal in the output.
print_tape([], State, Index, CurrIndex) :-
    Index == CurrIndex,
    format("~w~w", [State, ' ']), nl, !.
print_tape([], _, _, _) :- nl, !.
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

print_configs([]).
print_configs([(Tape, State, Index)|T]) :-
    print_tape(Tape, State, Index, 0),
    print_configs(T).

% Program entry point.
start :-
    % read and parse input
    read_input(Input),
    parse_input(Input, Rules, Tape),
    % run simulation
    machine_simulate(Tape, Rules, 'S', 0, [], ConfigSequence),
    % print the configurations
    print_configs(ConfigSequence).
