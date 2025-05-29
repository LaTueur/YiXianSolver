:- use_module(cards).
:- use_module(riddles).

player_name(player(A, _, _, _, _, _, _, _), A).
cultivation(player(_, B, _, _, _, _, _, _), B).
hp(player(_, _, C, _, _, _, _, _), C).
max_hp(player(_, _, _, D, _, _, _, _), D).
qi(player(_, _, _, _, E, _, _, _), E).
effects(player(_, _, _, _, _, F, _, _), F).
next_card(player(_, _, _, _, _, _, G, _), G).
board(player(_, _, _, _, _, _, _, H), H).

change_hp(player(A, B, _, D, E, F, G, H), C, player(A, B, C, D, E, F, G, H)).
change_qi(player(A, B, C, D, _, F, G, H), E, player(A, B, C, D, E, F, G, H)).
change_next_card(player(A, B, C, D, E, F, _, H), G, player(A, B, C, D, E, F, G, H)).
change_board(player(A, B, C, D, E, F, G, _), H, player(A, B, C, D, E, F, G, H)).

subtract_cost(P, C, P) :- qi_cost(C, 0).
subtract_cost(P, C, NP) :- 
    qi(P, Q),
    qi_cost(C, QC),
    Q >= QC,
    NQ is Q - QC,
    change_qi(P, NQ, NP)
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
    hp(B, HP),
    HPAfter is HP - X,
    change_hp(B, HPAfter, BAfter)
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
resolve_effect(skip, match(A, B), match(AAfter, B), false) :-
    next_card(A, N),
    NAfter is N + 1,
    change_next_card(A, NAfter, AAfter)
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
    subtract_cost(A, Card, ASub) -> (
        resolve_card_effects(Card, match(ASub, B), MatchMid, ShouldChase),
        resolve_effect(skip, MatchMid, MatchAfter, _)
    )
    ; resolve_effect(add_qi(1), match(A, B), MatchAfter, ShouldChase)
.

begining_of_turn_effects(Match, Match).
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

fill_cards(A, AF) :-
    board(A, B),
    maplist(full_card, B, BF),
    change_board(A, BF, AF)
.

run(match(A, B), W) :-
    cultivation(A, AC),
    cultivation(B, BC),
    fill_cards(A, AF),
    fill_cards(B, BF),
    (AC > BC -> Match = match(AF, BF) ; Match = match(BF, AF)),
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
    true,
    build_board(H, B, 0),
    change_board(C, B, CTest),
    run(match(E, CTest), W),
    player_name(C, Name),
    player_name(W, Name)
.