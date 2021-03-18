;;; gsl cload timing tests

(require libgsl.scm)
(require libm.scm)

(define libgsl:jn (*libgsl* 'gsl_sf_bessel_Jn))
(define libm:jn (*libm* 'jn))

(define (fm-cascade-component-m freq-we-want wc wm1 a wm2 b)
  (let ((sum 0.0)
	(mxa (ceiling (* 7 a)))
	(mxb (ceiling (* 7 b))))
    (do ((k (- mxa) (+ k 1)))
	((>= k mxa))
      (do ((j (- mxb) (+ j 1)))
	  ((>= j mxb))
	(set! sum (+ sum (* (libm:jn k a)
			    (libm:jn j (* k b)))))))
	      
    sum))

(define (fm-cascade-component-g freq-we-want wc wm1 a wm2 b)
  (let ((sum 0.0)
	(mxa (ceiling (* 7 a)))
	(mxb (ceiling (* 7 b))))
    (do ((k (- mxa) (+ k 1)))
	((>= k mxa))
      (do ((j (- mxb) (+ j 1)))
	  ((>= j mxb))
	(set! sum (+ sum (* (libgsl:jn k a) ; we want d_id here not d_dd
			    (libgsl:jn j (* k b)))))))
	      
    sum))


(format *stderr* "~A ~A~%" (fm-cascade-component-m 2000 2000 500 1.5 50 1.0) (fm-cascade-component-g 2000 2000 500 1.5 50 1.0))

(define (testfm)
  (do ((i 0 (+ i 1)))
      ((= i 1000))
    (fm-cascade-component-m 2000 2000 500 1.5 50 1.0)
    (fm-cascade-component-g 2000 2000 500 1.5 50 1.0)))

(testfm)

(define (immutable-let L)
  (with-let L 
    (for-each (lambda (f)
                (immutable! (car f)))
              (curlet)))
  L)

(with-let (sublet (immutable-let *libgsl*))
  
  (define (eigenvalues M)
    (with-let (sublet *libgsl* (inlet 'M M))
      (let* ((len (sqrt (length M)))
	     (gm (gsl_matrix_alloc len len))
	     (m (float-vector->gsl_matrix M gm))
	     (evl (gsl_vector_complex_alloc len))
	     (evc (gsl_matrix_complex_alloc len len))
	     (w (gsl_eigen_nonsymmv_alloc len)))
	
	(gsl_eigen_nonsymmv m evl evc w)
	(gsl_eigen_nonsymmv_free w)
	(gsl_eigen_nonsymmv_sort evl evc GSL_EIGEN_SORT_ABS_DESC)
	
	(let ((vals (make-vector len)))
	  (do ((i 0 (+ i 1)))
	      ((= i len))
	    (set! (vals i) (gsl_vector_complex_get evl i)))
	  (gsl_matrix_free gm)
	  (gsl_vector_complex_free evl)
	  (gsl_matrix_complex_free evc)
	  vals))))
  
  (format *stderr* "~S #(4.0 2.0)~%" (eigenvalues (float-vector 3 1 1 3)))

  (define (testla)
    (do ((i 0 (+ i 1)))
	((= i 30000))
      (eigenvalues (float-vector 1 2 4 3))))

  (testla)

  (define (num-test expr result)
    expr)
  (define (test expr result)
    expr)

  (define (testrst)
    (do ((i 0 (+ i 1)))
	((= i 3000))
      (num-test (gsl_sf_airy_Ai -500.0 GSL_MODE_DEFAULT) 0.07259012010418163)
      (num-test (gsl_sf_airy_Bi -500.0 GSL_MODE_DEFAULT) -0.0946885701328829)
      (num-test (gsl_sf_airy_Ai_scaled -5.0 GSL_MODE_DEFAULT) 0.3507610090241141)
      (num-test (gsl_sf_airy_Bi_scaled -5.0 GSL_MODE_DEFAULT) -0.1383691349016009)
      (num-test (gsl_sf_airy_Ai_deriv -5.0 GSL_MODE_DEFAULT) 0.3271928185544435)
      (num-test (gsl_sf_airy_Bi_deriv -5.0 GSL_MODE_DEFAULT) 0.778411773001899)
      (num-test (gsl_sf_airy_Ai_deriv_scaled -5.0 GSL_MODE_DEFAULT) 0.3271928185544435)
      (num-test (gsl_sf_airy_Bi_deriv_scaled -5.0 GSL_MODE_DEFAULT) 0.778411773001899)
      (num-test (gsl_sf_airy_zero_Ai_deriv 2) -3.248197582179837)
      (num-test (gsl_sf_airy_zero_Bi_deriv 2) -4.073155089071828)
      (num-test (gsl_sf_bessel_J0 1.0) 0.7651976865579666)
      (num-test (let ((sfr (gsl_sf_result.make))) (gsl_sf_bessel_J0_e 1.0 sfr) (gsl_sf_result.val sfr)) 0.7651976865579666)
      (num-test (let ((sfr (gsl_sf_result.make))) (gsl_sf_bessel_J0_e 1.0 sfr) (gsl_sf_result.err sfr)) 6.72613016567227e-16)
      (num-test (gsl_sf_bessel_J0 .1) 0.9975015620660401)
      (num-test (gsl_sf_bessel_J1 .1) 0.049937526036242)
      (num-test (gsl_sf_bessel_Jn 45 900.0) 0.02562434700634277)
      (num-test (gsl_sf_bessel_Y0 .1) -1.534238651350367)
      (num-test (gsl_sf_bessel_Y1 .1) -6.458951094702027)
      (num-test (gsl_sf_bessel_Yn 4 .1) -305832.2979335312)
      (num-test (gsl_sf_bessel_I0_scaled .1) 0.9071009257823011)
      (num-test (gsl_sf_bessel_I1_scaled .1) 0.04529844680880932)
      (num-test (gsl_sf_bessel_In_scaled 4 .1) 2.35752586200546e-07)
      (num-test (gsl_sf_bessel_I0 .1) 1.002501562934096)
      (num-test (gsl_sf_bessel_I1 .1) 0.05006252604709269)
      (num-test (gsl_sf_bessel_In 4 .1) 2.605469021299657e-07)
      (num-test (gsl_sf_bessel_K0_scaled .1) 2.682326102262894)
      (num-test (gsl_sf_bessel_K1_scaled .1) 10.8901826830497)
      (num-test (gsl_sf_bessel_Kn_scaled 4 .1) 530040.2483725621)
      (num-test (gsl_sf_bessel_K0 .1) 2.427069024702016)
      (num-test (gsl_sf_bessel_K1 .1) 9.853844780870606)
      (num-test (gsl_sf_bessel_Kn 4 .1) 479600.2497925678)
      (num-test (gsl_sf_bessel_j0 1.0) 0.8414709848078965)
      (num-test (gsl_sf_bessel_j1 1.0) 0.3011686789397567)
      (num-test (gsl_sf_bessel_j2 1.0) 0.06203505201137386)
      (num-test (gsl_sf_bessel_jl 5 1.0) 9.256115861125814e-05)
      (num-test (gsl_sf_bessel_zero_J0 1) 2.404825557695771)
      (num-test (gsl_sf_bessel_zero_Jnu 5 5) 22.21779994656127)
      (num-test (gsl_sf_hydrogenicR_1 3 2) 0.02575994825614847)
      (num-test (gsl_sf_dilog -3.0) -1.939375420766708)
      (let ((s1 (gsl_sf_result.make))
	    (s2 (gsl_sf_result.make)))
	(gsl_sf_complex_dilog_e 0.99999 (/ pi 2) s1 s2)
	(num-test (gsl_sf_result.val s1) -0.2056132926277968)
	(num-test (gsl_sf_result.val s2) 0.9159577401813151))
      (let ((s1 (gsl_sf_result.make))
	    (s2 (gsl_sf_result.make)))
	(gsl_sf_complex_spence_xy_e 0.5 0.0 s1 s2)
	(num-test (gsl_sf_result.val s1) 0.5822405264650126)
	(num-test (gsl_sf_result.val s2) 0.0))
      (num-test (gsl_sf_lngamma -0.1) 2.368961332728787)
      (num-test (gsl_sf_gamma 9.0) 40320.0)
      (num-test (gsl_sf_gammastar 9.0) 1.009298426421819)
      (num-test (gsl_sf_gammainv -1.0) 0.0)
      (let ((s1 (gsl_sf_result.make))
	    (s2 (gsl_sf_result.make)))
	(gsl_sf_lngamma_complex_e 5.0 2.0 s1 s2)
	(num-test (gsl_sf_result.val s1) 2.748701756133804)
	(num-test (gsl_sf_result.val s2) 3.073843410049702))
      (num-test (gsl_sf_taylorcoeff 10 5) 2.691144455467373)
      (num-test (gsl_sf_choose 7 3) 35.0)
      (num-test (gsl_sf_poch 7 3) 504.0000000000001)
      (num-test (gsl_sf_gamma_inc_P 1.0 10.0) 0.9999546000702381)
      (num-test (gsl_sf_lnbeta 0.1 1.0) 2.302585092994044)
      (num-test (gsl_sf_beta 100.1 -1.2) 1203.895236907804)
      (num-test (gsl_sf_hyperg_0F1 1 0.5) 1.56608292975635)
      (num-test (gsl_sf_hyperg_1F1 1 1.5 1) 2.030078469278705)
      (num-test (gsl_sf_hyperg_U_int 100 100 1) 0.009998990209084679)
      (num-test (gsl_sf_hyperg_2F1 1 1 1 0.5) 2.0)
      (num-test (gsl_sf_legendre_P1 -0.5) -0.5)
      (num-test (gsl_sf_legendre_sphPlm 10 0 -0.5) -0.2433270236930014)
      (num-test (gsl_sf_legendre_Q0 -0.5) -0.5493061443340549)
      (num-test (gsl_sf_clausen (+ (* 2 pi) (/ pi 3))) 1.014941606409653)
      (num-test (gsl_sf_coupling_3j 0 1 1 0 1 -1) 0.7071067811865476)
      (num-test (gsl_sf_dawson 0.5) 0.4244363835020223)
      (num-test (gsl_sf_multiply -3 2) -6.0)
      (num-test (gsl_sf_ellint_E (/ pi 2) 0.5 GSL_MODE_DEFAULT) 1.467462209339427)
      (num-test (gsl_sf_erfc -10) 2.0)
      (num-test (gsl_sf_exp_mult 10 -2) -44052.93158961344)
      (num-test (gsl_sf_expm1 -.001) -0.0009995001666250082)
      (num-test (gsl_sf_Shi -1) -1.057250875375728)
      (num-test (gsl_sf_fermi_dirac_0 -1) 0.3132616875182229)
      (num-test (gsl_sf_gegenpoly_1 1.0 1.0) 2.0)
      
      (let ((p (float-vector 1.0 -2.0 1.0)) (res (vector 0.0 0.0)))
	(gsl_poly_complex_solve (double* p) 3 res)
	(test res #(1.0 1.0)))
      (let ((p (float-vector 1 -1 1 -1 1 -1 1 -1 1 -1 1)))
	(num-test (gsl_poly_eval (double* p) 11 1.0) 1.0))
      (let ((p (float-vector 2.1 -1.34 0.76 0.45)))
	(num-test (gsl_poly_complex_eval (double* p) 4 0.49+0.95i) 0.3959142999999998-0.6433305000000001i))
      (let ((res (float-vector 0.0 0.0)))
	(let ((err (gsl_poly_solve_quadratic 4.0 -20.0 26.0 (double* res))))
	  (test err 0)))
      (let ((res (float-vector 0.0 0.0)))
	(let ((err (gsl_poly_solve_quadratic 4.0 -20.0 21.0 (double* res))))
	  (test res (float-vector 1.5 3.5))))
      (let ((res (float-vector 0.0 0.0 0.0)))
	(let ((err (gsl_poly_solve_cubic -51 867 -4913 (double* res))))
	  (test res (float-vector 17.0 17.0 17.0))))
      (let ((res (vector 0.0 0.0)))
	(let ((err (gsl_poly_complex_solve_quadratic 4.0 -20.0 26.0 res)))
	  (test res #(2.5-0.5i 2.5+0.5i))))
      (let ((res (vector 0.0 0.0 0.0))) ; workspace handling is internal
	(let ((err (gsl_poly_complex_solve_cubic -51 867 -4913 res)))
	  (test res #(17.0 17.0 17.0))))
      
      (num-test (gsl_hypot3 1.0 1.0 1.0) (sqrt 3))
      (num-test (gsl_hypot 1.0 1.0) (sqrt 2))
      (test (nan? (gsl_nan)) #t)
      (test (infinite? (gsl_posinf)) #t)
      (test (gsl_frexp 2.0) '(0.5 2))
      (num-test (gsl_pow_2 4) 16.0)
      
      (num-test (gsl_cdf_ugaussian_P 0.0) 0.5)
      (num-test (gsl_cdf_ugaussian_P 0.5) 0.691462461274013)
      (num-test (gsl_cdf_ugaussian_Q 0.5) 0.3085375387259869)
      (num-test (gsl_cdf_ugaussian_Pinv 0.5) 0.0)
      (num-test (gsl_cdf_ugaussian_Qinv 0.5) 0.0)
      (num-test (gsl_cdf_exponential_P 0.1 0.7) 0.1331221002498184)
      (num-test (gsl_cdf_exponential_Q 0.1 0.7) 0.8668778997501816)
      (num-test (gsl_cdf_exponential_Pinv 0.13 0.7) 0.09748344713345537)
      (num-test (gsl_cdf_exponential_Qinv 0.86 0.7) 0.1055760228142086)
      (num-test (gsl_cdf_exppow_P -0.1 0.7 1.8) 0.4205349082867516)
      (num-test (gsl_cdf_exppow_Q -0.1 0.7 1.8) 0.5794650917132484)
      (num-test (gsl_cdf_tdist_P 0.0 1.0) 0.5)
      (num-test (gsl_cdf_tdist_Q 0.0 1.0) 0.5)
      (num-test (gsl_cdf_fdist_P 0.0 1.0 1.3) 0.0)
      (num-test (gsl_cdf_fdist_Q 0.0 1.0 1.3) 1.0)
      (num-test (gsl_cdf_fdist_Pinv 0.0 1.0 1.3) 0.0)
      (num-test (gsl_cdf_fdist_Qinv 1.0 1.0 1.3) 0.0)
      (num-test (gsl_cdf_gamma_P 0 1 1) 0.0)
      (num-test (gsl_cdf_gamma_Q 0 1 1) 1.0)
      (num-test (gsl_cdf_chisq_P 0 13) 0.0)
      (num-test (gsl_cdf_chisq_Q 0 13) 1.0)
      (num-test (gsl_cdf_beta_P 0 1.2 1.3) 0.0)
      (num-test (gsl_cdf_beta_Q 0 1.2 1.3) 1.0)
      
      (num-test (gsl_stats_mean (double* (float-vector 1.0 2.0 3.0 4.0)) 1 4) 2.5)
      (num-test (gsl_stats_skew (double* (float-vector 1.0 2.0 3.0 4.0)) 1 4) 0.0)
      (num-test (gsl_stats_max (double* (float-vector 1.0 2.0 3.0 4.0)) 1 4) 4.0)
      
      (let ((rng (gsl_rng_alloc gsl_rng_default)))
	(test (real? (gsl_ran_exponential rng 1.0)) #t)
	(gsl_rng_free rng))
      
      (num-test (gsl_complex_log 1+i) (log 1+i))
      (num-test (gsl_complex_abs 1+i) (magnitude 1+i))
      (num-test (gsl_complex_sin 1+i) (sin 1+i))
      
      (let ((gs (gsl_cheb_alloc 40)))
	(gsl_cheb_init gs (lambda (x) x) -1.0 1.0)
	(num-test (gsl_cheb_eval gs -1.0) -1.0)
	(num-test (gsl_cheb_eval gs 0.0) 0.0)
	(num-test (gsl_cheb_eval gs 1.0) 1.0)
	(gsl_cheb_free gs))
      
      (let ((x (float-vector 0.0))
	    (y (float-vector 0.0)))
	(gsl_deriv_central (lambda (x) (expt x 1.5)) 2.0 1e-8 (double* x) (double* y))
	(num-test (x 0) (* 1.5 (sqrt 2)))
	(gsl_deriv_forward (lambda (x) (expt x 1.5)) 0.0 1e-8 (double* x) (double* y))
	(test (< (x 0) 1e-5) #t))
      
      (let ((f (float-vector -1 3 0 4 2 6)))
	(gsl_sort (double* f) 1 6)
	(test f (float-vector -1 0 2 3 4 6)))
      
      (let ((g1 (gsl_vector_alloc 3))
	    (g2 (gsl_vector_alloc 3))
	    (f1 (make-float-vector 3)))
	(gsl_vector_add (float-vector->gsl_vector (float-vector 0 1 2) g1)
			(float-vector->gsl_vector (float-vector 3 4 5) g2))
	(gsl_vector->float-vector g1 f1)
	(gsl_vector_free g1)
	(gsl_vector_free g2)
	(test f1 (float-vector 3 5 7)))
      
      (let ((f (make-float-vector '(3 3))))
	(let ((g (gsl_matrix_alloc 3 3)))
	  (gsl_matrix_set_identity g)
	  (do ((i 0 (+ i 1)))
	      ((= i 3)
	       (gsl_matrix_free g))
	    (do ((j 0 (+ j 1)))
		((= j 3))
	      (set! (f i j) (gsl_matrix_get g i j)))))
	(test (equivalent? f #2d((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))) #t))
      
      (let ((f (make-vector '(3 3))))
	(let ((g (gsl_matrix_complex_alloc 3 3)))
	  (gsl_matrix_complex_set_identity g)
	  (gsl_matrix_complex_scale g 1+i)
	  (do ((i 0 (+ i 1)))
	      ((= i 3)
	       (gsl_matrix_complex_free g))
	    (do ((j 0 (+ j 1)))
		((= j 3))
	      (set! (f i j) (gsl_matrix_complex_get g i j)))))
	(test (equivalent? f #2d((1+i 0.0 0.0) (0.0 1+i 0.0) (0.0 0.0 1+i))) #t))
      
      (let ((Y (float-vector 0.554))
	    (A (float-vector -0.047))
	    (X (float-vector 0.672)))
	(cblas_dgemv 101 111 1 1 -0.3 (double* A) 1 (double* X) -1 -1 (double* Y) -1)
	(num-test (Y 0) -0.5445248))
      
      (let ((Y (float-vector 0.348 0.07))
	    (A (float-vector 0.932 -0.724))
	    (X (float-vector 0.334 -0.317))
	    (alpha (float-vector 0 .1))
	    (beta (float-vector 1 0)))
	(cblas_zgemv 101 111 1 1 (double* alpha) (double* A) 1 (double* X) -1 (double* beta) (double* Y) -1)
	(num-test (Y 0) 0.401726)
	(num-test (Y 1) 0.078178))
      
      (test (let ((f (float-vector 0 1 2 3 4))) (gsl_interp_bsearch (double* f) 1.5 0 4)) 1)
      
      (let ((x (make-float-vector 10))
	    (y (make-float-vector 10)))
	(do ((i 0 (+ i 1)))
	    ((= i 10))
	  (set! (x i) (+ i (* 0.5 (sin i))))
	  (set! (y i) (+ i (cos (* i i)))))
	(let ((acc (gsl_interp_accel_alloc))
	      (spline (gsl_spline_alloc gsl_interp_cspline 10)))
	  (gsl_spline_init spline (double* x) (double* y) 10)
	  (let ((res (gsl_spline_eval spline (x 5) acc)))
	    (gsl_spline_free spline)
	    (gsl_interp_accel_free acc)
	    (num-test res 5.991202811863474))))
      
      (let ((c (gsl_combination_alloc 6 3))
	    (data #2d((0 1 2) (0 1 3) (0 1 4) (0 1 5)
		      (0 2 3) (0 2 4) (0 2 5) (0 3 4)
		      (0 3 5) (0 4 5) (1 2 3) (1 2 4)
		      (1 2 5) (1 3 4) (1 3 5) (1 4 5)
		      (2 3 4) (2 3 5) (2 4 5) (3 4 5)))
	    (iv (make-int-vector 3 0)))
	(gsl_combination_init_first c)
	(do ((i 0 (+ i 1)))
	    ((= i 20))
	  ((*libgsl* 'gsl_combination->int-vector) c iv)
	  (if (not (equivalent? iv (data i)))
	      (format *stderr* ";gsl_combination: ~A ~A~%" iv (data i)))
	  (gsl_combination_next c))
	(gsl_combination_free c))
      
      (let ((p (gsl_permutation_alloc 3))
	    (data (make-int-vector 18 0)))
	(gsl_permutation_init p)
	(do ((pp GSL_SUCCESS (gsl_permutation_next p))
	     (i 0 (+ i 3)))
	    ((not (= pp GSL_SUCCESS)))
	  (set! (data i) (gsl_permutation_get p 0))
	  (set! (data (+ i 1)) (gsl_permutation_get p 1))
	  (set! (data (+ i 2)) (gsl_permutation_get p 2)))
	(gsl_permutation_free p)
	(test (equivalent? data #(0 1 2 0 2 1 1 0 2 1 2 0 2 0 1 2 1 0)) #t))
      
      (let ((N 50))
	(let ((t (make-float-vector N 0.0)))
	  (do ((i 0 (+ i 1)))
	      ((= i N))
	    (set! (t i) (/ 1.0 (* (+ i 1) (+ i 1)))))
	  (let ((zeta_2 (/ (* pi pi) 6.0)))
	    (let ((accel (float-vector 0.0))
		  (err (float-vector 0.0))
		  (w (gsl_sum_levin_u_alloc N)))
	      (gsl_sum_levin_u_accel (double* t) N w (double* accel) (double* err))
	      (num-test zeta_2 (accel 0))
	      (gsl_sum_levin_u_free w)))))
      
      (let ((data (float-vector 0 0  1 0  1 1  0 -1)) ; complex data as rl+im coming and going
	    (output (make-float-vector 8 0.0)))
	(gsl_dft_complex_forward (double* data) 1 4 (double* output))
	;; = -1 in snd terminology: (cfft! (vector 0 1 1+i 0-i) 4 -1): #(2.0 0-2i 0+2i -2.0)
	(test (equivalent? output (float-vector 2.0 0.0  0.0 -2.0  0.0 2.0  -2.0 0.0)) #t))
      (let ((data (float-vector 0 0  1 0  1 1  0 -1))) ; complex data as rl+im coming and going
	(gsl_fft_complex_radix2_forward (double* data) 1 4)
	(test (equivalent? data (float-vector 2.0 0.0  0.0 -2.0  0.0 2.0  -2.0 0.0)) #t))
      
      (let ((data (make-float-vector 256))
	    (w (gsl_wavelet_alloc gsl_wavelet_daubechies 4))
	    (work (gsl_wavelet_workspace_alloc 256)))
	(do ((i 0 (+ i 1)))
	    ((= i 256))
	  (set! (data i) (sin (* i (/ pi 128)))))
	(gsl_wavelet_transform_forward w (double* data) 1 256 work)
	(gsl_wavelet_transform_inverse w (double* data) 1 256 work)
	(gsl_wavelet_free w)
	(gsl_wavelet_workspace_free work)
	data)
      
      (let ((h (gsl_histogram_alloc 10))
	    (data (make-int-vector 10)))
	(gsl_histogram_set_ranges_uniform h 0.0 1.0)
	(do ((i 0 (+ i 1)))
	    ((= i 50))
	  (gsl_histogram_increment h (random 1.0)))
	(do ((i 0 (+ i 1)))
	    ((= i 10))
	  (set! (data i) (round (gsl_histogram_get h i))))
	(gsl_histogram_free h)
	data)
      
      (let ((a_data (float-vector 0.18 0.60 0.57 0.96  0.41 0.24 0.99 0.58  0.14 0.30 0.97 0.66  0.51 0.13 0.19 0.85))
	    (b_data (float-vector 1 2 3 4)))
	(let ((m (gsl_matrix_alloc 4 4))
	      (b (gsl_vector_alloc 4)))
	  (let ((x (gsl_vector_alloc 4))
		(p (gsl_permutation_alloc 4)))
	    (do ((i 0 (+ i 1)))
		((= i 4))
	      (do ((j 0 (+ j 1)))
		  ((= j 4))
		(gsl_matrix_set m i j (a_data (+ j (* i 4))))))
	    (do ((i 0 (+ i 1)))
		((= i 4))
	      (gsl_vector_set b i (b_data i)))
	    (gsl_linalg_LU_decomp m p) ; int-by-ref is internal
	    (gsl_linalg_LU_solve m p b x)
	    (do ((i 0 (+ i 1)))
		((= i 4))
	      (set! (b_data i) (gsl_vector_get x i)))
	    (gsl_permutation_free p)
	    (gsl_vector_free x)
	    b_data)))
      
      (when (>= gsl-version 1.16)
	(let ()
	  (define (dofit T X y c cov)
	    (let ((work (gsl_multifit_robust_alloc T (car (gsl_matrix_size X)) (cdr (gsl_matrix_size X)))))
	      (let ((s (gsl_multifit_robust X y c cov work)))
		(gsl_multifit_robust_free work)
		s)))
	  (let* ((n 30)
		 (p 2)
		 (a 1.45)
		 (b 3.88)
		 (X (gsl_matrix_alloc n p))
		 (x (gsl_vector_alloc n))
		 (y (gsl_vector_alloc n))
		 (c (gsl_vector_alloc p))
		 (c_ols (gsl_vector_alloc p))
		 (cov (gsl_matrix_alloc p p))
		 (gv (gsl_vector_alloc p))
		 (r (gsl_rng_alloc gsl_rng_default)))
	    (do ((i 0 (+ i 1)))
		((= i (- n 3)))
	      (let* ((dx (/ 10.0 (- n 1.0)))
		     (ei (gsl_rng_uniform r))
		     (xi (+ -5.0 (* i dx)))
		     (yi (+ b (* a xi))))
		(gsl_vector_set x i xi)
		(gsl_vector_set y i (+ yi ei))))
	    (gsl_vector_set x (- n 3) 4.7)
	    (gsl_vector_set y (- n 3) -8.3)
	    (gsl_vector_set x (- n 2) 3.5)
	    (gsl_vector_set y (- n 2) -6.7)
	    (gsl_vector_set x (- n 1) 4.1)
	    (gsl_vector_set y (- n 1) -6.0)
	    (do ((i 0 (+ i 1)))
		((= i n))
	      (let ((xi (gsl_vector_get x i)))
		(gsl_matrix_set X i 0 1.0)
		(gsl_matrix_set X i 1 xi)))
	    (dofit gsl_multifit_robust_ols X y c_ols cov)
	    (dofit gsl_multifit_robust_bisquare X y c cov)
	    (do ((i 0 (+ i 1)))
		((= i n))
	      (let ((xi (gsl_vector_get x i))
		    (yi (gsl_vector_get y i))
		    (y_ols (float-vector 0.0))
		    (y_rob (float-vector 0.0))
		    (y_err (float-vector 0.0)))
		(gsl_vector_set gv 0 (gsl_matrix_get X i 0))
		(gsl_vector_set gv 1 (gsl_matrix_get X i 1))
		(gsl_multifit_robust_est gv c cov (double* y_rob) (double* y_err))
		(gsl_multifit_robust_est gv c_ols cov (double* y_ols) (double* y_err))))
	    (gsl_matrix_free X)
	    (gsl_matrix_free cov)
	    (gsl_vector_free x)
	    (gsl_vector_free y)
	    (gsl_vector_free c)
	    (gsl_vector_free gv)
	    (gsl_rng_free r))))
      
      (let ()
	(gsl_rng_env_setup)
	(let* ((T gsl_rng_default)
	       (r (gsl_rng_alloc T))
	       (x 0)
	       (y 0)
	       (dx (float-vector 0.0))
	       (dy (float-vector 0.0)))
	  (do ((i 0 (+ i 1)))
	      ((= i 10))
	    (gsl_ran_dir_2d r (double* dx) (double* dy))
	    (set! x (+ x (dx 0)))
	    (set! y (+ y (dy 0))))
	  (gsl_rng_free r)))
      
      (let ((f_size 2)
	    (T gsl_multimin_fminimizer_nmsimplex))
	(define (simple-abs x)
	  (let ((u (gsl_vector_get x 0))
		(v (gsl_vector_get x 1)))
	    (let ((a (- u 1))
		  (b (- v 2)))
	      (+ (abs a) (abs b)))))
	(let ((x (gsl_vector_alloc f_size))
	      (step_size (gsl_vector_alloc f_size))
	      (s (gsl_multimin_fminimizer_alloc T 2)))
	  (gsl_vector_set x 0 1.0)
	  (gsl_vector_set x 1 2.0)
	  (gsl_vector_set step_size 0 1)
	  (gsl_vector_set step_size 1 1)
	  (gsl_multimin_fminimizer_set s simple-abs x step_size)
	  (do ((i 0 (+ i 1)))
	      ((= i 10))
	    (gsl_multimin_fminimizer_iterate s))
	  (let ((result (abs (gsl_multimin_fminimizer_fval s))))
	    (gsl_multimin_fminimizer_free s)
	    (gsl_vector_free x)
	    (gsl_vector_free step_size)
	    (num-test result 0.0))))
      
      (let ((n 4)
	    (x (float-vector 1970 1980 1990 2000))
	    (y (float-vector 12 11 14 13))
	    (w (float-vector 0.1 0.2 0.3 0.4))
	    (c0 (float-vector 0.0))
	    (c1 (float-vector 0.0))
	    (cov00 (float-vector 0.0))
	    (cov01 (float-vector 0.0))
	    (cov11 (float-vector 0.0))
	    (chisq (float-vector 0.0)))
	(gsl_fit_wlinear (double* x) 1 (double* w) 1 (double* y) 1 n
			 (double* c0) (double* c1) (double* cov00) (double* cov01) (double* cov11) (double* chisq))
	(num-test (+ (c0 0) (c1 0)) -106.54))
      
      (let ((c (gsl_multiset_calloc 4 2)))
	(test (list (gsl_multiset_n c) (gsl_multiset_k c)) '(4 2)))
      
      (let ((x (gsl_vector_alloc 2))
	    (factor 1.0)
	    (T gsl_multiroot_fsolver_dnewton))
	(define (rosenb x f)
	  (let ((x0 (gsl_vector_get x 0))
		(x1 (gsl_vector_get x 1)))
	    (let ((y0 (- 1 x0))
		  (y1 (* 10 (- x1 (* x0 x0)))))
	      (gsl_vector_set f 0 y0)
	      (gsl_vector_set f 1 y1)
	      GSL_SUCCESS)))
	(gsl_vector_set x 0 -1.2)
	(gsl_vector_set x 1 1.0)
	(let ((s (gsl_multiroot_fsolver_alloc T 2)))
	  (gsl_multiroot_fsolver_set s rosenb x)
	  (do ((i 0 (+ i 1)))
	      ((= i 10))
	    (gsl_multiroot_fsolver_iterate s))
	  (let ((residual (abs (gsl_vector_get (gsl_multiroot_fsolver_f s) 0))))
	    (gsl_multiroot_fsolver_free s)
	    (gsl_vector_free x)
	    (test residual 0.0))))
      ))

  (testrst))

(exit)

