:- module(card, [card/4, card_name/2, qi_cost/2, card_effects/2, full_card/2, spirit_sword/1]).

card("Normal Attack", 1, 0, [attack(3)]).
card("Qi Perfusion", 1, 0, [add_qi(2)]).
card("Guard Qi", 3, 0, [add_qi(3), defense(5)]).
card("Transforming Spirits Rhythm", 1, 0, [add_qi(3)]).
card("Transforming Spirits Rhythm", 2, 0, [add_qi(4)]).
card("Spiritage Sword", 1, 0, [add_qi(2), more_qi_than(2, [attack(2), attack(2)])]).
card("Spiritage Sword", 3, 0, [add_qi(4), more_qi_than(4, [attack(2), attack(2)])]).
card("Giant Roc Spirit Sword", 1, 2, [attack(9), more_qi_than(0, [chase])]).
card("Giant Roc Spirit Sword", 2, 2, [attack(12), more_qi_than(0, [chase])]).
card("Giant Tiger Spirit Sword", 1, 1, [attack(10)]).
card("Giant Tiger Spirit Sword", 2, 1, [attack(13)]).
card("Giant Tiger Spirit Sword", 3, 1, [attack(16)]).
card("Giant Whale Spirit Sword", 1, 2, [attack(16)]).
card("Giant Whale Spirit Sword", 2, 2, [attack(20)]).
card("Giant Kun Spirit Sword", 1, 3, [attack(10), defense(10), chase]).
card("Giant Kun Spirit Sword", 2, 3, [attack(13), defense(13), chase]).
card("Egret Spirit Sword", 1, 1, [attack_per_qi(5, 2)]).
card("Egret Spirit Sword", 2, 1, [attack_per_qi(5, 3)]).
card("Spirit Gather Citta-Dharma", 1, 0, [add_qi(1), add_stack(qi_per_two_turns, 1), consume]).
card("Spirit Gather Citta-Dharma", 2, 0, [add_qi(1), add_stack(qi_per_two_turns, 2), consume]).
card("Centibird Spirit Sword Rythm", 2, 0, [add_qi(3), add_stack(reduce_spirit_sword_cost, 1), consume]).
card("Spiritage Elixir", 1, 0, [add_qi(4), consume]).
card("Ice Spirit Guard Elixir", 1, 1, [add_stack(guard_up, 2), consume]).
card("Flying Spirit Shade Sword", 1, 0, Effect) :- length(Effect, 4), maplist(=(injured(1, [add_qi(1)])), Effect).
card("Dharma Spirit Sword", 2, 0, [attack_per_qi(5, 6), exhaust_qi]).
card("Sword Slash", 2, 0, [attack(5), add_stack(sword_intent, 3)]).
card("Sword Defence", 2, 0, [defense(5), add_stack(sword_intent, 3)]).
card("Flying Fang Sword", 1, 1, [injured(8, [add_stack(used_sword_intent, -1)])]).
card("Flying Fang Sword", 2, 1, [injured(11, [add_stack(used_sword_intent, -1)])]).
card("Contemplate Spirits Rythm", 1, 0, [add_qi(1), add_stack(sword_intent, 3)]).
card("Tri-Peak Sword", 1, 0, [attack(3), attack(3), attack(3)]).

card_name(card(A, _, _, _), A).
qi_cost(card(_, _, C, _), C).
card_effects(card(_, _, _, D), D).

full_card(card(N, L), card(N, L, _, _)).

spirit_sword(C) :- card_name(C, N), spirit_sword_name(N).

contains_spirit_sword(N) :- sub_string(N, _, _, _, "Spirit Sword").

:- dynamic spirit_sword_name/1.
:- retractall(spirit_sword_name(_)).
:- findall(X, card(X, _, _, _), Xs),
    list_to_set(Xs, Ys),
    include(contains_spirit_sword, Ys, Zs),
    forall(member(N, Zs), assertz(spirit_sword_name(N)))
.
