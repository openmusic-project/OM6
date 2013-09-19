;;===========================================================================
;;; midi-api-cl.lisp
;;; Common Lisp Midi API - based on ms:: versions found in midi-api.lisp
;;; 
;;; This program is free software;;;  you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License
;;; as published by the Free Software Foundation;;;  either version 2
;;; of the License, or (at your option) any later version.
;;; 
;;; See file LICENSE for further informations on licensing terms.
;;; 
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY;;;  without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;; 
;;; You should have received a copy of the GNU General Public License
;;; along with this program;;;  if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
;;; 
;;; Author: Anders Vinjar

;;===========================================================================
; DocFile
; MIDI functions called by OpenMusic
; Using lisp-based SMF I/O + events
; Sources at Goldsmiths, Univ. of London: http://www.doc.gold.ac.uk/isms/lisp/midi/
;;===========================================================================

;;; this file - midi-api-cl.lisp - is meant as a replacement off all
;;; midishare-dependencies in midi-api.lisp, while staying compatible
;;; with all the various ms:: specialities.  Everything below named
;;; 'om-midi-*' seems to be part of the main OM api.
;;;
;;; TODO: get rid of ms:: thinking everywhere where live-streams arent
;;; wanted - ie smf read/write, message-crunching..  Substitute
;;; everything live/rt with ALSA-based api.

(in-package :oa)

;;;==============================
;;; MIDI UTILS
;;;==============================

;; types (replacements for ms::..) defined in "./midi-types.lisp"

(defun om-midi-get-num-from-type (typestr)
  (eval (read-from-string (concatenate 'string "ml::type" typestr))))

;=== Converts an event name symbol to MS event type format
;=== eg: KeyOn --> typeKeyOn
(defun om-midi-symb2mtype (sym)
  (eval (intern (concatenate 'string "TYPE" (STRING sym)) :midishare)))

(defun om-midi-new-event-safe (type)
  (make-instance 'midimsg2evt :type type))

(defun om-midi-new-evt (type &key port ref chan date vals pgm pitch kpress dur ctrlchange bend param tempo bytes)
  (let ((event (om-midi-new-event-safe type)))
    (when chan (setf (event-chan event) chan))                  
    (when port (setf (event-port event) port))
    (when date (setf (event-date event) date))
    (when ref (setf (event-ref event) ref))
    (cond (vals
	   ;; (if (listp vals)
	   ;;     (loop for v in vals for i = 0 then (+ i 1) do 
	   ;; 	    (setf (event-fields event) (list i v)))
           ;;     (setf (event-fields event) (list 0 vals)))
	   ;; (when (listp vals)
	   ;;   (setf (event-pitch event) (first vals)
	   ;; 	   (event-velocity event) (second vals)
	   ;; 	   (event-dur event) (third vals)))
	   (if (listp vals)
	       (setf (event-fields event) vals)
	       (setf (event-fields event) (list 0 vals))))
	  (ctrlchange
	   (progn (setf (event-ctrl event) (car ctrlchange))
		  (setf (event-val event) (cadr ctrlchange))))
	  (bytes
	   (dolist (byte (if (consp bytes) bytes (list bytes)))
	     (setf (event-midiaddfield event) byte)))
          (t 
           (when param (setf (event-param event) param))
           (when pgm (setf (event-pgm event) pgm))
           (when bend (setf (event-bend event) bend))
           (when dur (setf (event-dur event) dur))
           (when kpress (setf (event-kpress event) kpress))
           (when pitch (setf (event-pitch event) pitch))
           (when tempo (setf (event-tempo event) tempo))))
    event))

(defun om-midi-copy-evt (event)
  (let* ((class (class-of event))
	 (new (allocate-instance class)))
    (dolist (slot (mapcar #'clos::slot-definition-name (clos::class-slots class)))
      (when (slot-boundp event slot)
        (setf (slot-value new slot)
              (slot-value event slot))))
    new))

;;; a structure to manage instances of midimsg2evt's

(defstruct midi-seq (events))

(defun om-midi-seq-concat-evt (seq evt &optional (end t))
  (when (and evt seq)
    (if end
        (om-midi-seq-add-evt seq evt)
      (progn
	(setf (event-link evt) (car (midi-seq-events seq)))
	(push evt (midi-seq-events seq))))))

(defun om-midi-seq-add-evt (seq evt)
  (if (null (midi-seq-events seq))
      (push evt (midi-seq-events seq))
      (progn
	(setf (event-link (car (last (midi-seq-events seq)))) evt)
	(rplacd (last (midi-seq-events seq)) (list evt)))))

(defun om-midi-new-seq () (make-midi-seq))

(defun om-midi-free-seq (seq) (setf seq nil))

(defun om-midi-seq-first-evt (seq)
  (let ((events (midi-seq-events seq)))
    (loop for event in events
       until (event-link event)
       finally (return event))))

(defun om-midi-next-evt (evt) (event-link evt))

(defun om-midi-evt-get (event slot)
  (case slot
    (:type (event-type event))
    (:date (event-date event))
    (:ref (event-ref event))
    (:port (event-port event))
    (:chan (event-chan event))
    (:fields (event-fields event))
    (:dur (event-dur event))
    (:pitch (event-pitch event))
    (:vel (event-velocity event))
    (:kpress (event-keypress event))
    (:bend (event-bend event))
    (:tempo (event-tempo event))
    (:text (event-text event))
    (:link (event-link event))))

(defun om-midi-evt-set (evt &key dur date port ref chan pgm param kpress bend tempo ctrlchange vals bytes field text)
  (when dur (setf (event-dur evt) dur))
  (when date (setf (event-date evt) date))
  (when port (setf (event-port evt) port))
  (when chan (setf (event-chan evt) chan))
  (when ref (setf (event-ref evt) ref))
  (when pgm (setf (event-pgm evt) pgm))
  (when param (setf (event-param evt) param))
  (when kpress (setf (event-keypress evt) kpress))
  (when bend (setf (event-bend evt) bend))
  (when tempo (setf (event-tempo evt) tempo))
  (when text (setf (event-text evt) text))
  (when ctrlchange
    (setf (event-ctrl evt) (car ctrlchange))
    (setf (event-val evt) (cadr ctrlchange)))
  (when bytes (dolist (byte (if (consp bytes) bytes (list bytes)))
                (setf (event-midiaddfield evt) byte)))
  (when vals
    (if (listp vals)
        (loop for v in vals
	   for i = 0 then (+ i 1)
	   do (setf (event-fields evt) (list i v)))
	(setf (event-fields evt) (list 0 vals))))
  (when field (setf (event-fields evt) (list (car field) (cadr field)))))


;; takes instances of the various midi:*message classes, returning
;; a 'midimsg2evt:

(defun make-note-list () (make-hash-table :test 'equal))

(defun event-is-on-off-or... (msg)
  (cond ((or (typep msg 'midi:note-off-message)
	     (and (typep msg 'midi:note-on-message) (zerop (midi:message-velocity msg))))
	 'off)
	((typep msg 'midi:note-on-message) 'on)
	(t t)))

(defun make-event-from-message (msg ref note-list)
  (case (event-is-on-off-or... msg)
    (off (let* ((key (midi:message-key msg))
		(channel (midi:message-channel msg))
		(startevt (gethash (list key channel) note-list)))
	   (when startevt
	     (remhash (list key channel) note-list)
	     (let ((duration (- (midi:message-time msg) (midi:message-time startevt))))
	       (change-class startevt 'midimsg2evt)
	       (setf (event-dur startevt) duration)
	       (setf (event-ref startevt) ref)
	       startevt))))
    (on (let ((key (midi:message-key msg))
	      (channel (midi:message-channel msg)))
	  ;;push data to table and return nil (for collectors...):
	  (setf (gethash (list key channel) note-list) msg)
	  nil))
    (t (change-class msg 'midimsg2evt))))

(defun messages2events (trk ref)
  (let ((note-list (make-note-list)))
    (loop for message in trk
       for event = (make-event-from-message message ref note-list)
       when event collect event)))

;;; run through whole seq 'linking' events:
(defun linkevents (events)		
  (loop for this in events
       for next in (cdr events)
       collect (progn (setf (event-link this) next) this) into bag
       finally (return (nconc bag (list next)))))

;; (defun tracks2seq (tracks)
;;   (mapcar #'linkevents (apply #'append (mapcar #'messages2events tracks))))

(defun sort-events-< (a b)
  (cond ((< (event-date a) (event-date b)) t)
	((= (event-date a) (event-date b)) 
	 (> (event-type a) (event-type b))) ;send meta-messages first 
	(t nil)))

(defun tracks2seq (tracks)
  (if (> (length tracks) 1)
      (append
       ;;mf-format=1, ie. dont link events from tempo-track...
       (messages2events (car tracks) 0)
       (linkevents
	(sort (loop for ref from 1
		 for track in (cdr tracks)
		 append (messages2events track ref))
	      #'sort-events-<)))
      ;; else mf-format=0, handle interspersed tempo-messages
      (linkevents		
       (sort (loop for ref from 0
		for track in tracks
		append (messages2events track ref))
	     #'sort-events-<))))

(defun tracks2seq (tracks)
  (linkevents
   (sort (loop for ref from 0
	    for track in tracks
	    append (messages2events track ref))
	 #'sort-events-<)))

(defun om-midi-load-file (pathname sequence)
  (let ((f (midi:read-midi-file pathname))
	err nbtracks clicks format timedef)
    (setf nbtracks (length (midi:midifile-tracks f))
	  clicks (midi:midifile-division f)
	  format (midi:midifile-format f)
	  timedef 0
	  err 0
	  (midi-seq-events sequence) (tracks2seq (midi:midifile-tracks f)))
    (values err sequence nbtracks clicks format timedef)))

(defun om-midi-copy-seq (seq &optional filtertest)
  (let ((event (om-midi-seq-first-evt seq))
        (newseq (om-midi-new-seq)))
    (loop while event do
	 (let ((newevent (om-midi-copy-evt event)))
	   (unless (or (not event) 
		       (and filtertest (cond ((equal (car filtertest) :type)
					      (= (cadr filtertest) (event-type event)))
					     (t nil))))
	     (om-midi-seq-add-evt newseq newevent))
	   (setf event (om-midi-next-evt event))))
    newseq))

;;;
;;; FILE OUTPUT: building useful midi-messages, writing SMF's:
;;;

(defparameter +note-off-opcode+		#x80)
(defparameter +note-on-opcode+		#x90)
(defparameter +key-pressure-opcode+	#xA0)
(defparameter +control-change-opcode+	#xB0)
(defparameter +program-change-opcode+	#xC0)
(defparameter +channel-pressure-opcode+ #xD0)
(defparameter +pitch-bend-opcode+	#xE0)
(defparameter +tempo-opcode+		#xFF)

(defun make-note-off-message (time key vel chan)
  (make-instance 'midi:note-off-message :key key :time time :velocity vel :status (logior +note-off-opcode+ chan)))

(defun make-note-on-message (time key vel chan)
  (make-instance 'midi:note-on-message :key key :time time :velocity vel :status (logior +note-on-opcode+ chan)))

(defun make-tempo-message (time tempo)
  (make-instance 'midi:tempo-message :time time :tempo tempo :status +tempo-opcode+))

(defun event2note-on-off (ev)
  (let ((k (first (event-fields ev)))
	(v (second (event-fields ev)))
	(onset (event-date ev))
	(dur (third (event-fields ev)))
	(chan (event-chan ev)))
    (let ((on (make-note-on-message onset k v chan))
	  (off (make-note-off-message (+ onset dur) k 0 chan)))
      (list on off))))

(defun event2note-off (ev)
  (make-note-off-message (event-date ev) (first (event-fields ev)) (event-velocity ev) (event-chan ev)))

(defun event2note-on (ev)
  (make-note-on-message (event-date ev) (first (event-fields ev)) (event-velocity ev) (event-chan ev)))

(defun event2tempo (ev)
  (make-tempo-message (event-date ev) (second (event-fields ev))))

(defun make-messages-from-event (ev)
  (let ((type (event-type ev)))
    (cond 
      ((= type (om-midi-get-num-from-type "Note")) (event2note-on-off ev)) ;returns cons
      ((= type (om-midi-get-num-from-type "keyOn")) (event2note-on ev))
      ((= type (om-midi-get-num-from-type "keyOff")) (event2note-off ev))
      ((= type (om-midi-get-num-from-type "Tempo")) (event2tempo ev))
      (t (error "(midi) message-type ~A isn't supported yet" type)))))

(defun seq2tracks (seq)
  (loop for ev in (midi-seq-events seq)
     for msg = (make-messages-from-event ev)
     if (listp msg) append msg
     else collect msg))

(defun om-midi-save-seq-in-file (seq filename &key (fileformat 1) (timedef 0) (clicks 1000) (tracks 1))
  (declare (ignore timedef tracks))
  (let ((mf (make-instance 'midi:midifile :format fileformat :division clicks)))
    (setf (slot-value mf 'midi::tracks) (list (seq2tracks seq)))
    (om-create-directory filename)
    (midi:write-midi-file mf filename)
    filename))
