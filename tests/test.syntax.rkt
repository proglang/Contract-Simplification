#lang racket
(require redex)
(require rackunit)

(require "../lcon.rkt")
(require "../baseline.rkt")
 

;(define canonical? (redex-match λCon-Baseline T))
;(define reducible? (redex-match λCon-Baseline Reducible))

;; xor ?


;; Test Syntax
;; -----------
;; Each source term is either reducible or in a canonical form (non-reducible).

(define (syntax-ok? M) (xor (canonical? M) (reducible? M)))

(define xterm
(redex-check λCon-Baseline M (syntax-ok? (term M)) #:print? "a"	#:attempts 10000000)
)

;; Manual Test
;; -----------

(define (print-result M) (string-append "canonical? " (format "~a" (canonical? M)) " - " "reducible? " (format "~a" (reducible? M))))
;(redex-match? λCon M (term (λ x (+ (x @ ι Number?) 1))))
;(print-result (term 
;              ((if (0 @ ιe ⊥) 1 hR) @ ιL (hq ↦ (Λ fT ⊥)))
;               ))

(print-result xterm)