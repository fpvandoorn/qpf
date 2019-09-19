/-
Copyright (c) 2018 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Jeremy Avigad

Polynomial functors. Also expresses the W-type construction as a polynomial functor.
(For the M-type construction, see Mtype.lean.)
-/
import tactic.interactive data.multiset families.pfunctor.family for_mathlib
universe u

/- TODO (Jeremy): move this. -/

namespace fam

variables {I J : Type u} {F : fam I ⥤ fam J}

def Pred (α : fam I) : Sort* := ∀ i, α i → Prop

@[reducible]
def subtype {α : fam I} (p : Pred α) : fam I :=
λ i, subtype (p i)

def subtype.val {α : fam I} (p : Pred α) : fam.subtype p ⟶ α :=
λ i, subtype.val

def prod (α β : fam I) : fam I
| i := α i × β i

infix ` ⊗ `:35 := prod

def prod.fst : Π {α β : fam I}, α ⊗ β ⟶ α
| α β i x := _root_.prod.fst x

def prod.snd : Π {α β : fam I}, α ⊗ β ⟶ β
| α β i x := _root_.prod.snd x

def prod.map {α β α' β' : fam I} : (α ⟶ β) → (α' ⟶ β') → (α ⊗ α' ⟶ β ⊗ β')
| f g i x := (f x.1,g x.2)

infix ` ⊗ `:35 := prod.map

def diag : Π {α : fam I}, α ⟶ α ⊗ α
| α i x := (x,x)

end fam

namespace pfunctor

variables {I J : Type u} {F G : fam I ⥤ fam J}

def liftp {α : fam I} (p : fam.Pred α) {X : fam J} : (X ⟶ F.obj α) → Prop :=
λ x, ∃ u : X ⟶ F.obj (fam.subtype p), u ≫ F.map (fam.subtype.val p) = x

def liftr {α β : fam I} (r : fam.Pred (α ⊗ β)) {X : fam J} : (X ⟶ F.obj α) → (X ⟶ F.obj β) → Prop :=
λ x y, ∃ u : X ⟶ F.obj (fam.subtype r),
  u ≫ F.map (fam.subtype.val _ ≫ fam.prod.fst) = x ∧
  u ≫ F.map (fam.subtype.val _ ≫ fam.prod.snd) = y

def supp {α : fam I} {X : fam J} (x : X ⟶ F.obj α) : set (sigma α) := { y : sigma α | ∀ ⦃p⦄, liftp p x → p _ y.2 }

theorem of_mem_supp {α : fam I} {X : fam J} {x : X ⟶ F.obj α} {p : fam.Pred α} (h : liftp p x) :
  ∀ y ∈ supp x, p _ (sigma.snd y) :=
λ y hy, hy h

open category_theory

lemma liftp_comp {α : fam I} {X : fam J} {p : Π i, α i → Prop}
  (x : X ⟶ F.obj α) (h : F ⟶ G) :
  liftp p x → liftp p (x ≫ h.app _)
| ⟨u,h'⟩ := ⟨u ≫ nat_trans.app h _, by rw ← h'; simp,⟩

lemma liftp_comp' {α : fam I} {X : fam J} {p : Π i, α i → Prop}
  (x : X ⟶ F.obj α) (T : F ⟶ G) (T' : G ⟶ F)
  (h_inv : ∀ {α}, T.app α ≫ T'.app α = 𝟙 _):
  liftp p x ↔ liftp p (x ≫ T.app _) :=
-- | ⟨u,h'⟩ :=
⟨ liftp_comp x T,
 λ ⟨u,h'⟩, ⟨u ≫ T'.app _,by rw [category.assoc,← nat_trans.naturality,← category.assoc,h',category.assoc,h_inv,category.comp_id]⟩ ⟩

lemma liftr_comp {α : fam I} {X : fam J} (p : fam.Pred (α ⊗ α)) (x y : X ⟶ F.obj α)
   (T : F ⟶ G) :
  liftr p x y → liftr p (x ≫ T.app _) (y ≫ T.app _)
| ⟨u,h,h'⟩ := ⟨u ≫ T.app _, by { rw ← h'; simp, }⟩

end pfunctor

/-
A polynomial functor `P` is given by a type `A` and a family `B` of types over `A`. `P` maps
any type `α` to a new type `P.apply α`.

An element of `P.apply α` is a pair `⟨a, f⟩`, where `a` is an element of a type `A` and
`f : B a → α`. Think of `a` as the shape of the object and `f` as an index to the relevant
elements of `α`.
-/

structure pfunctor (I J : Type u) :=
(A : J → Type u) (B : Π i, A i → fam I)

namespace pfunctor

variables {I J : Type u} {α β : Type u}

section pfunc
variables (P : pfunctor I J)

-- TODO: generalize to psigma?
def apply : fam I ⥤ fam J :=
{ obj := λ X i, Σ a : P.A i, P.B i a ⟶ X,
  map := λ X Y f i ⟨a,g⟩, ⟨a, g ≫ f⟩ }

def obj := P.apply.obj
def map {X Y : fam I} (f : X ⟶ Y) : P.obj X ⟶ P.obj Y := P.apply.map f

lemma map_id {X : fam I} : P.map (𝟙 X) = 𝟙 _ :=
category_theory.functor.map_id _ _

lemma map_comp {X Y Z : fam I} (f : X ⟶ Y) (g : Y ⟶ Z) : P.map (f ≫ g) = P.map f ≫ P.map g :=
category_theory.functor.map_comp _ _ _

theorem map_eq {α β : fam I} (f : α ⟶ β) {i : J} (a : P.A i) (g : P.B i a ⟶ α) :
  P.map f ⟨a, g⟩ = ⟨a, g ≫ f⟩ :=
rfl

def Idx (i : J) := Σ (x : P.A i) j, P.B i x j

section
variables {P}
def Idx.idx {i : J} (x : Idx P i) : I := x.2.1
end

def obj.iget {i} [decidable_eq $ P.A i] {α : fam I} (x : P.obj α i) (j : P.Idx i) [inhabited $ α j.2.1] : α j.2.1 :=
if h : j.1 = x.1
  then x.2 (cast (by rw ← h) $ j.2.2)
  else default _

end pfunc

variables (P : pfunctor I I)

-- theorem id_map {α : Type*} : ∀ x : P.apply α, id <$> x = id x :=
-- λ ⟨a, b⟩, rfl

-- theorem comp_map {α β γ : Type*} (f : α → β) (g : β → γ) :
--   ∀ x : P.apply α, (g ∘ f) <$> x = g <$> (f <$> x) :=
-- λ ⟨a, b⟩, rfl

-- instance : is_lawful_functor P.apply :=
-- {id_map := @id_map P, comp_map := @comp_map P}

inductive W : I → Type u
-- | mk {i : I} (a : P.A i) (f : ∀ j : I, P.B i a j → W j) : W i
| mk {i : I} (a : P.A i) (f : P.B i a ⟶ W) : W i

-- inductive W' : I -> Type u
-- | mk {a : A} : (∀ k : K a, W' (f a k)) → W' (g a)

def W_dest (P : pfunctor I I) {i} : W P i → P.obj (W P) i
| ⟨a, f⟩ := ⟨a, f⟩

def W_mk {i} : P.obj (W P) i → W P i
| ⟨a, f⟩ := ⟨a, f⟩

@[simp] theorem W_dest_W_mk {i} (p : P.obj (W P) i) : P.W_dest (P.W_mk p) = p :=
by cases p; reflexivity

@[simp] theorem W_mk_W_dest {i} (p : W P i) : P.W_mk (P.W_dest p) = p :=
by cases p; reflexivity

variables {P}

-- theorem Wp_ind {α : fam I} {C : Π i (x : P.A i), (P.B i x ⟶ α) → Prop}
--   (ih : ∀ i (a : P.A i) (f : P.B i a ⟶ P.W)
--     (f' : P.B i a ⟶ α),
--       (∀ j (x : P.B _ a j), C j ((f : Π j, P.B i a j → P.W j) x) x) → C i ⟨a, f⟩ f') :
--   Π i (x : P.last.W i) (f' : P.W_path x ⟶ α), C i x f'


-- @[simp]
-- lemma fst_map {α β : fam I} (x : P.apply.obj α _) (f : α ⟶ β) :
--   (f <$> x).1 = x.1 := by { cases x; refl }

-- @[simp]
-- lemma iget_map [decidable_eq P.A] {α β : Type u} [inhabited α] [inhabited β]
--   (x : P.apply α) (f : α → β) (i : P.Idx)
--   (h : i.1 = x.1) :
--   (f <$> x).iget i = f (x.iget i) :=
-- by { simp [apply.iget],
--      rw [dif_pos h,dif_pos];
--      cases x, refl, rw h, refl }

end pfunctor

/-
Composition of polynomial functors.
-/

namespace pfunctor

/-
def comp : pfunctor.{u} → pfunctor.{u} → pfunctor.{u}
| ⟨A₂, B₂⟩ ⟨A₁, B₁⟩ := ⟨Σ a₂ : A₂, B₂ a₂ → A₁, λ ⟨a₂, a₁⟩, Σ u : B₂ a₂, B₁ (a₁ u)⟩
-/

variables {I J K : Type u} (P₂ : pfunctor.{u} J K) (P₁ : pfunctor.{u} I J)

def comp : pfunctor.{u} I K :=
⟨ λ i, Σ a₂ : P₂.1 i, P₂.2 _ a₂ ⟶ P₁.1,
-- ⟨ Σ a₂ : P₂.1 _, P₂.2 _ a₂ → P₁.1, ²
  λ k a₂a₁ i, Σ j (u : P₂.2 _ a₂a₁.1 j), P₁.2 _ (a₂a₁.2 u) i ⟩

def comp.mk {α : fam I} {k} (x : P₂.obj (P₁.obj α) k) : (comp P₂ P₁).obj α k :=
⟨ ⟨x.1,x.2 ≫ λ j, sigma.fst⟩, λ i a₂a₁, (x.2 _).2 a₂a₁.2.2 ⟩

def comp.get {α : fam I} {k} (x : (comp P₂ P₁).obj α k) : P₂.obj (P₁.obj α) k :=
⟨ x.1.1, λ j a₂, ⟨x.1.2 a₂, λ i a₁, x.2 ⟨j, a₂, a₁⟩⟩ ⟩

end pfunctor

/-
Lifting predicates and relations.
-/

namespace pfunctor
variables {I J : Type u} {P : pfunctor.{u} I J}
open functor

noncomputable def classical.indefinite_description' {α : Sort*} (p : α → Prop) (h : ∃ (x : α), p x) : psigma p :=
let ⟨x,h'⟩ := classical.indefinite_description p h in ⟨x,h'⟩

namespace tactic

open tactic .

meta def mk_constructive_aux : expr → expr → tactic expr
| e `(∃ x : %%t, %%b) :=
  do e ← mk_mapp ``classical.indefinite_description' [none,none,e],
     t ← infer_type e,
     mk_constructive_aux e t <|> pure e
| e `(@psigma %%α %%f) :=
  do id_f ← mk_mapp ``id [α],
     v ← mk_local_def `v α,
     f' ← head_beta $ f v,
     v' ← mk_local_def `v' f',
     fn ← mk_constructive_aux v' f',
     t ← infer_type fn >>= lambdas [v],
     fn ← lambdas [v,v'] fn,
     r ← mk_mapp ``psigma.map [α,α,f,t,id_f],
     pure $ r fn e
| e _ := failed

setup_tactic_parser

meta def mk_constructive (n : parse ident) : tactic unit :=
do h ← get_local n,
   (vs,t) ← infer_type h >>= mk_local_pis,
   e' ← mk_constructive_aux (h.mk_app vs) t,
   -- let e' := e.mk_app vs,
   e' ← lambdas vs e',
   note h.local_pp_name none e',
   clear h

meta def apply_symm (n : name) : tactic expr :=
do e ← mk_const n,
   (vs,t) ← infer_type e >>= mk_local_pis,
   e' ← mk_eq_symm $ e.mk_app vs,
   lambdas vs e'

meta def fold (ns : parse ident*) (ls : parse location) : tactic unit :=
do hs ← ns.mmap $ get_eqn_lemmas_for tt,
   hs ← hs.join.mmap apply_symm,
   (s,u) ← mk_simp_set tt [] (hs.map $ simp_arg_type.expr ∘ to_pexpr),
   ls.try_apply (λ h, () <$ simp_hyp s u h) (simp_target s u)
   -- simp_target s u

run_cmd add_interactive [``fold,``mk_constructive]

end tactic

@[simp]
lemma then_def {X Y Z : fam I} (f : X ⟶ Y) (g : Y ⟶ Z) {i} (x : X i) : (f ≫ g) x = g (f x) := rfl

theorem liftp_iff {α : fam I} {X : fam J} (p : Π i, α i → Prop) (x : X ⟶ P.obj α) :
  liftp p x ↔ ∀ j (y : X j), ∃ a f, x y = ⟨a, f⟩ ∧ ∀ i a, p i (f a) :=
begin
  split,
  { rintros ⟨y, hy⟩ j z, cases h : y z with a f,
    refine ⟨a, λ i a, subtype.val (f a), _, λ i a, subtype.property (f a)⟩, --, λ i, (f i).property⟩,
    fold pfunctor.map pfunctor.obj at *,
    simp [hy.symm, (≫), h, map_eq],
    simp [(∘),fam.subtype.val], },
  introv hv, dsimp [liftp],
  mk_constructive hv,
  let F₀ := λ j k, (hv j k).1,
  let F₁ : Π j k, P.B j (F₀ j k) ⟶ α := λ j k, (hv j k).2.1,
  have F₂ : ∀ j k, x k = ⟨F₀ j k,F₁ j k⟩ := λ j k, (hv j k).2.2.1,
  have F₃ : ∀ j k i a, p i (F₁ j k a) := λ j k, (hv j k).2.2.2,
  refine ⟨λ j x, ⟨F₀ j x,λ i y, ⟨F₁ j x y,F₃ j x i y⟩⟩,_⟩,
  ext : 2, dsimp, rw F₂, refl
end

theorem liftr_iff {α : fam I} (r : Π i, α i → α i → Prop) {X : fam J} (x y : X ⟶ P.obj α) :
  liftr r x y ↔ ∀ j (z : X j), ∃ a f₀ f₁, x z = ⟨a, f₀⟩ ∧ y z = ⟨a, f₁⟩ ∧ ∀ i a, r i (f₀ a) (f₁ a) :=
begin
  split,
  { rintros ⟨u, xeq, yeq⟩ j z, cases h : u z with a f,
    use [a, λ i b, (f b).val.fst, λ i b, (f b).val.snd],
    split, { rw [←xeq, then_def, h], refl },
    split, { rw [←yeq, then_def, h], refl },
    intros i a, exact (f a).property },
  rintros hv, dsimp [liftr],
  mk_constructive hv,
  let F₀ := λ j k, (hv j k).1,
  let F₁ : Π j k, P.B j (F₀ j k) ⟶ α := λ j k, (hv j k).2.1,
  let F₂ : Π j k, P.B j (F₀ j k) ⟶ α := λ j k, (hv j k).2.2.1,
  fold pfunctor.map,
  have F₃ : ∀ j k, x k = ⟨F₀ j k,F₁ j k⟩ := λ j k, (hv j k).2.2.2.1,
  have F₄ : ∀ j k, y k = ⟨F₀ j k,F₂ j k⟩ := λ j k, (hv j k).2.2.2.2.1,
  have F₅ : ∀ j k i a, r i (F₁ j k a) (F₂ j k a) := λ j k, (hv j k).2.2.2.2.2,
  refine ⟨λ j x, ⟨F₀ j x,λ i y, _⟩,_⟩,
  { refine ⟨(F₁ j x y,F₂ j x y),F₅ _ _ _ _⟩ },
  split; ext : 2; [rw F₃,rw F₄]; refl,
end

end pfunctor

/-
Facts about the general quotient needed to construct final coalgebras.

TODO (Jeremy): move these somewhere.
-/

namespace quot

def factor {α : Type*} (r s: α → α → Prop) (h : ∀ x y, r x y → s x y) :
  quot r → quot s :=
quot.lift (quot.mk s) (λ x y rxy, quot.sound (h x y rxy))

def factor_mk_eq {α : Type*} (r s: α → α → Prop) (h : ∀ x y, r x y → s x y) :
  factor r s h ∘ quot.mk _= quot.mk _ := rfl

end quot
