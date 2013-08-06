(in-package :oa)

;; redefinitions using CFFI

(defun om-write-ptr (ptr pos type value) 
  (cffi::%mem-set value ptr type pos))

(defun om-read-ptr (ptr pos type) 
  (cffi::%mem-ref ptr type pos))
 
;(setf aaa (om-make-pointer 5))
;(om-write-ptr aaa 1 :float 8.0)
;(om-read-ptr aaa 0 :float)
