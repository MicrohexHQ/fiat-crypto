Require Import Coq.micromega.Lia.
Require Import Coq.ZArith.ZArith.
Require Import Coq.Classes.Morphisms.
Require Import Coq.Classes.RelationPairs.
Require Import Coq.Relations.Relations.
Require Import Crypto.Util.ZRange.
Require Import Crypto.Util.ZRange.Operations.
Require Import Crypto.Util.ZRange.BasicLemmas.
Require Import Crypto.Util.ZRange.SplitBounds.
Require Import Crypto.Util.ZRange.CornersMonotoneBounds.
Require Import Crypto.Util.ZRange.LandLorBounds.
Require Import Crypto.Util.Sum.
Require Import Crypto.Util.LetIn.
Require Import Crypto.Util.Prod.
Require Import Crypto.Util.Sigma.
Require Import Crypto.Util.Option.
Require Import Crypto.Util.ListUtil.
Require Import Crypto.Util.NatUtil.
Require Import Crypto.Util.ZUtil.AddGetCarry.
Require Import Crypto.Util.ZUtil.AddModulo.
Require Import Crypto.Util.ZUtil.CC.
Require Import Crypto.Util.ZUtil.MulSplit.
Require Import Crypto.Util.ZUtil.Rshi.
Require Import Crypto.Util.ZUtil.TruncatingShiftl.
Require Import Crypto.Util.ZUtil.Zselect.
Require Import Crypto.Util.ZUtil.Combine.
Require Import Crypto.Util.ZUtil.Le.
Require Import Crypto.Util.ZUtil.Tactics.LtbToLt.
Require Import Crypto.Util.ZUtil.Tactics.SplitMinMax.
Require Import Crypto.Util.ZUtil.Tactics.ReplaceNegWithPos.
Require Import Crypto.Util.ZUtil.Tactics.DivModToQuotRem.
Require Import Crypto.Util.ZUtil.Morphisms.
Require Import Crypto.Util.HProp.
Require Import Crypto.Util.Tactics.BreakMatch.
Require Import Crypto.Util.Tactics.DestructHead.
Require Import Crypto.Util.Tactics.SplitInContext.
Require Import Crypto.Util.Tactics.UniquePose.
Require Import Crypto.Util.Tactics.SpecializeBy.
Require Import Crypto.Util.Tactics.SpecializeAllWays.
Require Import Crypto.Util.Tactics.Head.
Require Import Crypto.Util.Tactics.PrintGoal.
Require Import Crypto.LanguageWf.
Require Import Crypto.AbstractInterpretation.

Module Compilers.
  Import LanguageWf.Compilers.
  Import AbstractInterpretation.Compilers.

  Module ZRange.
    Module type.
      Module base.
        Module option.
          Lemma is_bounded_by_None t v : ZRange.type.base.option.is_bounded_by (@ZRange.type.base.option.None t) v = true.
          Proof. induction t; cbn; cbv [andb]; break_innermost_match; eauto. Qed.
        End option.
      End base.

      Module option.
        Lemma is_bounded_by_impl_related_hetero t
              (x : ZRange.type.option.interp t) (v : type.interp base.interp t)
        : ZRange.type.option.is_bounded_by x v = true
          -> type.related_hetero (fun t x v => ZRange.type.base.option.is_bounded_by x v = true) x v.
        Proof. induction t; cbn in *; intuition congruence. Qed.
      End option.
    End type.

    Module ident.
      Module option.
        (** First we prove relatedness for some particularly complicated identifiers separately *)
        Section interp_related.
          Context (cast_outside_of_range : zrange -> Z -> Z).

          Local Notation interp_is_related idc
            := (type.related_hetero
                  (fun t st v => ZRange.type.base.option.is_bounded_by st v = true)
                  (ZRange.ident.option.interp idc)
                  (ident.gen_interp cast_outside_of_range idc)).

          Local Ltac z_cast_t :=
            cbn [type.related_hetero ZRange.ident.option.interp ident.interp ident.gen_interp respectful_hetero type.interp ZRange.type.base.option.interp ZRange.type.base.interp base.interp base.base_interp ZRange.type.base.option.Some];
            cbv [ZRange.ident.option.interp_Z_cast ZRange.type.base.option.is_bounded_by ZRange.type.base.is_bounded_by respectful_hetero];
            intros; break_innermost_match; trivial;
            rewrite ?Bool.andb_true_iff, ?Bool.andb_false_iff in *; destruct_head'_and; destruct_head'_or; repeat apply conj; Z.ltb_to_lt;
            rewrite ?ident.cast_in_bounds by (eapply ZRange.is_bounded_by_iff_is_tighter_than; eauto);
            try reflexivity; try lia; try assumption.

          Lemma interp_related_Z_cast r : interp_is_related (@ident.Z_cast r).
          Proof. z_cast_t. Qed.

          Lemma interp_related_Z_cast2 r : interp_is_related (@ident.Z_cast2 r).
          Proof. z_cast_t. Qed.

          Lemma interp_related_List_flat_map A B : interp_is_related (@ident.List_flat_map A B).
          Proof.
            cbn; cbv [respectful_hetero]; intros.
            destruct_head' option; cbn in *; [ | reflexivity ].
            break_match; cbn in *; [ | reflexivity ].
            let v := (eval cbv [base.interp ZRange.type.base.option.interp ZRange.type.base.interp] in (@ZRange.type.base.option.interp)) in
            progress change v with (@ZRange.type.base.option.interp) in *.
            progress fold (@base.interp) in *.
            rewrite FoldBool.fold_andb_map_iff in *.
            rewrite OptionList.fold_right_option_seq in *.
            destruct_head'_ex.
            destruct_head'_and.
            rewrite List.flat_map_concat_map, concat_fold_right_app.
            subst.
            lazymatch goal with
            | [ H : List.map _ ?ls1 = List.map _ ?ls' |- length (List.fold_right _ _ ?ls1) = length (List.fold_right _ _ (List.map _ ?ls2)) /\ _ ]
              => is_var ls1; is_var ls2; is_var ls';
                   revert dependent ls'; intro ls'; revert dependent ls2; revert ls'; induction ls1 as [|? xs IHxs];
                     intros [|? ls'] [|? ls2]; cbn [length] in *; intros; cbn in *;
                     [ tauto | exfalso; discriminate.. | ]
            end.
            repeat first [ progress cbn in *
                         | progress subst
                         | discriminate
                         | congruence
                         | progress autorewrite with distr_length
                         | progress destruct_head'_and
                         | rewrite combine_app_samelength
                         | rewrite FoldBool.fold_andb_map_iff in *
                         | specialize (IHxs _ _ ltac:(eassumption) ltac:(eassumption) ltac:(eassumption))
                         | match goal with
                           | [ H : cons _ _ = cons _ _ |- _ ] => inversion H; clear H
                           | [ H : S _ = S _ |- _ ] => inversion H; clear H
                           | [ H : forall v, _ = v \/ _ -> _ |- _ ] => pose proof (H _ (or_introl eq_refl)); specialize (fun v pf => H v (or_intror pf))
                           | [ H : forall x y, ?R x y = true -> match ?f x with Some _ => _ | None => _ end = true, H' : Some _ = ?f ?x' |- _ ]
                             => specialize (H _ _ ltac:(eassumption)); rewrite <- H' in H
                           | [ |- context[List.In _ (_ ++ _)] ] => setoid_rewrite List.in_app_iff
                           end
                         | solve [ intuition ] ].
          Qed.

          Lemma interp_related_List_partition A : interp_is_related (@ident.List_partition A).
          Proof.
            cbn; cbv [respectful_hetero]; intros.
            destruct_head' option; cbn in *; [ | break_innermost_match; reflexivity ].
            let v := (eval cbv [base.interp ZRange.type.base.option.interp ZRange.type.base.interp] in (@ZRange.type.base.option.interp)) in
            progress change v with (@ZRange.type.base.option.interp) in *.
            progress fold (@base.interp) in *.
            rewrite FoldBool.fold_andb_map_iff in *.
            destruct_head'_ex.
            destruct_head'_and.
            repeat break_match_step ltac:(fun v => let t := type of v in match (eval hnf in t) with prod _ _ => idtac end).
            repeat match goal with H : option (list _) |- _ => revert dependent H end.
            lazymatch goal with
            | [ Heq : List.partition _ _ = (?l0, ?l1), H : length ?ls1 = length ?ls2 |- _ ]
              => is_var ls1; is_var ls2; is_var l0; is_var l1;
                   revert dependent l0; intro l0; revert dependent l1; intro l1;
                     revert dependent ls2; intro ls2;
                       revert ls2 l0 l1;
                       induction ls1 as [|? xs IHxs]; intros [|? ls2]; cbn [length] in *; cbn in *;
                         [ intros [|? ?] [|? ?]; cbn in *; intros; break_innermost_match; cbn in *;
                           inversion_prod; inversion_option; subst..
                         | ];
                         [ tauto | exfalso; discriminate.. | intros ]
            end.
            repeat first [ progress cbn in *
                         | progress subst
                         | match goal with
                           | [ H : S _ = S _ |- _ ] => inversion H; clear H
                           end
                         | discriminate
                         | congruence
                         | progress destruct_head'_and
                         | progress inversion_prod
                         | progress eta_expand
                         | rewrite Bool.if_const
                         | specialize (fun l0 l1 => IHxs _ l0 l1 ltac:(eassumption))
                         | specialize (fun l0 l1 => IHxs l0 l1 ltac:(eassumption))
                         | specialize (IHxs _ _ (@surjective_pairing _ _ _))
                         | progress Bool.split_andb
                         | match goal with
                           | [ |- context[Option.bind ?x ?y] ] => destruct x eqn:?
                           | [ H : bool_eq _ _ = true |- _ ] => apply bool_eq_ok in H
                           | [ H : forall v, _ = v \/ _ -> _ |- _ ] => pose proof (H _ (or_introl eq_refl)); specialize (fun v pf => H v (or_intror pf))
                           | [ |- context[match ?b with true => ?f ?x | false => ?f ?y end] ]
                             => replace (match b with true => f x | false => f y end)
                               with (f match b with true => x | false => y end)
                                    by now case b
                           | [ H : context[match ?b with true => ?f ?x | false => ?f ?y end] |- _ ]
                             => replace (match b with true => f x | false => f y end)
                               with (f match b with true => x | false => y end)
                               in H
                               by now case b
                           | [ H : _ = (_, _) -> _ |- _ ] => specialize (fun pf1 pf2 => H (@path_prod _ _ _ _ pf1 pf2))
                           | [ H : ?x = _, H' : context[?x] |- _ ] => rewrite H in H'
                           | [ H : ?x = _ :> bool |- context[?x] ] => rewrite H
                           | [ H : forall x y, ?R x y = true -> match ?f x with Some _ => _ | None => _ end _ = true, H' : ?f ?x' = Some _ |- _ ]
                             => specialize (H _ _ ltac:(eassumption)); rewrite H' in H
                           end
                         | progress break_innermost_match_step ].
          Qed.

          Local Ltac handle_lt_le_t_step_fast :=
            first [ match goal with
                    | [ H : (?a <= ?b)%Z, H' : (?b <= ?a)%Z |- _ ]
                      => pose proof (@Z.le_antisymm _ _ H H'); clear H H'
                    | [ H : (?a <= ?b <= ?a)%Z |- _ ]
                      => pose proof (@Z.le_antisymm _ _ (proj1 H) (proj2 H)); clear H
                    end ].

          Local Ltac handle_lt_le_t_step :=
            first [ handle_lt_le_t_step_fast
                  | match goal with
                    | [ |- context[Z.leb ?a ?b = true] ] => rewrite !Z.leb_le
                    | [ |- context[Z.ltb ?a ?b = true] ] => rewrite !Z.ltb_lt
                    | [ |- context[Nat.eqb ?a ?b = true] ] => rewrite !Nat.eqb_eq
                    | [ |- context[Z.eqb ?a ?b = true] ] => rewrite !Z.eqb_eq
                    | [ H : context[andb ?a ?b = true] |- _ ] => rewrite !Bool.andb_true_iff in H
                    | [ H : context[Z.leb ?a ?b = true] |- _ ] => rewrite !Z.leb_le in H
                    | [ H : context[Z.ltb ?a ?b = true] |- _ ] => rewrite !Z.ltb_lt in H
                    | [ H : context[Nat.eqb ?a ?b = true] |- _ ] => rewrite !Nat.eqb_eq in H
                    | [ H : context[Z.eqb ?a ?b = true] |- _ ] => rewrite !Z.eqb_eq in H
                    end ].

          Local Ltac handle_mod_bounds_t_step_fast :=
            first [ match goal with
                    | [ |- (0 <= _ mod _)%Z ] => apply Z.mod_pos_bound
                    | [ |- (_ mod ?m < ?m)%Z ] => apply Z.mod_pos_bound
                    | [ |- (?x mod ?m <= ?m - 1)%Z ] => cut (x mod m < m)%Z; [ clear; lia | ]
                    end ].

          Local Ltac simplify_ranges_t_step_fast :=
            first [ match goal with
                    | [ H : ZRange.lower ?r = ZRange.upper ?r |- _ ]
                      => is_var r; let x := fresh in destruct r as [r x]; cbn in H; subst x
                    | [ H : context[ZRange.type.base.is_bounded_by r[_ ~> _]%zrange _] |- _ ]
                      => progress cbn [ZRange.type.base.is_bounded_by] in H
                    | [ H : context[is_bounded_by_bool _ r[_ ~> _]%zrange] |- _ ]
                      => progress cbv [is_bounded_by_bool] in H
                    end ].
          Local Ltac simplify_ranges_t_step :=
            first [ simplify_ranges_t_step_fast ].

          Local Ltac non_arith_t :=
            repeat first [ assumption
                         | match goal with
                           | [ |- ?R ?x ?x ] => reflexivity
                           | [ H : forall x : unit, _ |- _ ] => specialize (H tt)
                           | [ H : ?x = ?x -> _ |- _ ] => specialize (H eq_refl)
                           | [ H : ?x = ?x |- _ ] => clear H
                           | [ H : false = true |- _ ] => exfalso; clear -H; discriminate
                           | [ H : ~?R ?x ?x |- _ ] => exfalso; apply H; reflexivity
                           | [ |- ZRange.type.base.option.is_bounded_by ZRange.type.base.option.None _ = true ]
                             => apply type.base.option.is_bounded_by_None
                           | [ H : FoldBool.fold_andb_map _ ?l1 ?l2 = true |- length ?l1 = length ?l2 ]
                             => eapply FoldBool.fold_andb_map_length, H
                           | [ H : forall x y, Nat.eqb x y = true -> _ |- _ ] => specialize (fun x => H x x (@Nat.eqb_refl x))
                           | [ H : forall x, true = true -> _ |- _ ] => specialize (fun x => H x eq_refl)
                           | [ H : forall v, List.In v (List.combine ?ls1 ?ls2) -> ?R (fst v) (snd v) = true,
                                 H1 : List.nth_error ?ls1 ?n = Some ?v1,
                                 H2 : List.nth_error ?ls2 ?n = Some ?v2
                                 |- ?R ?v1 ?v2 = true ]
                             => apply (H (v1, v2)), (@nth_error_In _ _ n); clear -H1 H2
                           | [ H : ?T, H' : ~?T |- _ ] => exfalso; solve [ apply H', H ]
                           | [ H : List.nth_error ?ls ?n = Some _, H' : List.nth_error ?ls' ?n = None |- _ ]
                             => let Hlen := fresh in
                                assert (Hlen : length ls = length ls') by congruence;
                                exfalso; clear -H H' Hlen;
                                apply nth_error_value_length in H;
                                apply nth_error_error_length in H';
                                omega
                           | [ |- (0 <= 1)%Z ] => clear; omega
                           end
                         | handle_lt_le_t_step_fast
                         | simplify_ranges_t_step_fast
                         | handle_mod_bounds_t_step_fast
                         | progress intros
                         | progress subst
                         | progress inversion_option
                         | progress inversion_prod
                         | progress destruct_head'_and
                         | progress destruct_head'_unit
                         | progress destruct_head'_prod
                         | progress destruct_head'_ex
                         | break_innermost_match_step
                         | break_innermost_match_hyps_step
                         | progress cbn [ZRange.type.base.option.is_bounded_by is_bounded_by_bool ZRange.type.base.is_bounded_by lower upper fst snd projT1 projT2 bool_eq base.interp base.base_interp Option.bind FoldBool.fold_andb_map negb ZRange.ident.option.to_literal ZRange.type.base.option.None ident.to_fancy invert_Some ident.fancy.interp ident.fancy.interp_with_wordmax fst snd ZRange.type.base.option.interp ZRange.type.base.interp List.combine List.In] in *
                         | progress destruct_head'_bool
                         | solve [ auto with nocore ]
                         | progress fold (@base.interp) in *
                         | let v := (eval cbv [base.interp ZRange.type.base.option.interp ZRange.type.base.interp] in (@ZRange.type.base.option.interp)) in
                           progress change v with (@ZRange.type.base.option.interp) in *
                         | handle_lt_le_t_step
                         | simplify_ranges_t_step
                         | match goal with
                           | [ |- context[andb ?a ?b = true] ] => rewrite !Bool.andb_true_iff
                           | [ H : context[andb ?a ?b = true] |- _ ] => rewrite !Bool.andb_true_iff
                           | [ H : FoldBool.fold_andb_map _ _ _ = true |- _ ] => rewrite FoldBool.fold_andb_map_iff in H
                           | [ |- FoldBool.fold_andb_map _ _ _ = true ] => rewrite FoldBool.fold_andb_map_iff
                           | [ H : forall (x : option _), _ |- _ ] => pose proof (H None); specialize (fun x => H (Some x))
                           | [ H : forall x y z (w : option _), _ |- _ ] => pose proof (fun x y z => H x y z None); specialize (fun x y z w => H x y z (Some w))
                           | [ H : forall v, _ = v \/ _ -> _ |- _ ] => pose proof (H _ (or_introl eq_refl)); specialize (fun v pf => H v (or_intror pf))
                           | [ |- context[length ?x] ] => tryif is_var x then fail else (progress autorewrite with distr_length)
                           | [ H : List.In _ (List.combine _ _) |- _ ] => apply List.In_nth_error in H
                           | [ H : context[List.nth_error (List.combine _ _) _] |- _ ] => rewrite nth_error_combine in H
                           | [ |- context[List.nth_error (List.combine _ _) _] ] => rewrite nth_error_combine
                           | [ H : List.nth_error (List.map _ _) _ = Some _ |- _ ] => apply nth_error_map in H
                           | [ H : context[List.nth_error (List.seq _ _) _] |- _ ] => rewrite nth_error_seq in H
                           | [ |- context[List.nth_error (List.seq _ _) _] ] => rewrite nth_error_seq
                           | [ H : context[List.nth_error (List.firstn _ _) _] |- _ ] => rewrite nth_error_firstn in H
                           | [ |- context[List.nth_error (List.firstn _ _) _] ] => rewrite nth_error_firstn
                           | [ H : context[List.nth_error (List.skipn _ _) _] |- _ ] => rewrite nth_error_skipn in H
                           | [ |- context[List.nth_error (List.skipn _ _) _] ] => rewrite nth_error_skipn
                           | [ H : context[List.nth_error (update_nth _ _ _) _] |- _ ] => rewrite nth_update_nth in H
                           | [ |- context[List.nth_error (update_nth _ _ _) _] ] => rewrite nth_update_nth
                           | [ H : context[List.nth_error (List.app _ _) _] |- _ ] => rewrite nth_error_app in H
                           | [ |- context[List.nth_error (List.app _ _) _] ] => rewrite nth_error_app
                           | [ H : context[List.nth_error (List.rev _) _] |- _ ] => rewrite nth_error_rev in H
                           | [ |- context[List.nth_error (List.rev _) _] ] => rewrite nth_error_rev
                           | [ H : List.nth_error (Lists.List.repeat _ _) _ = Some _ |- _ ] => apply nth_error_repeat in H
                           | [ H : List.nth_error (List.repeat _ _) _ = Some _ |- _ ] => apply nth_error_repeat in H
                           | [ H : length ?l1 = length ?l2 |- context[length ?l1] ] => rewrite H
                           | [ H : length ?l1 = length ?l2, H' : context[length ?l1] |- _ ] => rewrite H in H'
                           | [ |- context[List.flat_map _ _] ] => rewrite List.flat_map_concat_map, concat_fold_right_app
                           | [ H : S _ = S _ |- _ ] => inversion H; clear H
                           | [ H : List.fold_right (fun x y => x <- x; y <- y; Some _)%option (Some ?init) ?ls = Some ?v |- _]
                             => rewrite OptionList.fold_right_option_seq in H
                           | [ |- and _ _ ] => apply conj
                           end
                         | progress cbv [bool_eq option_map List.nth_default Definitions.Z.bneg is_bounded_by_bool zrange_beq] in *
                         | match goal with
                           | [ |- ?R (nat_rect ?P ?O ?S ?n) (nat_rect ?P' ?O' ?S' ?n) = true ]
                             => is_var n; induction n; cbn [nat_rect];
                                generalize dependent (nat_rect P O S); generalize dependent (nat_rect P' O' S');
                                intros
                           | [ |- ?R (nat_rect ?P ?O ?S ?n ?x) (nat_rect ?P' ?O' ?S' ?n ?y) = true ]
                             => is_var n; is_var x; is_var y;
                                revert dependent x; revert dependent y; induction n; cbn [nat_rect];
                                generalize dependent (nat_rect P O S); generalize dependent (nat_rect P' O' S');
                                intros
                           | [ H : length ?ls = length ?ls' |- ?R (List.fold_right ?f ?x ?ls) (List.fold_right ?f' ?x' ?ls') = true ]
                             => is_var ls; is_var ls';
                                let IH := fresh "IH" in
                                revert dependent ls'; induction ls as [|? ls IH]; intros [|? ls']; cbn [List.fold_right length] in *;
                                [
                                 | exfalso; clear -H; discriminate | exfalso; clear -H; discriminate
                                 | specialize (IH ls');
                                   generalize dependent (List.fold_right f x); generalize dependent (List.fold_right f' x') ];
                                intros
                           | [ H : length ?ls = length ?ls' |- ?R (List.fold_right ?f ?x ?ls) (List.fold_right ?f' ?x' ?ls') = true ]
                             => is_var ls; is_var ls';
                                let IH := fresh "IH" in
                                revert dependent ls'; induction ls as [|? ls IH]; intros [|? ls']; intros; cbn [List.fold_right length] in *;
                                [
                                 | exfalso; discriminate | exfalso; discriminate
                                 | specialize (IH ls');
                                   generalize dependent (List.fold_right f x); generalize dependent (List.fold_right f' x') ];
                                intros
                           | [ H : length ?ls = length ?ls' |- ?R (list_rect ?P ?N ?C ?ls) (list_rect ?P' ?N' ?C' ?ls') = true ]
                             => is_var ls; is_var ls';
                                let IH := fresh "IH" in
                                revert dependent ls'; induction ls as [|? ls IH]; intros [|? ls']; intros; cbn [list_rect length] in *;
                                [
                                 | exfalso; discriminate | exfalso; discriminate
                                 | specialize (IH ls');
                                   generalize dependent (list_rect P N C); generalize dependent (list_rect P' N' C') ];
                                intros
                           | [ H : length ?ls = length ?ls' |- ?R (list_rect ?P ?N ?C ?ls ?x) (list_rect ?P' ?N' ?C' ?ls' ?y) = true ]
                             => is_var ls; is_var ls'; is_var x; is_var y;
                                revert dependent y; try revert dependent x;
                                let IH := fresh "IH" in
                                revert dependent ls'; induction ls as [|? ls IH]; intros [|? ls']; intros; cbn [list_rect length] in *;
                                [
                                | exfalso; discriminate | exfalso; discriminate
                                | specialize (IH ls');
                                  generalize dependent (list_rect P N C); generalize dependent (list_rect P' N' C') ];
                                intros
                           | [ H : forall a b, ?R a b = true -> ?R' (?f a) (?g b) = true |- ?R' (?f _) (?g _) = true ] => apply H; clear H
                           | [ H : forall a b, ?R a b = true -> forall c d, ?R' c d = true -> ?R'' (?f a c) (?g b d) = true |- ?R'' (?f _ _) (?g _ _) = true ]
                             => apply H; clear H
                           | [ H : forall a b, ?R a b = true -> forall c d, ?R' c d = true -> forall e f, ?R'' e f = true -> ?R''' (?F _ _ _) (?G _ _ _) = true |- ?R''' (?F _ _ _) (?G _ _ _) = true ]
                             => apply H; clear H
                           | [ H : context[ZRange.type.base.option.is_bounded_by (?f (Some _) (Some _)) (?g _ _) = true]
                               |- ZRange.type.base.option.is_bounded_by (?f (Some _) (Some _)) (?g _ _) = true ]
                             => apply H
                           | [ H : (forall a b, ?R0 a b = true -> forall c d, ?R1 c d = true -> forall e f, (forall g h, ?R3 g h = true -> ?R4 (e g) (f h) = true) -> forall i j, ?R5 i j = true -> ?R6 (?F _ _ _ _) (?G _ _ _ _) = true)
                               |- ?R6 (?F _ _ _ _) (?G _ _ _ _) = true ]
                             => apply H; clear H
                           end ].

          Local Lemma mul_by_halves_bounds x y n :
            (0 <= x < 2^ (n / 2))%Z ->
            (0 <= y < 2^ (n / 2))%Z ->
            (0 <= x * y <= 2 ^ n - 1)%Z.
          Proof.
            intros. rewrite Z.le_sub_1_iff.
            assert (2 ^ (n / 2) * 2 ^ (n / 2) <= 2 ^ n)%Z.
            { rewrite <-Z.pow_twice_r.
              apply Z.pow_le_mono_r; auto with zarith; [ ].
              Z.div_mod_to_quot_rem. nia. }
            Z.div_mod_to_quot_rem; nia.
          Qed.

          Local Ltac mul_by_halves_t :=
            apply mul_by_halves_bounds;
            match goal with
            | |- context [Z.land _ (2 ^ ?n - 1)%Z] =>
              rewrite (Z.sub_1_r (2 ^ n)), <-Z.ones_equiv, !Z.land_ones by auto with zarith
            | |- context [Z.shiftr ?a ?n] =>
            apply LandLorShiftBounds.Z.shiftr_range; auto with zarith; rewrite Z.add_diag, <-Z_div_exact_full_2 by auto with zarith
            end; auto using Z.mod_pos_bound with zarith.

          Local Lemma interp_related_fancy_rshi k n :
            interp_is_related (ident.fancy_rshi k n).
          Proof.
            cbn [type.related_hetero ZRange.ident.option.interp ident.interp ident.gen_interp respectful_hetero type.interp ZRange.type.base.option.interp ZRange.type.base.interp base.interp base.base_interp ZRange.type.base.option.Some ZRange.ident.option.of_literal].
            cbv [respectful_hetero option_map list_case].
            clear cast_outside_of_range.
            intros.
            destruct_head_hnf' prod.
            break_innermost_match;
              auto using type.base.option.is_bounded_by_None;
              cbn [ZRange.type.base.option.is_bounded_by ZRange.type.base.is_bounded_by Option.bind ZRange.ident.option.to_literal ident.fancy.interp invert_Some ident.to_fancy ident.fancy.interp_with_wordmax] in *;
              repeat match goal with
                     | H : _ |- _ =>
                     rewrite Bool.andb_true_iff in H;
                       destruct H
                     | _ => progress destruct_head_hnf' option; try congruence; [ ]
                     | _ => progress cbv [is_bounded_by_bool is_tighter_than_bool] in *; cbn in *
                     | _ => progress cbn in *
                     end.

             { Z.ltb_to_lt. rewrite !Z.rshi_small by omega.
               apply Bool.andb_true_iff; split; apply Z.leb_le;
                 Z.div_mod_to_quot_rem; nia. }
             { Z.ltb_to_lt.
               rewrite Z.rshi_correct_full by omega.
               break_innermost_match; apply Bool.andb_true_iff; split; apply Z.leb_le; try apply Z.le_sub_1_iff; auto with zarith. }
          Qed.

          Lemma interp_related {t} (idc : ident t) : interp_is_related idc.
          Proof.
            destruct idc.
            all: lazymatch goal with
                 | [ |- context[ident.Z_cast] ] => apply interp_related_Z_cast
                 | [ |- context[ident.Z_cast2] ] => apply interp_related_Z_cast2
                 | [ |- context[ident.List_flat_map] ] => apply interp_related_List_flat_map
                 | [ |- context[ident.List_partition] ] => apply interp_related_List_partition
                 | [ |- context[ident.fancy_rshi] ] => apply interp_related_fancy_rshi
                 | _ => idtac
                 end.
            all: cbn [type.related_hetero ZRange.ident.option.interp ident.interp ident.gen_interp respectful_hetero type.interp ZRange.type.base.option.interp ZRange.type.base.interp base.interp base.base_interp ZRange.type.base.option.Some ZRange.ident.option.of_literal].
            all: cbv [respectful_hetero option_map option_rect zrange_rect list_case].
            all: intros.
            all: destruct_head_hnf' prod.
            all: destruct_head_hnf' option.
            Time all: try solve [ non_arith_t ].
            all: cbn [ZRange.type.base.option.is_bounded_by ZRange.type.base.is_bounded_by Option.bind ZRange.ident.option.to_literal ident.fancy.interp invert_Some ident.to_fancy ident.fancy.interp_with_wordmax] in *.
            all: break_innermost_match; try reflexivity.
            Time all: try solve [ non_arith_t ].
            all: repeat first [ progress subst
                              | progress inversion_prod
                              | progress inversion_option
                              | progress destruct_head'_and
                              | progress cbn [ZRange.type.base.option.is_tighter_than lower upper fst snd Option.bind ZRange.type.base.is_tighter_than] in *
                              | progress cbv [Definitions.Z.lnot_modulo Definitions.Z.add_with_carry] in *
                              | handle_lt_le_t_step
                              | simplify_ranges_t_step
                              | discriminate
                              | solve [ auto using ZRange.is_bounded_by_bool_Proper_if_sumbool_union, Z.mod_pos_bound, Z.mod_neg_bound with zarith ]
                              | rewrite ZRange.is_bounded_by_bool_opp
                              | progress autorewrite with zsimplify_const
                              | rewrite Z.le_sub_1_iff
                              | rewrite Z.le_add_1_iff
                              | match goal with
                                | [ H : ?x = ?x |- _ ] => clear H
                                | [ |- andb (is_bounded_by_bool (_ mod ?m) (fst (Operations.ZRange.split_bounds _ ?m)))
                                           (is_bounded_by_bool (_ / ?m) (snd (Operations.ZRange.split_bounds _ ?m))) = true ]
                                  => apply ZRange.is_bounded_by_bool_split_bounds
                                | [ |- is_bounded_by_bool (_ mod _) r[_ ~> _] = true ] => cbv [is_bounded_by_bool]; rewrite Bool.andb_true_iff
                                | [ H : is_bounded_by_bool ?v ?r1 = true, H' : is_tighter_than_bool ?r1 ?r2 = true |- _ ]
                                  => pose proof (@ZRange.is_bounded_by_of_is_tighter_than r1 r2 H' v H);
                                     clear H H' r1
                                | [ |- context [match (if _ then _ else _) with _ => _ end ] ]
                                  => break_innermost_match
                                | [ |- context[ZRange.constant ?x] ] => unique pose proof (ZRange.is_bounded_by_bool_constant x)
                                | [ |- context[r[?x~>?x]%zrange] ] => unique pose proof (ZRange.is_bounded_by_bool_constant x)
                                end
                              | progress Z.ltb_to_lt
                              | progress rewrite ?Z.mul_split_div, ?Z.mul_split_mod, ?Z.add_get_carry_full_div, ?Z.add_get_carry_full_mod, ?Z.add_with_get_carry_full_div, ?Z.add_with_get_carry_full_mod, ?Z.sub_get_borrow_full_div, ?Z.sub_get_borrow_full_mod, ?Z.sub_with_get_borrow_full_div, ?Z.sub_with_get_borrow_full_mod, ?Z.zselect_correct, ?Z.add_modulo_correct, ?Z.rshi_correct_full, ?Z.truncating_shiftl_correct_land_ones ].
            all: clear cast_outside_of_range.
            all: repeat lazymatch goal with
                        | [ |- is_bounded_by_bool (Z.land _ _) (ZRange.land_bounds _ _) = true ]
                          => apply ZRange.is_bounded_by_bool_land_bounds; auto
                        | [ |- is_bounded_by_bool (Z.lor _ _) (ZRange.lor_bounds _ _) = true ]
                          => apply ZRange.is_bounded_by_bool_lor_bounds; auto
                        | [ |- is_bounded_by_bool (if _ then (_ + _ - _)%Z else (_ + _)%Z) (ZRange.union (ZRange.four_corners Z.add _ _) (ZRange.eight_corners _ _ _ _)) = true ]
                          => rewrite ZRange.union_comm; apply ZRange.is_bounded_by_bool_Proper_if_bool_union_dep; intros; Z.ltb_to_lt
                        | [ |- is_bounded_by_bool (?a + ?b - ?c) (ZRange.eight_corners (fun x y z => Z.max 0 (x + y - z)) _ _ _) = true ]
                          => replace (a + b - c)%Z with (Z.max 0 (a + b - c)) by lia
                        | [ Hx : is_bounded_by_bool _ ?x = true, Hy : is_bounded_by_bool _ ?y = true, Hz : is_bounded_by_bool _ ?z = true
                            |- is_bounded_by_bool _ (ZRange.eight_corners ?f ?x ?y ?z) = true ]
                          => apply (fun pf1 pf2 pf3 => @ZRange.monotoneb_eight_corners_gen f pf1 pf2 pf3 _ _ _ _ _ _ Hx Hy Hz); intros; auto with zarith
                        | [ Hx : is_bounded_by_bool _ ?x = true, Hy : is_bounded_by_bool _ ?y = true
                            |- is_bounded_by_bool _ (ZRange.four_corners_and_zero ?f ?x ?y) = true ]
                          => apply (fun pf1 pf2 pf3 pf4 => @ZRange.monotoneb_four_corners_and_zero_gen f pf1 pf2 pf3 pf4 _ _ _ _ Hx Hy); intros; auto with zarith
                        | [ Hx : is_bounded_by_bool _ ?x = true, Hy : is_bounded_by_bool _ ?y = true
                            |- is_bounded_by_bool _ (ZRange.four_corners ?f ?x ?y) = true ]
                          => apply (fun pf1 pf2 => @ZRange.monotoneb_four_corners_gen f pf1 pf2 _ _ _ _ Hx Hy); intros; auto with zarith
                        | [ Hx : is_bounded_by_bool _ ?x = true
                            |- is_bounded_by_bool _ (ZRange.two_corners ?f ?x) = true ]
                          => apply (fun pf => @ZRange.monotoneb_two_corners_gen f pf x _ Hx); intros; auto with zarith
                        | [ |- is_bounded_by_bool (if _ then _ else _) (ZRange.four_corners _ _ _) = true ]
                          => apply ZRange.is_bounded_by_bool_Proper_if_bool_union_dep; intros; Z.ltb_to_lt
                        | [ H : ?x <> ?x |- _ ] => destruct (H eq_refl)
                        | [ |- context[Proper _ (Z.mul ?v)] ] => is_var v; destruct v; auto with zarith
                        | [ |- context[Proper _ (Z.div ?v)] ] => is_var v; destruct v; auto with zarith
                        | [ |- context[Proper _ (fun y => Z.mul _ ?v)] ] => is_var v; destruct v; auto with zarith
                        | [ |- context[Proper _ (fun y => Z.mul ?v _)] ] => is_var v; destruct v; auto with zarith
                        | [ |- context[Proper _ (fun y => Z.div _ ?v)] ] => is_var v; destruct v; auto with zarith
                        | [ |- context[Proper _ (fun y => Z.div ?v _)] ] => is_var v; destruct v; auto with zarith
                        | [ |- context[Proper _ (fun y => Z.shiftr _ ?v)] ] => is_var v; destruct v; auto with zarith
                        | [ |- context[Proper _ (fun y => Z.shiftr ?v _)] ] => is_var v; destruct v; auto with zarith
                        | [ |- context[Proper _ (fun y => Z.shiftl _ ?v)] ] => is_var v; destruct v; auto with zarith
                        | [ |- context[Proper _ (fun y => Z.shiftl ?v _)] ] => is_var v; destruct v; auto with zarith
                        | _ => idtac
                        end.
            all: try solve [ cbv [Proper respectful Basics.flip]; constructor; intros; lia ].
            all: try solve [ cbv [Proper respectful Basics.flip]; constructor; intros; autorewrite with zsimplify_const; lia ].
            all: cbv [is_bounded_by_bool ZRange.upper ZRange.lower]; rewrite ?Bool.andb_true_iff, ?Z.leb_le.
            all: try solve [ match goal with
                             | [ |- ((0 <= _ mod _ <= _) /\ (0 <= _ <= _))%Z ]
                               => Z.div_mod_to_quot_rem; nia
                             end
                           | intros; mul_by_halves_t ].
            (** For command-line debugging, we display goals that should not remain *)
            all: [ > idtac "WARNING: Remaining goal:"; print_context_and_goal () .. | | ].
            { intros.
              rewrite Z.le_sub_1_iff.
              break_innermost_match; Z.ltb_to_lt;
                auto with zarith. }
            { non_arith_t; Z.ltb_to_lt; reflexivity. }
          Qed.
        End interp_related.
      End option.
    End ident.
  End ZRange.
End Compilers.
