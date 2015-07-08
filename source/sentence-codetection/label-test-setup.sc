
(start-matlab!)
(matlab "load('~/codetection/source/sentence-codetection/asm_20150702.mat')")
(define asm (matlab-get-variable "avg_similarity_matrix"))
(define asm-g (matrix->list-of-lists asm))
(define g-c (easy-ffi:double-to-c 2 asm-g))
;; (define labels-c
;;  (list->c-exact-array (malloc (* c-sizeof-int (length asm-g)))
;; 		      (map-n (lambda _ 0) (length asm-g)) c-sizeof-int #t))

(define (test-labeling num-labels f-value default-g-value dummy-g-value)
 (let* ((labels-c
	 (list->c-exact-array (malloc (* c-sizeof-int (length asm-g)))
			      (map-n (lambda _ 0) (length asm-g)) c-sizeof-int #t))
	(test-score (bp-label-inference (length asm-g)
					num-labels
					f-value
					default-g-value
					g-c
					dummy-g-value
					labels-c))
	(labels (c-exact-array->list labels-c c-sizeof-int (length asm-g) #t)))
  (free labels-c)
  labels))

(define (positions v l)
 (let loop ((l l) (i 0))
  (let ((p (position v l)))
   (if p
       (cons (+ p i) (loop (list-remove l p) (+ i 1)))
       '()))))