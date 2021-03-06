theory UntypedNom
imports "Nominal2-Isabelle2015/Nominal/Nominal2" "~~/src/HOL/Eisbach/Eisbach" begin

text {* Disclaimer: Some of the definitions were copied over and adapted from Nominal2-Isabelle2015/Nominal/Nominal2/Ex/Lambda.thy *}

atom_decl name

nominal_datatype lam =
  Var "name"
| App "lam" "lam"
| Lam x::"name" l::"lam"  binds x in l ("Lam [_]. _" [100, 100] 100)

definition 
  Name :: "nat \<Rightarrow> name" 
where 
  "Name n = Abs_name (Atom (Sort ''name'' []) n)"

definition
   "Ident2 = Lam [Name 1].(Var (Name 1))"

definition 
   "Ident x = Lam [x].(Var x)"

lemma "Ident2 = Ident x"
unfolding Ident_def Ident2_def
by simp

lemma "Ident x = Ident y"
unfolding Ident_def
by simp




nominal_function
  subst :: "lam \<Rightarrow> name \<Rightarrow> lam \<Rightarrow> lam"  ("_ [_ ::= _]" [90, 90, 90] 90)
where
  "(Var x)[y ::= s] = (if x = y then s else (Var x))"
| "(App t1 t2)[y ::= s] = App (t1[y ::= s]) (t2[y ::= s])"
| "atom x \<sharp> (y, s) \<Longrightarrow> (Lam [x]. t)[y ::= s] = Lam [x].(t[y ::= s])"
  apply(simp add: eqvt_def subst_graph_aux_def)
  apply(rule TrueI)
  using [[simproc del: alpha_lst]]
  apply(auto)
  apply(rule_tac y="a" and c="(aa, b)" in lam.strong_exhaust)
  apply(blast)+
  using [[simproc del: alpha_lst]]
  apply(simp_all add: fresh_star_def fresh_Pair_elim)
  apply (erule_tac c="(ya,sa)" in Abs_lst1_fcb2)
  apply(simp_all add: Abs_fresh_iff)
  apply(simp add: fresh_star_def fresh_Pair)
  apply(simp only: eqvt_at_def)
  apply(perm_simp)
  apply(simp)
  apply(simp add: fresh_star_Pair perm_supp_eq)
  apply(simp only: eqvt_at_def)
  apply(perm_simp)
  apply(simp)
  apply(simp add: fresh_star_Pair perm_supp_eq)
done

nominal_termination (eqvt)
  by lexicographic_order


lemma forget:
  shows "atom x \<sharp> t \<Longrightarrow> t[x ::= s] = t"
  by (nominal_induct t avoiding: x s rule: lam.strong_induct)
     (auto simp add: fresh_at_base)

lemma fresh_fact:
  fixes z::"name"
  assumes a: "atom z \<sharp> s"
      and b: "z = y \<or> atom z \<sharp> t"
  shows "atom z \<sharp> t[y ::= s]"
  using a b
  by (nominal_induct t avoiding: z y s rule: lam.strong_induct)
      (auto simp add: fresh_at_base)

lemma substitution_lemma:  
  assumes a: "x \<noteq> y" "atom x \<sharp> u"
  shows "t[x ::= s][y ::= u] = t[y ::= u][x ::= s[y ::= u]]"
using a 
by (nominal_induct t avoiding: x y s u rule: lam.strong_induct)
   (auto simp add: fresh_fact forget)


subsection {* single-step beta-reduction *}

inductive 
  beta :: "lam \<Rightarrow> lam \<Rightarrow> bool" (" _ \<longrightarrow>b _" [80,80] 80)
where
  red_L[intro]: "t1 \<longrightarrow>b t2 \<Longrightarrow> App t1 s \<longrightarrow>b App t2 s"
| red_R[intro]: "s1 \<longrightarrow>b s2 \<Longrightarrow> App t s1 \<longrightarrow>b App t s2"
| abst[intro]: "t1 \<longrightarrow>b t2 \<Longrightarrow> Lam [x]. t1 \<longrightarrow>b Lam [x]. t2"
| beta[intro]: "atom x \<sharp> s \<Longrightarrow> App (Lam [x]. t) s \<longrightarrow>b t[x ::= s]"

equivariance beta

nominal_inductive beta
  avoids beta: "x"
  by (simp_all add: fresh_star_def fresh_Pair  fresh_fact)


subsection {* lambda beta theory *}

inductive lam_beta_eq :: "lam \<Rightarrow> lam \<Rightarrow> bool" ("\<lambda>b \<turnstile> _ = _") where
refl: "\<lambda>b \<turnstile> s = s" |
sym: "\<lambda>b \<turnstile> s = t \<Longrightarrow> \<lambda>b \<turnstile> t = s" |
trans: "\<lambda>b \<turnstile> s = t \<Longrightarrow> \<lambda>b \<turnstile> t = u \<Longrightarrow> \<lambda>b \<turnstile> s = u" |
app: "\<lambda>b \<turnstile> s = s' \<Longrightarrow> \<lambda>b \<turnstile> t = t' \<Longrightarrow> \<lambda>b \<turnstile> (App s t) = (App s' t')" |
beta: "atom x \<sharp> t \<Longrightarrow> \<lambda>b \<turnstile> (App (Lam [x]. s) t) = s [x ::= t]"

equivariance lam_beta_eq

nominal_inductive lam_beta_eq
  avoids beta: "x"
  by (simp_all add: fresh_star_def fresh_Pair  fresh_fact)


subsection {* parallel beta reduction *}

inductive 
  pbeta :: "lam \<Rightarrow> lam \<Rightarrow> bool" (" _ \<rightarrow>\<parallel>b _" [80,80] 80)
where
  refl[intro]: "(Var x) \<rightarrow>\<parallel>b (Var x)"
| p_app[intro]: "s \<rightarrow>\<parallel>b s' \<Longrightarrow> t \<rightarrow>\<parallel>b t' \<Longrightarrow> App s t \<rightarrow>\<parallel>b App s' t'"
| p_abs[intro]: "t1 \<rightarrow>\<parallel>b t2 \<Longrightarrow> Lam [x]. t1 \<rightarrow>\<parallel>b Lam [x]. t2"
| p_beta[intro]: "\<lbrakk> atom x \<sharp> t' ; atom x \<sharp> t \<rbrakk> \<Longrightarrow> s \<rightarrow>\<parallel>b s' \<Longrightarrow> t \<rightarrow>\<parallel>b t' \<Longrightarrow> App (Lam [x]. s) t \<rightarrow>\<parallel>b s'[x ::= t']"

equivariance pbeta

nominal_inductive pbeta
  avoids p_beta: "x" | p_abs: "x" (*don't understand what this does exactly or why we need it...*)
  by (simp_all add: fresh_star_def fresh_Pair  fresh_fact)



nominal_function 
  not_abst :: "lam \<Rightarrow> bool"
where
  "not_abst (Var x) = True"
| "not_abst (App t1 t2) = True"
| "not_abst (Lam [x]. t) = False"
apply (simp add: eqvt_def not_abst_graph_aux_def)
apply (rule TrueI)
apply (rule_tac y="x" in lam.exhaust)
using [[simproc del: alpha_lst]]
by auto

nominal_termination (eqvt) by lexicographic_order


subsection {* parallel beta reduction *}

inductive 
  pbeta_max :: "lam \<Rightarrow> lam \<Rightarrow> bool" (" _ >>> _" [80,80] 80)
where
  cd_refl[intro]: "(Var x) >>> (Var x)"
| cd_app[intro]: "not_abst s \<Longrightarrow> s >>> s' \<Longrightarrow> t >>> t' \<Longrightarrow> App s t >>> App s' t'"
| cd_abs[intro]: "t1 >>> t2 \<Longrightarrow> Lam [x]. t1 >>> Lam [x]. t2"
| cd_beta[intro]: "atom x \<sharp> t' \<Longrightarrow> atom x \<sharp> t \<Longrightarrow> s >>> s' \<Longrightarrow> t >>> t' \<Longrightarrow> App (Lam [x]. s) t >>> s'[x ::= t']"

equivariance pbeta_max

nominal_inductive pbeta_max
  avoids cd_beta: "x" | cd_abs: "x" (*don't understand what this does exactly or why we need it in the abs case ...*)
  by (simp_all add: fresh_star_def fresh_Pair fresh_fact)

thm pbeta_max.strong_induct


lemma Ex1_5: "x \<noteq> y \<Longrightarrow> atom x \<sharp> u \<Longrightarrow> (s[x ::= t])[y ::= u] = s[y ::= u][x ::= t[y ::= u]]"
proof (nominal_induct s avoiding: x y u t rule:lam.strong_induct)
case (Var s) thus ?case
  apply (cases "x = s")
  apply (cases "y = s")
  apply simp
  defer
  apply simp
  apply (subst forget) using Var
  by simp+
next
case (App p q)
  thus ?case by simp
next
case (Lam z p)
  show ?case 
  apply (subst subst.simps(3), simp add: Lam fresh_fact)+
  using Lam by simp
qed




lemma Lem2_5_1:
  assumes "s \<rightarrow>\<parallel>b s'"
      and "t \<rightarrow>\<parallel>b t'"
      shows "(s[x ::= t]) \<rightarrow>\<parallel>b (s'[x ::= t'])"
using assms proof (nominal_induct s s' avoiding: x t t' rule:pbeta.strong_induct)
case (refl s)
  then show ?case by auto
  (*proof (nominal_induct s avoiding: x t t' rule:lam.strong_induct)
  case (Var n) 
    thus ?case unfolding subst.simps
    apply (cases "n = x") 
    apply simp+
    by (rule pbeta.refl)
  next
  case App thus ?case unfolding subst.simps apply (rule_tac pbeta.p_app) by simp+
  next
  case Lam thus ?case unfolding subst.simps by auto
  qed*)
next
case p_app
  show ?case 
  unfolding subst.simps
  apply (rule pbeta.p_app)
  using p_app
  by simp+
next
case (p_beta y q' q p p')
  have "App ((Lam [y]. p) [x ::= t]) (q [x ::= t]) \<rightarrow>\<parallel>b (p' [x ::= t'])[y ::= q'[x ::= t']]"
  apply (subst subst.simps(3))
  defer
  apply (rule_tac pbeta.p_beta)
  using p_beta by (simp add: fresh_fact)+

  then show ?case unfolding subst.simps
  apply (subst Ex1_5) using p_beta by simp+
next
case (p_abs p p' y) 
  show ?case 
  apply (subst subst.simps)
  using p_abs apply simp
  apply (subst subst.simps)
  using p_abs apply simp
  apply (rule_tac pbeta.p_abs)
  using p_abs by simp
qed


lemma pbeta_refl[intro]: "s \<rightarrow>\<parallel>b s"
apply (induct s rule:lam.induct)
by auto


lemma pbeta_max_ex:
  fixes a
  shows "\<exists>d. a >>> d"
apply (nominal_induct a rule:lam.strong_induct)
apply auto
apply (case_tac "not_abst lam1")
apply auto[1]
proof -
case goal1 
  thus ?case
  apply (nominal_induct lam1 d avoiding: da lam2 rule:pbeta_max.strong_induct)
  by auto
qed



lemma subst_rename: 
  assumes a: "atom y \<sharp> t"
  shows "t[x ::= s] = ((y \<leftrightarrow> x) \<bullet> t)[y ::= s]"
using a 
apply (nominal_induct t avoiding: x y s rule: lam.strong_induct)
apply (auto simp add:  fresh_at_base)
done


lemma fresh_in_pbeta: "s \<rightarrow>\<parallel>b s' \<Longrightarrow> atom (x::name) \<sharp> s \<Longrightarrow>  atom x \<sharp> s'"
apply (nominal_induct s s' rule:pbeta.strong_induct)
apply simp
apply simp
apply auto[1]
proof - 
case (goal1 xx)
  then have "atom x \<sharp> t" by simp
  { assume "x = xx" with goal1 have ?case by (simp add: fresh_fact) }
  { assume "x \<noteq> xx" with goal1 have ?case by (simp add: fresh_fact) }
  thus ?case using `x = xx \<Longrightarrow> atom x \<sharp> s' [xx ::= t']` by blast
qed


(* adopting great naming conventions so early on! *)
lemma aaaaa2: "(Lam [x]. s) \<rightarrow>\<parallel>b s' \<Longrightarrow> \<exists>t. s' = Lam [x]. t \<and> s \<rightarrow>\<parallel>b t"
proof (cases "(Lam [x]. s)" s' rule:pbeta.cases, simp)
  case (goal1 _ _ x')
    then have 1: "s \<rightarrow>\<parallel>b ((x' \<leftrightarrow> x) \<bullet> t2)" using pbeta.eqvt by (metis Abs1_eq_iff(3) Nominal2_Base.swap_self add_flip_cancel flip_commute flip_def permute_flip_cancel2 permute_plus)
    from goal1 have 2: "(x' \<leftrightarrow> x) \<bullet> s' = Lam [x]. ((x' \<leftrightarrow> x) \<bullet> t2)" by simp
    from goal1 have "atom x \<sharp> (Lam [x']. t2)"  using fresh_in_pbeta by (meson lam.fresh(3) list.set_intros(1))
    with 2 have "s' = Lam [x]. ((x' \<leftrightarrow> x) \<bullet> t2)" unfolding goal1 by (metis "2" flip_fresh_fresh goal1(3) lam.fresh(3) list.set_intros(1))
    with 1 show ?case by auto
qed

thm pbeta.cases
lemma pbeta_cases_2:
  shows "atom x \<sharp> t \<Longrightarrow> App (Lam [x]. s) t \<rightarrow>\<parallel>b a2 \<Longrightarrow> 
    (\<And>s' t'. a2 = App (Lam [x]. s') t' \<Longrightarrow> atom x \<sharp> t' \<Longrightarrow> s \<rightarrow>\<parallel>b s' \<Longrightarrow> t \<rightarrow>\<parallel>b t' \<Longrightarrow> P) \<Longrightarrow>
    (\<And>t' s'. a2 = s' [x ::= t'] \<Longrightarrow> atom x \<sharp> t' \<Longrightarrow> atom x \<sharp> t \<Longrightarrow> s \<rightarrow>\<parallel>b s' \<Longrightarrow> t \<rightarrow>\<parallel>b t' \<Longrightarrow> P) \<Longrightarrow> P"
apply atomize_elim
proof (cases "App (Lam [x]. s) t" a2 rule:pbeta.cases, simp)
case goal1 
  then obtain s'' where 1: "s' = Lam [x]. s''" "s \<rightarrow>\<parallel>b s''" using aaaaa2 by blast
  thus ?case using goal1 fresh_in_pbeta  by auto
next
case (goal2 xx _ ss)
  have 1: "s' [xx ::= t'] = ((x \<leftrightarrow> xx) \<bullet> s') [x ::= t']"
    by (metis (no_types, lifting) Abs1_eq_iff(3) Nominal2_Base.swap_self add_flip_cancel flip_def fresh_in_pbeta goal2(3) goal2(7) permute_flip_cancel permute_plus subst_rename) 
  from goal2 have 2: "s \<rightarrow>\<parallel>b ((x \<leftrightarrow> xx) \<bullet> s')"
    by (metis Abs1_eq_iff(3) Nominal2_Base.swap_self add_flip_cancel flip_def pbeta.eqvt permute_flip_cancel permute_plus)
  from goal2 have 3: "atom x \<sharp> t'" using fresh_in_pbeta by simp
  with goal2 1 2 show ?case by auto
qed


lemma pbeta_max_closes_pbeta:
  fixes a b d
  assumes "a >>> d"
  and "a \<rightarrow>\<parallel>b b"
  shows "b \<rightarrow>\<parallel>b d"
using assms proof (nominal_induct arbitrary: b rule:pbeta_max.strong_induct)
case (cd_refl a)  
  show ?case using cd_refl pbeta.cases by fastforce
next
case (cd_beta u ard ar al ald)
  from cd_beta(2,7) show ?case
  apply (rule_tac pbeta_cases_2)
  apply (simp, simp)
  proof -
  case (goal2 arb alb)
    with cd_beta have "alb \<rightarrow>\<parallel>b ald" "arb \<rightarrow>\<parallel>b ard" by simp+
    thus ?case unfolding goal2 apply (rule_tac Lem2_5_1) by simp+
  next
  case (goal1 alb arb)
    with cd_beta have ih: "alb \<rightarrow>\<parallel>b ald" "arb \<rightarrow>\<parallel>b ard" by simp+
    show ?case unfolding goal1 
    apply (rule_tac pbeta.p_beta) using goal1 cd_beta ih
    by simp_all
  qed
next
case (cd_app al ald ar ard) 
  from cd_app(6,1) show ?case
  apply (cases "App al ar" b rule:pbeta.cases)
  defer
  apply simp
  using cd_app by auto
next
case (cd_abs al ald x) thus ?case using aaaaa2 by blast
qed


lemma Lem2_5_2: 
  assumes "a \<rightarrow>\<parallel>b b"
      and "a \<rightarrow>\<parallel>b c"
    shows "\<exists>d. b \<rightarrow>\<parallel>b d \<and> c \<rightarrow>\<parallel>b d"
proof -
  obtain d where 1: "a >>> d" using pbeta_max_ex by auto
  have "b \<rightarrow>\<parallel>b d \<and> c \<rightarrow>\<parallel>b d" 
  apply rule 
  apply (rule_tac pbeta_max_closes_pbeta)
  using 1 assms apply simp+
  apply (rule_tac pbeta_max_closes_pbeta)
  using 1 assms apply simp+
  done
  thus ?thesis by auto
qed


inductive beta_c :: "lam \<Rightarrow> lam \<Rightarrow> bool" ("_ \<longrightarrow>b* _" [80,80] 80)
where
  base[intro]: "a \<longrightarrow>b b \<Longrightarrow> a \<longrightarrow>b* b"
| refl[intro]: "a \<longrightarrow>b* a"
| trans[intro]: "\<lbrakk> a \<longrightarrow>b* b ; b \<longrightarrow>b* c \<rbrakk> \<Longrightarrow> a \<longrightarrow>b* c"


inductive pbeta_c :: "lam \<Rightarrow> lam \<Rightarrow> bool" ("_ \<rightarrow>\<parallel>b* _" [80,80] 80)
where
  base[intro]: "a \<rightarrow>\<parallel>b b \<Longrightarrow> a \<rightarrow>\<parallel>b* b"
| refl[intro]: "a \<rightarrow>\<parallel>b* a"
| trans[intro]: "\<lbrakk> a \<rightarrow>\<parallel>b* b ; b \<rightarrow>\<parallel>b* c \<rbrakk> \<Longrightarrow> a \<rightarrow>\<parallel>b* c"


definition DP :: "(lam \<Rightarrow> lam \<Rightarrow> bool) \<Rightarrow> (lam \<Rightarrow> lam \<Rightarrow> bool) \<Rightarrow> bool" where
"DP R T = (\<forall>a b c. R a b \<and> T a c \<longrightarrow> (\<exists>d. T b d \<and> R c d))"

lemma DP_R_R_imp_DP_R_Rc_pbeta:
  assumes "DP pbeta pbeta"
    shows "DP pbeta pbeta_c"
using assms unfolding DP_def
apply auto
proof -
case goal1 
  from goal1(3,2) show ?case
  apply (induct arbitrary: b rule:pbeta_c.induct)
  using goal1(1) by blast+
qed

lemma DP_R_R_imp_DP_Rc_Rc_pbeta:
  assumes "DP pbeta pbeta"
    shows "DP pbeta_c pbeta_c"
using assms unfolding DP_def
apply auto
proof -
case goal1 
  from goal1(2,3) show ?case
  apply (induct arbitrary: c rule:pbeta_c.induct)
  using DP_R_R_imp_DP_R_Rc_pbeta using DP_def assms apply fastforce
  apply auto
  by blast
qed

lemma M1: "m \<longrightarrow>b* m' \<Longrightarrow> m \<rightarrow>\<parallel>b* m'" sorry
lemma M2: "m \<rightarrow>\<parallel>b* m' \<Longrightarrow> m \<longrightarrow>b* m'"
proof (nominal_induct m avoiding: m' rule:lam.strong_induct)
print_cases
case (Var x) thus ?case 
  apply (cases rule:pbeta_c.cases)
  apply (cases "Var x" m' rule:pbeta.cases)
  apply simp 
  apply auto
  proof -
  case goal1 from goal1(1,2) show ?case sorry
  qed
next
case (App p q) from App(3) show ?case
  apply (cases rule:pbeta_c.cases)
defer
apply auto[1]
defer
  apply (cases "App p q" m' rule:pbeta.cases)
  apply auto[1]
  apply auto[1]
  sorry
next
case (Lam x p p') thus ?case sorry
qed



lemma church_rosser:
  assumes "a \<longrightarrow>b* b"
      and "a \<longrightarrow>b* c"
    shows "\<exists>d. b \<longrightarrow>b* d \<and> c \<longrightarrow>b* d"
proof -
  from assms have "a \<rightarrow>\<parallel>b* b" "a \<rightarrow>\<parallel>b* c" using M1 by simp+
  then obtain d where "b \<rightarrow>\<parallel>b* d" "c \<rightarrow>\<parallel>b* d" by (metis DP_R_R_imp_DP_Rc_Rc_pbeta DP_def Lem2_5_2) 
  thus ?thesis using M2 by blast
qed

end

