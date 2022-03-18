(define file-names '(("make-index.scm" . "v-index")
		     ("tmac.scm" . "v-mac")
		     ("tpeak.scm" . "v-peak")
		     ("tvect.scm" . "v-vect")
		     ("teq.scm" . "v-eq")
		     ("tfft.scm" . "v-fft")
		     ("tref.scm" . "v-ref")
		     ("tauto.scm" . "v-auto")
		     ("s7test.scm" . "v-test")
		     ("tcopy.scm" . "v-cop")
		     ("lt.scm" . "v-lt")
		     ("tform.scm" . "v-form")
		     ("tread.scm" . "v-read")
		     ("tmap.scm" . "v-map")
		     ("tmat.scm" . "v-mat")
		     ("tmisc.scm" . "v-misc")
		     ("lg.scm" . "v-lg")
		     ("titer.scm" . "v-iter")
		     ("tsort.scm" . "v-sort")
		     ("tlet.scm" . "v-let")
		     ("thash.scm" . "v-hash")
		     ("tgen.scm" . "v-gen")
		     ("tall.scm" . "v-all")
		     ("snd-test.scm" . "v-call")
		     ("full-snd-test.scm" . "v-sg")
		     ("dup.scm" . "v-dup")
		     ("tset.scm" . "v-set")
		     ("trec.scm" . "v-rec")
		     ("tclo.scm" . "v-clo")
		     ("tbig.scm" . "v-big")
		     ("tshoot.scm" . "v-shoot")
		     ("fbench.scm" . "v-fb")
		     ("trclo.scm" . "v-rclo")
		     ("tcase.scm" . "v-case")
		     ("test-all.scm" . "v-b")
		     ("tio.scm" . "v-io")
		     ("tgc.scm" . "v-gc")
		     ("tnum.scm" . "v-num")
		     ("tmock.scm" . "v-mock")
		     ("concordance.scm" . "v-str")
		     ("tgsl.scm" . "v-gsl")
		     ("tlist.scm" . "v-list")
		     ("tload.scm" . "v-load")
		     ("cb.scm" . "v-cb")
		     ("tari.scm" . "v-ari")
		     ("texit.scm" . "v-exit")
		     ("tleft.scm" . "v-left")
		     ("tobj.scm" . "v-obj")
		     ("timp.scm" . "v-imp")
		     ("tlamb.scm" . "v-lamb")
		     ))

(define (last-callg)
  (let ((name (system "ls callg*" #t)))
    (let ((len (length name)))
      (do ((i 0 (+ i 1)))
	  ((or (= i len)
	       (char-whitespace? (name i)))
	   (substring name 0 i))))))

(define (next-file f)
  (let ((name (system (format #f "ls -t ~A*" f) #t)))
    (let ((len (length name)))
      (do ((i 0 (+ i 1)))
	  ((or (= i len)
	       (and (char-numeric? (name i))
		    (char-numeric? (name (+ i 1)))))
	   (+ 1 (string->number (substring name i (+ i 2)))))))))

(define (call-valgrind)
  (for-each
   (lambda (caller+file)
     (system "rm callg*")
     (format *stderr* "~%~NC~%~NC ~A ~NC~%~NC~%" 40 #\- 16 #\- (cadr caller+file) 16 #\- 40 #\-)
     (system (format #f "valgrind --tool=callgrind ./~A ~A" (car caller+file) (cadr caller+file)))

     (let ((outfile (cdr (assoc (cadr caller+file) file-names))))
       (let ((next (next-file outfile)))
	 (system (format #f "callgrind_annotate --auto=yes --show-percs=no --threshold=100 ~A > ~A~D" (last-callg) outfile next))
	 (format *stderr* "~NC ~A~D -> ~A~D: ~NC~%" 8 #\space outfile (- next 1) outfile next 8 #\space)
	 (system (format #f "./snd compare-calls.scm -e '(compare-calls \"~A~D\" \"~A~D\")'" outfile (- next 1) outfile next)))))

   (list (list "repl" "tpeak.scm")
	 (list "repl" "tref.scm")
	 (list "snd -noinit" "make-index.scm")
	 (list "repl" "tmock.scm")
	 (list "repl" "tvect.scm")
	 (list "repl" "texit.scm")
	 (list "repl" "s7test.scm")
	 (list "repl" "lt.scm")
	 (list "repl" "timp.scm")
	 (list "repl" "tread.scm")
	 (list "repl" "dup.scm")
	 (list "repl" "trclo.scm")
	 (list "repl" "fbench.scm")
	 (list "repl" "tcopy.scm")
	 (list "repl" "tmat.scm")
	 (list "repl" "tauto.scm")
	 (list "repl" "titer.scm")
	 (list "repl" "tsort.scm")
	 (list "repl" "tmac.scm")
	 (list "repl" "tload.scm")
	 (list "repl" "tset.scm")
	 (list "repl" "teq.scm")
	 (list "repl" "tio.scm")
	 (list "repl" "tobj.scm")
	 (list "repl" "tclo.scm")
	 (list "repl" "tcase.scm")
	 (list "repl" "tlet.scm")
	 (list "repl" "tmap.scm")
	 (list "repl" "tfft.scm")
	 (list "repl" "tshoot.scm")
	 (list "repl" "tform.scm")
	 (list "repl" "tnum.scm")
	 (list "repl" "concordance.scm")
	 (list "repl" "tlamb.scm")
	 (list "repl" "tgsl.scm")
	 (list "repl" "tmisc.scm")
	 (list "repl" "tlist.scm")
	 (list "repl" "trec.scm")
	 (reader-cond ((not (provided? 'gmp)) (list "repl" "tari.scm")))
	 (list "repl" "tleft.scm")
	 (list "repl" "tgc.scm")
	 (list "repl" "thash.scm")
	 (list "repl" "cb.scm")
	 (list "snd -noinit" "tgen.scm")    ; repl here + cload sndlib was slower
	 (list "snd -noinit" "tall.scm")
	 (list "snd -l" "snd-test.scm")
	 (list "snd -l" "full-snd-test.scm")
	 (list "repl" "lg.scm")
	 (list "repl" "tbig.scm")
	 )))

(call-valgrind)

(when (file-exists? "test.table")
  (system "mv test.table old-test.table"))
(load "compare-calls.scm")
(combine-latest)

(exit)
