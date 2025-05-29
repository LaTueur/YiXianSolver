:- use_module(card).
:- use_module(riddle).

player_name(player(N, _, _, _), N).
cultivation(player(_, num_values(Cul, _, _, _, _), _, _), Cul).
hp(player(_, num_values(_, Hp, _, _, _), _, _), Hp).
max_hp(player(_, num_values(_, _, MHp, _, _), _, _), MHp).
qi(player(_, num_values(_, _, _, Qi, _), _, _), Qi).
defense(player(_, num_values(_, _, _, _, Def), _, _), Def).
statuses(player(_, _, Stat, _), Stat).
next_card(player(_, _, _, board_infos(Next, _, _)), Next).
board(player(_, _, _ , board_infos(_, Board, _)), Board).
slots_consumed(player(_, _, _ , board_infos(_, _, Cons)), Cons).

change_hp(player(N, num_values(Cul, _, MHp, Qi, Def), Stat, Board), Hp, player(N, num_values(Cul, Hp, MHp, Qi, Def), Stat, Board)).
change_qi(player(N, num_values(Cul, Hp, MHp, _, Def), Stat, Board), Qi, player(N, num_values(Cul, Hp, MHp, Qi, Def), Stat, Board)).
change_def(player(N, num_values(Cul, Hp, MHp, Qi, _), Stat, Board), Def, player(N, num_values(Cul, Hp, MHp, Qi, Def), Stat, Board)).
change_statuses(player(N, Val, _, Board), Stat, player(N, Val, Stat, Board)).
change_next_card(player(N, Val, Stat, board_infos(_, Board, Cons)), Next, player(N, Val, Stat, board_infos(Next, Board, Cons))).
change_board(player(N, Val, Stat, board_infos(Next, _, Cons)), Board, player(N, Val, Stat, board_infos(Next, Board, Cons))).
change_slots_consumed(player(N, Val, Stat, board_infos(Next, Board, _)), Cons, player(N, Val, Stat, board_infos(Next, Board, Cons))).

starting_state(player(N, num_values(Cul, _, MHp, _, _), _, board_infos(_, Board, _)), player(N, num_values(Cul, MHp, MHp, 0, 0), [], board_infos(0, BoardFull, Cons))) :-
    maplist(full_card, Board, BoardFull),
    length(Cons, 8),
    maplist(=(false), Cons)
.

subtract_cost(P, C, P) :- qi_cost(C, 0).
subtract_cost(P, C, NP) :- 
    qi(P, Q),
    qi_cost(C, QC),
    (stack_count(P, reduce_spirit_sword_cost, X),
        card_name(C, N),
        sub_string(N, _, _, _, "Spirit Sword")
    -> RC is QC - X
    ; RC = QC),
    Q >= RC,
    NQ is Q - RC,
    change_qi(P, NQ, NP)
.

increase_stack([], X, [X]).
increase_stack([stack(X, Y)|Ys], stack(X, N), [stack(X, Z)|Ys]) :-
    Z is Y + N, !
.
increase_stack([Y|Ys], X, [Y|Zs]) :- increase_stack(Ys, X, Zs).

stack_count(P, X, N) :- statuses(P, Stat), list_stack_count(Stat, X, N).

list_stack_count([stack(X, N)|_], X, N) :- !.
list_stack_count([_|Cs], X, N) :- list_stack_count(Cs, X, N).

slot_consumed(S, A) :-
    slots_consumed(A, Slots),
    nth0(S, Slots, Consumed),
    Consumed
.

resolve_card_effects(Card, M, MA, SC) :-
    card_effects(Card, E),
    resolve_effects(E, M, MA, SC)
.

resolve_effects([], match(A, B), match(A, B), false).
resolve_effects([E|Es], match(A, B), match(AAfter, BAfter), ShouldChase) :-
    resolve_effect(E, match(A, B), match(AMid, BMid), ShouldChaseMid),
    resolve_effects(Es, match(AMid, BMid), match(AAfter, BAfter), ShouldChaseEnd),
    ShouldChase = ((ShouldChaseMid ; ShouldChaseEnd), !)
.

resolve_effect(attack(X), match(A, B), match(A, BAfter), false) :-
    hp(B, Hp),
    defense(B, Def),
    XHp is max(X - Def, 0),
    DefAfter is max(Def - X, 0),
    change_def(B, DefAfter, BMid),
    (XHp > 0, stack_count(BMid, guard_up, G), G > 0 ->
        resolve_effect(add_stack(guard_up, -1), match(BMid, A), match(BAfter, A), _)
    ;
    HpAfter is Hp - XHp,
    change_hp(BMid, HpAfter, BAfter))
.
resolve_effect(defense(X), match(A, B), match(AAfter, B), false) :-
    defense(A, Def),
    DefAfter is Def + X,
    change_def(A, DefAfter, AAfter)
.
resolve_effect(attack_per_qi(X, S), match(A, B), MatchAfter, ShouldChase) :-
    qi(A, Qi),
    T is X + S * Qi,
    resolve_effect(attack(T), match(A, B), MatchAfter, ShouldChase)
.
resolve_effect(injured(X, Es), match(A,B), MatchAfter, ShouldChase) :-
    hp(B, Hp),
    resolve_effect(attack(X), match(A,B), match(AMid,BMid), _),
    hp(BMid, HpAfter),
    (Hp > HpAfter -> resolve_effects(Es, match(AMid, BMid), MatchAfter, ShouldChase)
    ; MatchAfter = match(AMid, BMid), ShouldChase = false)
.
resolve_effect(add_qi(X), match(A, B), match(AAfter, B), false) :-
    qi(A, Q),
    QAfter is Q + X,
    change_qi(A, QAfter, AAfter)
.
resolve_effect(chase, match(A, B), match(A, B), true).
resolve_effect(more_qi_than(X, Es), match(A, B), match(AAfter, BAfter), ShouldChase) :-
    qi(A, Q),
    Q > X -> resolve_effects(Es, match(A, B), match(AAfter, BAfter), ShouldChase)
    ; AAfter = A, BAfter = B, ShouldChase = false
.
resolve_effect(add_stack(X, N), match(A, B), match(AAfter, B), false) :-
    statuses(A, Stat),
    increase_stack(Stat, stack(X, N), StatAfter),
    change_statuses(A, StatAfter, AAfter)
.
resolve_effect(consume, match(A, B), match(AAfter, B), false) :-
    next_card(A, N),
    slots_consumed(A, Cons),
    nth0(N, Cons, _, Rest),
    nth0(N, ConsAfter, true, Rest),
    change_slots_consumed(A, ConsAfter, AAfter)
.
resolve_effect(exhaust_qi, match(A, B), match(AAfter, B), false) :-
    change_qi(A, 0, AAfter)
.
resolve_effect(skip, match(A, B), match(AAfter, B), false) :-
    next_card(A, N),
    NAfter is (N + 1) mod 8,
    change_next_card(A, NAfter, AMid),
    (slot_consumed(NAfter, A) -> resolve_effect(skip, match(AMid, B), match(AAfter, B), false) ; AAfter = AMid)
.
resolve_effect(halve_defense, match(A, B), match(AAfter, B), false) :-
    defense(A, Def),
    DefAfter is Def div 2,
    change_def(A, DefAfter, AAfter)
.
resolve_effect(add_qi_per_turns, match(A, B), match(AAfter, B), false) :-
    stack_count(A, qi_per_two_turns, X) ->
    (stack_count(A, half_qi, Y) -> true ; Y = 0 ),
    T is X + Y,
    Add is T div 2,
    Left is T mod 2,
    Change is Left - Y,
    resolve_effect(add_qi(Add), match(A, B), match(AMid, B), _),
    resolve_effect(add_stack(half_qi, Change), match(AMid, B), match(AAfter, B), _)
    ; AAfter = A
.

has_winner(match(A, B), B) :-
    hp(A, HP),
    HP =< 0, !
.
has_winner(match(A, B), A) :-
    hp(B, HP),
    HP =< 0, !
.

play_card(match(A, B), MatchAfter, ShouldChase) :-
    next_card(A, Next),
    board(A, Board),
    nth0(Next, Board, Card),
    Card,
    (subtract_cost(A, Card, ASub) -> (
        resolve_card_effects(Card, match(ASub, B), MatchMid, ShouldChase),
        resolve_effect(skip, MatchMid, MatchAfter, _)
    )
    ; resolve_effect(add_qi(1), match(A, B), MatchAfter, ShouldChase))
.

begining_of_turn_effects(Match, MatchAfter) :-
    resolve_effects([halve_defense, add_qi_per_turns], Match, MatchAfter, _)
.
end_of_turn_effects(Match, Match).

turn_part(_, Match, W) :- has_winner(Match, W), !.
turn_part(begining, Match, W) :-
    begining_of_turn_effects(Match, MatchAfter),
    turn_part(first_card, MatchAfter, W)
.
turn_part(first_card, Match, W) :-
    play_card(Match, MatchAfter, ShouldChase),
    (ShouldChase -> NextPhase = second_card; NextPhase = end),
    turn_part(NextPhase, MatchAfter, W)
.
turn_part(second_card, Match, W) :-
    play_card(Match, MatchAfter, _),
    turn_part(end, MatchAfter, W)
.
turn_part(end, Match, W) :- 
    end_of_turn_effects(Match, match(A, B)),
    turn_part(begining, match(B, A), W)
.

run(match(A, B), W) :-
    cultivation(A, AC),
    cultivation(B, BC),
    starting_state(A, AS),
    starting_state(B, BS),
    (AC > BC -> Match = match(AS, BS) ; Match = match(BS, AS)),
    turn_part(begining, Match, W)
.

build_board(_, [], 8) :- !.
build_board(Hand, [B|Board], C) :-
    select(B, Hand, RestHand),
    CNext is C + 1,
    build_board(RestHand, Board, CNext)
.
build_board(Hand, [card("Normal Attack", 1)|Board], C) :-
    CNext is C + 1,
    build_board(Hand, Board, CNext)
.

winning_board(R, B) :-
    riddle(R, C, H, E),
    build_board(H, B, 0),
    change_board(C, B, CTest),
    run(match(E, CTest), W),
    player_name(C, Name),
    player_name(W, Name)
.