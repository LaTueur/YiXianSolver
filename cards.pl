:- module(cards, [card/4, qi_cost/2, card_effects/2, full_card/2]).

card("Normal Attack", 1, 0, [attack(3)]).
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
card("Giant Kun Spirit Sword", 1, 3, [attack(10), defense(10), chase]).
card("Giant Kun Spirit Sword", 2, 3, [attack(13), defense(13), chase]).
card("Egret Spirit Sword", 1, 1, [attack_per_qi(5, 2)]).
card("Spirit Gather Citta-Dharma", 1, 0, [add_qi(1), add_stack(qi_per_two_turns, 1), consume]).
card("Spirit Gather Citta-Dharma", 2, 0, [add_qi(1), add_stack(qi_per_two_turns, 2), consume]).
card("Centibird Spirit Sword Rythm", 2, 0, [add_qi(3), add_stack(reduce_spirit_sword_cost, 1), consume]).


qi_cost(card(_, _, C, _), C).
card_effects(card(_, _, _, D), D).

full_card(card(N, L), card(N, L, _, _)).
