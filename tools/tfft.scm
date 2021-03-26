(define times 1000)
(define size 1024)
 
(define (b_fft areal aimag)
  (let ((ar 0)
        (ai 0)
        (i 1)
        (j 1)
        (k 0)
        (m 0)
        (n 0)
        (le 1)
        (le1 0) (le2 0)
        (ip 0)
        (nv2 0)
        (nm1 0)
        (ur 0.0)
        (ui 0.0)
        (wr 0.0)
        (wi 0.0)
        (tr 0.0)
        (ti 0.0))
    ;; initialize
    (set! ar areal)
    (set! ai aimag)
    (set! n (length ar))
    (set! n (- n 1))
    (set! nv2 (quotient n 2))
    (set! nm1 (- n 1))
    
    (do ()
	((>= i n))
      (set! m (+ m 1))
      (set! i (+ i i)))
    (set! i 1)
    
    (do ()
	((>= i n))
      (when (< i j)
	(set! tr (float-vector-ref ar j))
	(set! ti (float-vector-ref ai j))
	(float-vector-set! ar j (float-vector-ref ar i))
	(float-vector-set! ai j (float-vector-ref ai i))
	(float-vector-set! ar i tr)
	(float-vector-set! ai i ti))
      (set! k nv2)
      (do ()
	  ((>= k j))
	(set! j (- j k))
	(set! k (quotient k 2)))
      
      (set! j (+ j k))
      (set! i (+ i 1)))
    
    (do ((l 1 (+ l 1)))
        ((> l m))  
      (set! le1 le)
      (set! le2 (+ le 1))
      (set! le (* le 2))
      (set! ur 1.0)
      (set! ui 0.)
      (set! wr (cos (/ pi le1)))
      (set! wi (sin (/ pi le1)))
      (do ((j1 1 (+ j1 1)))
	  ((= j1 le2))
	(do ((i1 j1 (+ i1 le)))
	    ((> i1 n))
	  (set! ip (+ i1 le1))
	  (set! tr (- (* (float-vector-ref ar ip) ur)
		      (* (float-vector-ref ai ip) ui)))
	  (set! ti (+ (* (float-vector-ref ar ip) ui)
		      (* (float-vector-ref ai ip) ur)))
	  (float-vector-set! ar ip (- (float-vector-ref ar i1) tr))
	  (float-vector-set! ai ip (- (float-vector-ref ai i1) ti))
	  (float-vector-set! ar i1 (+ (float-vector-ref ar i1) tr))
	  (float-vector-set! ai i1 (+ (float-vector-ref ai i1) ti))))
      (set! tr (- (* ur wr) (* ui wi)))
      (set! ti (+ (* ur wi) (* ui wr)))
      (set! ur tr)
      (set! ui ti))
    #t))
 
(if (not (defined? 'complex))
  (define complex make-rectangular))
(if (not (defined? 'when))
  (define-macro (when test . body) `(if ,test (begin ,@body))))

(define* (cfft data n (dir 1)) ; complex data
  (unless n (set! n (length data)))
  (do ((i 0 (+ i 1))
       (j 0))
      ((= i n))
    (if (> j i)
	(let ((temp (data j)))
	  (set! (data j) (data i))
	  (set! (data i) temp)))
    (do ((m (/ n 2) (/ m 2)))
        ((or (< m 2) 
             (< j m))
         (set! j (+ j m)))
     (set! j (- j m))))
  (do ((ipow (floor (log n 2)))
       (prev 1)
       (lg 0 (+ lg 1))
       (mmax 2 (* mmax 2))
       (pow (/ n 2) (/ pow 2))
       (theta (complex 0.0 (* pi dir)) (* theta 0.5)))
      ((= lg ipow))
    (do ((wpc (exp theta))
         (wc 1.0)
         (ii 0 (+ ii 1)))
	((= ii prev)
	 (set! prev mmax))
      (do ((jj 0 (+ jj 1))
           (i ii (+ i mmax))
           (j (+ ii prev) (+ j mmax)))
          ((>= jj pow))
        (let ((tc (* wc (data j))))
          (set! (data j) (- (data i) tc))
          (set! (data i) (+ (data i) tc))))
      (set! wc (* wc wpc))))
  data)

(when (defined? 'equivalent?)
  (unless (equivalent? (cfft (vector 0.0 1+i 0.0 0.0)) #(1+1i -1+1i -1-1i 1-1i))
    (format *stderr* "cfft 1: ~S~%" (cfft (vector 0.0 1+i 0.0 0.0))))
  (let-temporarily (((*s7* 'equivalent-float-epsilon) 1e-14))
    (unless (equivalent? (cfft (vector 0 0 1+i 0 0 0 1-i 0)) #(2 -2 -2 2 2 -2 -2 2))
      (format *stderr* "cfft 2: ~S~%" (cfft (vector 0 0 1+i 0 0 0 1-i 0))))))

(define (fft-bench)
  (let ((*re* (make-float-vector (+ size 1) 0.10))
	(*im* (make-float-vector (+ size 1) 0.10)))
    (do ((ntimes 0 (+ ntimes 1)))
	((= ntimes times))
      (b_fft *re* *im*)))

  (let* ((n 256)
	 (cdata (make-vector n 0.0)))
    (do ((i 0 (+ i 1)))
	((= i times))
      (fill! cdata 0.0)
      (vector-set! cdata 2 1+i)
      (vector-set! cdata (- n 1) 1-i)
      (cfft cdata))))
 
(fft-bench)

;; 2D dft, real data, spot-checked against fftw ("backward", for "forward" case, use (- (im yout xout)...))
(define (dft2 in)
  (let* ((dims (vector-dimensions in))
         (h (car dims))
         (w (cadr dims))
	 (ih (/ 1.0 h))
	 (iw (/ 1.0 w))
         (rl (make-float-vector dims 0.0))
         (im (make-float-vector dims 0.0))
	 (out (make-float-vector dims)))
    (do ((yout 0 (+ yout 1)))
        ((= yout h) 
	 (do ((i 0 (+ i 1)))
	     ((= i h) 
	      out)
	   (do ((j 0 (+ j 1)))
	       ((= j w))
	     (set! (out i j) (+ (* (rl i j) (rl i j)) 
				(* (im i j) (im i j)))))))
      (do ((xout 0 (+ xout 1)))
          ((= xout w))
        (do ((yin 0 (+ yin 1)))
            ((= yin h))
          (do ((xin 0 (+ xin 1)))
              ((= xin w))
            (set! (rl yout xout) (+ (rl yout xout) 
				    (* (in yin xin) 
				       (cos (* 2 pi (+ (* xout xin iw) 
						       (* yout yin ih)))))))
            (set! (im yout xout) (+ (im yout xout) 
				    (* (in yin xin) 
				       (sin (* 2 pi (+ (* xout xin iw) 
						       (* yout yin ih)))))))))))))
#|
(dft2 #2d((1.0 0.0 -1.0 0.0)
	  (0.0 0.0 0.0 0.0)
	  (0.0 1.0 0.0 0.0)
	  (0.0 0.0 0.0 0.0)))
|#
(define (test-dft2)
  (let ((mat (make-vector '(16 16) 0.0)))
    (set! (mat 0 8) 1.0)
    (dft2 mat)
    (fill! mat 0.0)
    (set! (mat 0 0) 1.0)
    (set! (mat 8 8) 1.0)
    (dft2 mat)))

(test-dft2)


(when (> (*s7* 'profile) 0)
  (show-profile 200))
(exit)
