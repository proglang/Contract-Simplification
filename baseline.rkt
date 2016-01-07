#lang racket
(require redex)

(require "lj.rkt")
(require "lcon.rkt")
(require "contracts.rkt")

(provide (all-defined-out))

#|
 ___          _                           _ 
/ __|_  _ _ _| |_ __ ___ __  __ _ _ _  __| |
\__ \ || | ' \  _/ _` \ \ / / _` | ' \/ _` |
|___/\_, |_||_\__\__,_/_\_\ \__,_|_||_\__,_|
     |__/                                   
 ___                     _   _      ___                 _         
/ __| ___ _ __  __ _ _ _| |_(_)__  |   \ ___ _ __  __ _(_)_ _  ___
\__ \/ -_) '  \/ _` | ' \  _| / _| | |) / _ \ '  \/ _` | | ' \(_-<
|___/\___|_|_|_\__,_|_||_\__|_\__| |___/\___/_|_|_\__,_|_|_||_/__/
                                                                  
|#

(define-extended-language λCon-Baseline λCon

  ;; Final Terms
  ;; Final terms are all non-reducible terms,
  ;; e.g. Immediate Contracts in variables (x @ (flat M))
  ((S T) 
   ;; All term from λJ
   K x (λ x T) (S T) (op T ...)
   ;; Non-reducible contract assertions
   (x @ C) ((λ x M) @ Q))
 
  ;; TODO
  ;; why not using x@I in the definition?
  ;; Restrict Application in final terms to λJ exressions
  ;; thus uncontracted or x@C
  ;; (λ x M) @ Q) might be further redusable
  
  ;; Baseline Reduction Context
  ((G H) hole (λ x H) (op S ... H M ...) (H M) (S H) (H @ C))
)

(define 
  (done? M)
  (redex-match? λCon-Baseline M))

#|
 ___        _         _   _          
| _ \___ __| |_  _ __| |_(_)___ _ _  
|   / -_) _` | || / _|  _| / _ \ ' \ 
|_|_\___\__,_|\_,_\__|\__|_\___/_||_|
                                     
|#

;; Baseline Reduction
;; Verifies all (immediate) contracts 
;; that can be check at compile time

(define Baseline-reduction
  (reduction-relation
   λCon-Baseline
   
   (--> (in-hole H (V @ I))
        (in-hole H ,(car (apply-reduction-relation* λCon-reduction (term (V @ I)))))
        "Verify"
   )
   
   (--> (in-hole H (K @ Q))
        (in-hole H K)
        "Skip"
   )
))

;; Function unroll : x Q M -> N
;; Unrolls a delayed contract Q of function x 
;; to all uses of x

(define-metafunction λCon-Baseline
  unroll : x Q M -> N
  
  ;; Don't continue if x is bound λ's body
  [(unroll x Q (λ x M)) (λ x M)]
  
  ;; Continue unrollong on λ's body
  [(unroll x Q (λ y M)) (λ y (unroll x Q M))]
  
  ;; Put contract to the usage of x
  [(unroll x Q x) (x @ Q)]

  ;; Continue unrollong on the structure of M
  [(unroll x Q (any ...)) ((unroll x Q any) ...)]
  
  ;; Return the target expression M if
  ;; none of the previous rules match
  [(unroll x Q any) any]
)

(define Baseline-reduction2
  (extend-reduction-relation Baseline-reduction
   λCon-Baseline
   
   ;; Unroll
   (--> (in-hole H ((λ x M) ((λ y N) @ Q)))
        (in-hole H ((λ x (unroll x Q M)) (λ y N)))
        "Unroll"
   )
   
   ;; Unfold
   (--> (in-hole H ((M @ (C → D)) N))
        (in-hole H ((M (N @ C)) @ D))
        "Unfold-Function"
   )
   (--> (in-hole H ((M @ (Q ∩ R)) N))
        (in-hole H (((M @ Q) @ R) N))
        "Unfold-Intersection"
   )
   
   ;; TODO
   ;; collaps argument contarcts, because teh arg may be used several times
   ;; Move/ Propagate
   
   ;; Lift
   (--> (in-hole H (λ x (S @ C)))
        (in-hole H ((λ x S) @ (,Any? → C)))
        "Lift-Range?"
   )
))



(traces 
 Baseline-reduction2
 (term
  ((λ f (f 1)) ((λ x (+ x 1)) @ (,Num? → ,Num?)))))


(test-->
 Baseline-reduction2
 (term
  ((λ f (f 1)) ((λ x (+ x 1)) @ (,Num? → ,Num?))))
 (term
  ((λ f ((f @ (,Num? → ,Num?)) 1)) (λ x (+ x 1)))))

;(test-->>
; Sugar-reduction
; (term
;  ((λ f (f 1)) ((λ x (+ x 1)) @ (,Num → ,Num))))
; (term
;  ((λ f ((f 1) @ ,Num)) (λ x (+ x 1)))))

(test-->>
 Baseline-reduction2
 (term
  ((λ f (f 1)) ((λ x (+ x 1)) @ (,Num? → ,Num?))))
 (term
  (((λ f (f 1)) (λ x (+ x 1))) @ ,Num?)))















;; TODO
;; write a test that checks if all terms from S are also M
;; every  is also an λCon-term







