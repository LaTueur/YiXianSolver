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

card("Normal Attack", 1, 0, [attack(3)]).
card("Not Enough Qi", 1, 0, [add_qi(1)]).
card("Qi Perfusion", 1, 0, [add_qi(2)]).
card("Transforming", 1, 0, [add_qi(3)]).
card("Spiritage Sword", 1, 0, [add_qi(2), more_qi_than(2, [attack(2), attack(2)])]).
card("Giant Roc Spirit Sword", 1, 2, [attack(9), more_qi_than(0, [chase])]).
card("Giant Roc Spirit Sword", 2, 2, [attack(12), more_qi_than(0, [chase])]).
card("Giant Tiger Spirit Sword", 1, 1, [attack(10)]).
card("Giant Tiger Spirit Sword", 2, 1, [attack(13)]).
card("Giant Tiger Spirit Sword", 3, 1, [attack(16)]).
card("Giant Whale Spirit Sword", 1, 2, [attack(16)]).
card("Giant Whale Spirit Sword", 2, 2, [attack(20)]).

qi_cost(card(_, _, C, _), C).
card_effects(card(_, _, _, D), D).

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
    resolve_effects(E, M, MM, SC),
    resolve_effect(skip, MM, MA, _)
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

enemy(player(
    "Practice Puppet",
    35,
    58,
    58,
    0,
    [],
    0,
    [
        card("Transforming", 1, _, _),
        card("Qi Perfusion", 1, _, _),
        card("Giant Roc Spirit Sword", 1, _, _),
        card("Giant Whale Spirit Sword", 1, _, _),
        card("Giant Tiger Spirit Sword", 3, _, _),
        card("Giant Tiger Spirit Sword", 1, _, _),
        card("Giant Tiger Spirit Sword", 1, _, _),
        card("Normal Attack", 1, _, _)
    ]
)).
challenger(player(
    "LajosTueur",
    21,
    52,
    52,
    0,
    [],
    0,
    [
    ]
)).

hand([
    card("Transforming", 1, _, _),
    card("Giant Tiger Spirit Sword", 2, _, _),
    card("Spiritage Sword", 1, _, _),
    card("Giant Whale Spirit Sword", 2, _, _),
    card("Giant Roc Spirit Sword", 2, _, _)
]).

run(match(A, B), B) :-
    hp(A, HP),
    HP =< 0, !
.
run(match(A, B), A) :-
    hp(B, HP),
    HP =< 0, !
.
run(match(A, B), W) :-
    next_card(A, Next),
    board(A, Board),
    nth0(Next, Board, Card),
    Card,
    player_name(A, Name),
    %writeln(Name),
    %writeln(Card),
    subtract_cost(A, Card, ASub) -> (
        resolve_card_effects(Card, match(ASub, B), match(AAfter, BAfter), ShouldChase),
        (ShouldChase -> run(match(AAfter, BAfter), W)
        ; run(match(BAfter, AAfter), W))
    )
    ; (resolve_effect(add_qi(1), match(A, B), match(AAfter, BAfter), _),
      run(match(BAfter, AAfter), W))
.

winner(W) :- enemy(E), challenger(C), run(match(E,C), W).

build_board(_, [], 8) :- !.
build_board(Hand, [B|Board], C) :-
    select(B, Hand, RestHand),
    CNext is C + 1,
    build_board(RestHand, Board, CNext)
.
build_board(Hand, [card("Normal Attack", 1, _, _)|Board], C) :-
    CNext is C + 1,
    build_board(Hand, Board, CNext)
.

winning_board(B) :-
    enemy(E), challenger(C), hand(H),
    build_board(H, B, 0),
    change_board(C, B, CTest),
    run(match(E, CTest), W),
    player_name(C, Name),
    player_name(W, Name)
.