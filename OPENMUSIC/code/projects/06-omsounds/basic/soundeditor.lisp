;OpenMusic
;
;Copyright (C) 1997, 1998, 1999, 2000 by IRCAM-Centre Georges Pompidou, Paris, France.
; 
;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the License, or (at your option) any later version.
;
;See file LICENSE for further informations on licensing terms.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
;
;Authors: Gerard Assayag and Augusto Agon

(in-package :om) 



;===========================================================
;CONTROL VIEW
;===========================================================
(defclass sound-control-view (3dBorder-view) 
  ((editor :initform nil :accessor editor :initarg :editor)    ;;; a reference to the main editor
   ;;; a list of controls
   (play-buttons :initform nil :accessor play-buttons)
   (mode-buttons :initform nil :accessor mode-buttons)
   (vol-control :initform nil :accessor vol-control)
   (pan-control :initform nil :accessor pan-control))
  (:default-initargs #+win32 :draw-with-buffer #+win32 t))

(defmethod editor ((self sound-control-view)) (om-view-container self))

(defmethod initialize-instance :after ((self sound-control-view) &rest args)
  
    (setf (mode-buttons self)
          (list (om-make-view 'om-icon-button :position (om-make-point 20 7) :size (om-make-point 22 22)
                              :icon1 "mousecursor" :icon2 "mousecursor-pushed"
                              :lock-push t
                              :selected-p (and (panel (editor self)) (equal :normal (cursor-mode (panel (editor self)))))
                              :action #'(lambda (item) 
                                          (setf (cursor-mode (panel (editor self))) :normal)
                                          (setf (selected-p item) t
                                                (selected-p (cadr (mode-buttons self))) nil)
                                          (om-invalidate-view self)))
                (om-make-view 'om-icon-button :position  (om-make-point 41 7) :size (om-make-point 22 22)
                              :icon1 "beamcursor" :icon2 "beamcursor-pushed"
                              :lock-push t
                              :selected-p (and (panel (editor self)) (equal :interval (cursor-mode (panel (editor self)))))
                              :action #'(lambda (item) 
                                          (setf (cursor-mode (panel (editor self))) :interval)
                                          (setf (selected-p item) t
                                                (selected-p (car (mode-buttons self))) nil)
                                          (om-invalidate-view self)))
                (om-make-view 'om-icon-button :position (om-make-point 62 7) :size (om-make-point 22 22)
                              :id :resize
                              :icon1 "resize" :icon2 "resize-pushed"
                              :lock-push nil
                              :action #'(lambda (item) 
                                          (init-coor-system (panel (editor self)))
                                          (om-invalidate-view (rulerx (panel (editor self))) t)))
                                         
                ))

    (setf (play-buttons self)
        (list (om-make-view 'om-icon-button :position (om-make-point 200 7) :size (om-make-point 22 22)
                            :icon1 "play" :icon2 "play-pushed"
                            :lock-push t
                            :action #'(lambda (item) (editor-play (editor self))))
              
              (om-make-view 'om-icon-button :position (om-make-point 221 7) :size (om-make-point 22 22)
                            :icon1 "pause" :icon2 "pause-pushed"
                            :lock-push t
                            :action #'(lambda (item) (editor-pause (editor self))))
              
              (om-make-view 'om-icon-button :position (om-make-point 242 7) :size (om-make-point 22 22)
                            :icon1 "stop" :icon2 "stop-pushed"
                            :action #'(lambda (item) (editor-stop (editor self))))
              
              ;; dummy rec button
              (om-make-view 'om-icon-button :position (om-make-point -10 7) :size (om-make-point 1 1)
                            :icon1 "rec" :icon2 "rec-pushed"
                            :lock-push t
                            :action #'(lambda (item) (editor-record (editor self))))
              
              (om-make-view 'om-icon-button :position (om-make-point 263 7) :size (om-make-point 22 22)
                            :icon1 "loopbutton" :icon2 "loopbutton-pushed"
                            :lock-push t
                            :selected-p (loop-play (editor self))
                            :action #'(lambda (item) 
                                        (setf (loop-play (editor self))
                                              (not (loop-play (editor self))))
                                        (setf (selected-p item) (loop-play (editor self)))
                                        )
                            )
              
              (om-make-view 'om-icon-button :position (om-make-point 324 7) :size (om-make-point 22 22)
                            :icon1 "player" :icon2 "player-pushed"
                            :action #'(lambda (item) 
                                        (let* ((previousplayer (get-edit-param (editor self) 'player))
                                               (newplayer (select-player (editor self))))
                                          (when (and newplayer (not (equal previousplayer newplayer)))
                                            (player-special-action newplayer)
                                            (player-init newplayer)
                                            (update-player-controls (editor self) newplayer self)))))))

    (apply 'om-add-subviews self
           (append (play-buttons self)
                   (mode-buttons self)))     
    )
  

      
    
(defmethod update-controls ((self sound-control-view))
  (let ((player (get-edit-param (editor self) 'player)))
    ;(om-set-selected-item (player-control self) (audio-player-name player))
    (update-player-controls (editor self) player self)
    ;(set-value (vol-control self) (vol (object (editor self))))
    ;(set-value (pan-control self) (pan (object (editor self))))
    ))



;;;==============
;;; RULER 
;;;==============

(defclass sound-ruler (ruler) ())

(defmethod strech-ruler-release ((self sound-ruler) pos) 
  (call-next-method)
  (let ((size (- (cadr (rangex (assoc-view self))) (car (rangex (assoc-view self))))))
    (when (> (cadr (rangex (assoc-view self))) (cadr (bounds-x (assoc-view self))))
      (setf (rangex (assoc-view self))
            (list 
             (max 0 (- (cadr (bounds-x (assoc-view self))) size))
             (cadr (bounds-x (assoc-view self)))
             ))
      ))
  (update-subviews (om-view-container self)))


;;;================
;;; SOUND PREVIEW
;;;================

(defclass full-preview (3Dborder-view cursor-play-view-mixin) ()
     (:default-initargs
      #+win32 :draw-with-buffer #+win32 t)
     ) 

(defvar *preview-size* "size of the preview pane")
(setf *preview-size* 40)


(defmethod update-cursor ((self full-preview) time &optional y1 y2)
  (let ((y (or y1 0))
        (h (if y2 (- y2 y1) (h self)))
        (pixel (round (* (/ time (cadr (bounds-x (panel (om-view-container self))))) (w self)))))
    (om-update-movable-cursor self pixel y 4 h)))


(defmethod om-draw-contents ((self full-preview))  
  (call-next-method)
  (if (and (om-view-container self) (sndpict (om-view-container self)))
    (let* ((panel (panel (om-view-container self)))
           (dur (cadr (bounds-x panel))))
      (unless (zerop dur)
        (om-with-focused-view self
          (om-draw-picture self (sndpict (om-view-container self)) (om-make-point 0 0) (om-view-size self))
          (om-with-fg-color self *om-steel-blue-color*
            (om-draw-rect (round (* (w self) (/ (car (rangex panel)) 
                                                dur)))
                          2
                          (round (* (w self) (/ (- (cadr (rangex panel))  (car (rangex panel)))
                                                dur)))
                          (- (h self) 5)))
          (om-with-fg-color self *om-gray-color*
            (om-with-dashline
              (loop for item in (markers (object (om-view-container self)))
                    for k = 0 then (+ k 1) do
                    (om-draw-line (round (* (w self) item 1000) dur) 0 (round (* (w self) item 1000) dur) (h self))
                    )))
          (om-with-fg-color self *om-red2-color*
            (om-draw-line (round (* (w self) (cursor-pos panel)) dur) 0 
                          (round (* (w self) (cursor-pos panel)) dur) (h self)))
          (when (cursor-interval panel)
            (draw-h-rectangle (list (round (* (w self) (car (cursor-interval panel))) dur) 0 
                                    (round (* (w self) (cadr (cursor-interval panel))) dur) (h self)) t t))
          ))
      )
    (om-with-focused-view self 
      (om-with-fg-color self *om-gray-color*
          (om-draw-string 10 24 "sound preview not available")))))


;===========================================================
;EDITOR 
;===========================================================
(defclass soundEditor (EditorView object-editor play-editor-mixin)
   ((mode :initform nil :accessor mode)
    (control :initform nil :accessor control)
    (preview :initform nil :accessor preview)
    (sndpict :initform nil :accessor sndpict)
    (timeunit :initform 0 :accessor timeunit :initarg :timeunit)))

(defmethod make-editor-window ((class (eql 'soundEditor)) object name ref &key 
                               winsize winpos (close-p t) (winshow t) (resize t) (retain-scroll nil)
                               (wintype nil))
  (call-next-method class object (if (om-sound-file-name object)
                                     (namestring (om-sound-file-name object))
                                   "empty sound")
                    ref :winsize winsize :winpos winpos :resize resize 
                    :close-p close-p :winshow winshow :resize resize
                    :retain-scroll retain-scroll :wintype wintype))


(defmethod get-panel-class ((self soundEditor)) 'soundpanel)
(defmethod get-control-h ((self soundEditor)) 36)
(defmethod get-titlebar-class ((self soundeditor)) 'sound-titlebar)

(defmethod get-help-list ((self soundeditor))
  (list '((alt+clic "Add Marker")
          (del "Delete Selected Markers")
          (("g") "Show/Hide Grid")
          (("A") "Align Selected Markers to Grid")
          (esc "Reset cursor")
          (space "Play/Stop"))))

(defmethod sound-import ((self soundeditor))
  (let ((newsound (get-sound)))
    (when newsound
      (setf (value (ref self)) newsound)
      (om-invalidate-view (car (frames (ref self))))
      (update-editor-after-eval self (value (ref self))))))

(defmethod initialize-instance :after ((self soundEditor) &rest args)
  (declare (ignore args))

  ;;; Allocate the sndbuffer (which is used to draw the waveform dynamically)
  (when (om-sound-file-name (object self))
    (om-sound-update-buffer-with-new (object self) (multiple-value-bind (data size nch) 
                                                       (au::load-audio-data (oa::convert-filename-encoding (om-sound-file-name (object self))) :float) 
                                                     (let ((sndbuffer data)) sndbuffer))))

  (setf (panel self) (om-make-view (get-panel-class self) 
                                   :owner self
                                   :scrollbars :h
                                   :position (om-make-point 0 *titlebars-h*) 
                                   :size (om-make-point (w self) (- (h self) (+ 25 *titlebars-h* (get-control-h self))))
                                   :cursor-mode :interval
                                   :rangex (list 0 (get-obj-dur (object self)))
                                   :bounds-x (list 0 (get-obj-dur (object self)))
                                   ))

  (setf (rulerx (panel self)) (om-make-view 'sound-ruler
                                            :owner self
                                            :axe 'x
                                            :assoc-view (panel self)
                                            :zoom 1000
                                            :minzoom 1
                                            :position (om-make-point 0 (- (h self) (get-control-h self) 25)) 
                                            :size (om-make-point (w self) 25)))
  
  (setf (control self) (om-make-view 'sound-control-view 
                                     :owner self
                                     :editor self
                                     :position (om-make-point 0 (- (h self) (get-control-h self))) 
                                     :size (om-make-point (w self) (get-control-h self))
                                     :bg-color *controls-color*))
  
  (setf (preview self) (om-make-view 'full-preview 
                                     :owner self
                                     :position (om-make-point 0 (get-control-h self)) 
                                     :size (om-make-point (w self) (get-control-h self))))


  (setf (sndpict self) (sound-get-pict (object self)))
  (set-units-ruler (panel self) (rulerx (panel self)))
  (update-controls (control self))
  (om-invalidate-view (panel self)))


(defmethod close-editor-after ((self soundEditor))
  (call-next-method)
  ;;; Free the sndbuffer (which is used to draw the waveform dynamically)
  (when (om-sound-sndbuffer (object self))
    (fli::free-foreign-object (om-sound-sndbuffer (object self)))))


(defmethod update-editor-after-eval ((self soundEditor) val)
  (call-next-method)
  (update-controls (control self))
  (setf (rangex (panel self)) (list 0 (get-obj-dur (object self))))
  (setf (bounds-x (panel self)) (list 0 (get-obj-dur (object self))))
  (set-units-ruler (panel self) (rulerx (panel self)))
  (let ((path (om-sound-file-name (object self))))
    (om-set-window-title (om-view-window self) (if path (namestring path) "empty sound")))
  (setf (sndpict self) (sound-get-pict (object self)))
  (update-titlebar self)
  (update-subviews self)
  (update-menubar self))

(defmethod update-editor-controls ((self soundEditor)) 
  (update-controls (control self)))



(defun calc-panel-size (bounds width range)
  (if (zerop (- (cadr range) (car range))) width
    (round (* (/ width (- (cadr range) (car range))) (- (cadr bounds) (car bounds))))))


(defmethod update-subviews ((self soundeditor))
   (when (title-bar self)
     (om-set-view-size  (title-bar self) (om-make-point (w self) *titlebars-h*)))
   (om-set-view-size  (panel self) (om-make-point (w self)
                                                   (- (h self) (get-control-h self) *preview-size* *titlebars-h* 25)))
   (om-set-field-size  (panel self) (om-make-point (calc-panel-size (bounds-x (panel self)) 
                                                                    (w self)
                                                                    (rangex (panel self)))
                                                   (- (h self) (get-control-h self) *preview-size* *titlebars-h* 25)))
   (om-set-view-position (panel self) (om-make-point 0 (+ *preview-size* *titlebars-h*)))
   
   (unless (zerop (cadr (bounds-x (panel self))))
     (om-set-scroll-position (panel self)
                             (om-make-point (round (* (om-point-h (om-field-size (panel self)))
                                                      (/ (car (rangex (panel self)))
                                                         (cadr (bounds-x (panel self)))))) 0)))
    
   (om-set-view-position (preview self) (om-make-point 0 *titlebars-h*))
   (om-set-view-size (preview self) (om-make-point (w self) *preview-size*))
   (om-set-view-size  (control self) (om-make-point (w self) (get-control-h self)))
   (om-set-view-position (control self) (om-make-point 0 (- (h self) (get-control-h self))))
   (om-set-view-position (rulerx (panel self)) (om-make-point 0 (- (h self) 25 (get-control-h self))))
   (om-set-view-size (rulerx (panel self)) (om-make-point (w self) 25))
   (om-invalidate-view self))

(defmethod get-menubar ((self soundEditor)) 
  (list (om-make-menu "File" 
                      (list
                       (om-new-leafmenu  "Close" #'(lambda () (om-close-window (window self))) "w")
                       (list 
                        (om-new-leafmenu  "Import..." #'(lambda () (sound-import self)) nil))))
        (om-make-menu "Edit" 
                      (remove nil
                               (list
                       (om-new-leafmenu  "Select All" #'(lambda () (editor-select-all self)) "a")
                       (audio-undo-menu self)
                       (audio-edit-menu self)
                       (audio-effects-menu self)
                       )))
        (make-om-menu 'windows :editor self)
        (make-om-menu 'help :editor self)))


;;; REDEFINED FUNCTIONS
(defun audio-undo-menu (editor) nil)
(defun audio-edit-menu (editor) nil)
(defun audio-effects-menu (editor) nil)


(defmethod editor-null-event-handler :after ((self soundEditor))
   (do-editor-null-event self))

(defmethod do-editor-null-event ((self soundEditor))
   (when (om-view-contains-point-p (panel self) (om-mouse-position self))
     (om-with-focused-view (panel self) ;;(control self) 
       (let* ((pixel (om-mouse-position (panel self)))
              (point (pixel2point (panel self) pixel))
              (timestr (if (= 1000 (timeunit self)) 
                           (format () "t: ~4D s" (/ (om-point-h point) 1000.0))
                         (format () "t: ~D ms" (om-point-h point)))))
         (om-with-fg-color (panel self) (om-get-bg-color (panel self))
           (om-fill-rect (om-h-scroll-position (panel self)) 0 80 20))
         (om-with-font (om-make-font *om-score-font-face* (nth 1 *om-def-font-sizes*))
                       (om-draw-string (+ 6 (om-h-scroll-position (panel self))) 12 timestr))))))


;;;================================
;;; play-editor-mixin methods
;;;================================

(defmethod cursor-panes ((self soundeditor))
  (list (panel self)
        (preview self)))

(defmethod editor-play ((self soundEditor))
  (call-next-method)
  (update-play-buttons (control self)))

(defmethod editor-pause ((self soundEditor))
  (call-next-method)
  (update-play-buttons (control self)))

(defmethod editor-stop ((self soundEditor))
  (call-next-method)
  (update-play-buttons (control self)))

(defmethod get-interval-to-play ((self soundEditor))
  (let ((panel (panel self)))
    (if (and (equal :normal (cursor-mode panel)) (cursor-interval panel))
        (cursor-interval panel)
      (call-next-method))))

#|
(defmethod DoStopRecord ((self soundpanel))
  (let* ((soundfile (audio-record-stop (get-score-player self)))
         (editor (om-view-container self))
         (box (ref editor)))
    (when (and soundfile (probe-file soundfile))
      (let ((newsound (load-sound-file soundfile)))
        (setf (object (om-view-container self)) newsound)
        (when (is-boxpatch-p box)
          (setf (value box) newsound)
          (om-invalidate-view (car (frames box))))
        (update-editor-after-eval editor newsound)   
        ))
    (setf (state (player self)) :stop)
    ))
|#

;;;====================== 
;;; TITLE BAR / SOUND INFO
;;;======================

(defclass sound-titlebar (editor-titlebar) ())

(defmethod init-titlebar ((self soundeditor))
  (let* ((pathname (om-sound-file-name (object self)))
         (name (if pathname
                   (if (stringp (pathname-type pathname))
                       (string+ (pathname-name pathname) "." (pathname-type pathname))
                     (pathname-name pathname))
                 "No file attached"))) 
  (om-add-subviews (title-bar self)
                   (om-make-dialog-item 'om-static-text (om-make-point 10 4) 
                                        (om-make-point 
                                         (+ 10 (om-string-size (string+ (om-str :file) ": " name)
                                                               *om-default-font1b*))
                                         18)
                                        (string+ (om-str :file) ": " name)
                                        :bg-color *editor-bar-color*
                                        :font *om-default-font1b*)
                   (om-make-dialog-item 'om-static-text (om-make-point 400 4) (om-make-point 120 18)
                                        (format nil "Format: ~D" (or (om-format-name (om-sound-format (object self))) "--"))
                                        :bg-color *editor-bar-color*
                                        :font *om-default-font1*)
                   (om-make-dialog-item 'om-static-text (om-make-point 600 4) (om-make-point 80 18)
                                        (format nil "SR: ~D" (if (om-sound-sample-rate (object self))
                                                                 (round (om-sound-sample-rate (object self)))
                                                               "--"))
                                        :bg-color *editor-bar-color*
                                        :font *om-default-font1*)
                   (om-make-dialog-item 'om-static-text (om-make-point 700 4) (om-make-point 80 18)
                                        (format nil "SS: ~D" (or (om-sound-sample-size (object self)) "--"))
                                        :bg-color *editor-bar-color*
                                        :font *om-default-font1*))))


;;;======= 
;;; PANEL 
;;;=======

(defclass soundPanel (om-scroller view-with-ruler-x cursor-play-view-mixin om-view-drag) 
  ((mode :initform 0 :accessor mode)
   (selection? :initform nil :accessor selection?)
   (bounds-x :initform '(0 1) :accessor bounds-x :initarg :bounds-x))
  (:default-initargs
   #+win32 :draw-with-buffer #+win32 t))

;;; temp compatibilité
(defmethod (setf cursor-p) (val (self soundpanel))
  (setf (cursor-mode self) (if val :interval :normal)))
(defmethod cursor-p ((self soundpanel))
  (equal (cursor-mode self) :interval))

(defmethod editor ((self soundpanel)) (om-view-container self)) 

(defmethod om-view-scrolled ((self soundpanel) x y)
  (let ((oldrange (rangex self))
        (newx (round (* (/ x (om-point-h (om-field-size self))) (cadr (bounds-x self))))))
    (setf (rangex self)
          (list newx (+ newx (- (cadr oldrange) (car oldrange)))))
    (om-invalidate-view (rulerx self))
    (om-invalidate-view (preview (editor self)))))
 
(defmethod get-string-nom  ((Self soundpanel) Num Axe)
   (declare (ignore axe))
   (format nil "~,2F" (ms->sec num)))

(defmethod point2pixel ((self soundpanel) point sys-etat)
   "Convert 'point' to pixels in the view 'self', 'sys-etat' is calculated by the 'get-system-etat' function."
   (om-add-points (call-next-method) (om-scroll-position self)))
           

(defmethod assoc-w ((self soundpanel)) 
  (w self))
;   (om-point-h (om-field-size self)))

(defmethod pixel2point ((self soundpanel) pixel)
  (call-next-method self (om-subtract-points pixel (om-scroll-position self))))

(defmethod init-coor-system ((self soundpanel))
  (setf (rangex self) (copy-list (bounds-x self)))
  (set-units-ruler self (rulerx self))
  (update-subviews (om-view-container self)))

(defmethod scroll-play-window ((self soundPanel)) t)

;;;==================
;;; MARKERS 
;;;==================

(defmethod align-markers ((self soundpanel))
  (when (selection? self)
    (loop for i in (selection? self) do 
          (setf (nth i (markers (object (editor self))))
                (/ (* (zoom (rulerx self)) 
                      (round (* (nth i (markers (object (editor self)))) 1000) (zoom (rulerx self))))
                   1000.0)))
    (om-invalidate-view self)
    (report-modifications (editor self))))
          
(defmethod mrk-before ((self sound) t-s)
  (let ((b 0))
    (loop for m in (markers self) do
          (when (and (> m b) (<= m t-s)) (setf b m)))
    b))

(defmethod mrk-after ((self sound) t-s)
  (let ((a (/ (get-obj-dur self) 1000.0)))
    (loop for m in (markers self) do
          (when (and (< m a) (>= m t-s)) (setf a m)))
    a))
 
(defmethod special-move-marker ((Self soundPanel) Point)
  (let* ((thesound (object (om-view-container self)))
         (dur (/ (om-sound-n-samples  thesound) (om-sound-sample-rate  thesound)))
         (dec 6)
         (Xsize 80)
         (Mydialog (om-make-window 'om-dialog
                                   :size (om-make-point (+ xsize 110) 80)
                                   :window-title "Marker Onset"
                                   :maximize nil :minimize nil :resizable nil
                                   :bg-color *om-window-def-color*
                                   :position (om-add-points (om-view-position (window self)) (om-mouse-position self))))
         (Xed (om-make-dialog-item 'om-editable-text (om-make-point 10 30)  (om-make-point (- xsize 25) 16)
                                   (format nil "~F" (nth point (markers thesound)))
                                   :font *controls-font*)))
    (om-add-subviews mydialog 
                     xed
                     (om-make-dialog-item 'om-static-text (om-make-point 14 8) (om-make-point 50 16) "t (s)"
                                          :font *om-default-font2b*)
                     (om-make-dialog-item 'om-button (om-make-point (- (w mydialog) 80) 8) (om-make-point 70 15) "Cancel"
                                          :di-action (om-dialog-item-act item 
                                                       (declare (ignore item))
                                                       (om-return-from-modal-dialog mydialog ()))
                                          :focus nil
                                          :default-button nil)
                     (om-make-dialog-item 'om-button (om-make-point (- (w mydialog) 80) 34) (om-make-point 70 15) "OK"
                                          :di-action (om-dialog-item-act item 
                                                       (declare (ignore item))
                                                       (let ((val (read-from-string (om-dialog-item-text xed))))
                                                         (when (and (numberp val)
                                                                    (>= val 0)
                                                                    (<= val dur))
                                                           (setf (nth point (markers thesound)) val)
                                                           (setf (markers thesound)
                                                                 (remove-duplicates (sort (markers thesound) '<)))
                                                           (setf (selection? self) (list (position val (markers thesound))))
                                                           (report-modifications (editor self))))
                                                       
                                                       (om-return-from-modal-dialog mydialog ()))
                                          :default-button t
                                          ))
    (om-modal-dialog mydialog)))

;;;==================
;;; EVENTS
;;;;=================

(defmethod om-view-cursor ((self soundPanel))
   (if (equal (cursor-mode self) :interval)
       *om-i-beam-cursor*
     *om-arrow-cursor*))

(defmethod handle-key-event ((self soundPanel) char)
   (case char
     (#\g (grille-on-off self))
     (#\A (align-markers self))
     (#\h (show-help-window "Commands for SOUND Editor" (get-help-list (editor self))))
     (:om-key-delete (delete-sound-marker self))
     (:om-key-esc (reset-cursor self))
     (#\SPACE (editor-play/stop (editor self)))
     (otherwise (call-next-method))))

(defmethod reset-cursor ((self soundpanel))
  (setf (cursor-pos self) 0)
  (om-invalidate-view self))


(defmethod change-sound-pict ((self soundPanel))
  (let* ((thesound (object (om-view-container self))))
    (setf (pict-spectre? thesound) (not (pict-spectre? thesound)))
    (om-invalidate-view self t)))

(defmethod om-view-click-handler ((self soundPanel) where)
  (if (om-add-key-p) (add-sound-marker self where)
    (if (equal (cursor-mode self) :interval)
        (progn 
          (setf (selection? self) nil)
          (new-interval-cursor self where)
          )
      (let* ((graph-obj (click-in-sound-marker-p self where)))
        (setf (cursor-pos self) 0)
        (if graph-obj
            (if (om-shift-key-p) (omselect-with-shift self graph-obj)
              (when (not (member graph-obj (selection? self) :test 'equal))
                (setf (selection? self) (list graph-obj))
                (om-invalidate-view self t)))
          (unless (or (om-shift-key-p) (om-drag-selection-p self where))
            (setf (cursor-interval self) '(0 0))
            (control-actives self where)
            ))))))

(defmethod om-view-doubleclick-handler ((self soundPanel) Where)
  (if (equal (cursor-mode self) :interval) ; (cursor-p self)
      (progn
        (setf (cursor-pos self) (om-point-h (pixel2point self where)))
        (setf (cursor-interval self) (list (cursor-pos self) (cadr (bounds-x self))))
        (om-invalidate-view self t))
    (let ((Position-Obj (click-in-sound-marker-p self where)))
      (if Position-Obj
          (special-move-marker self position-obj)
        (when (markers (object (editor self)))
          (let* ((time (/ (om-point-h (pixel2point self where)) 1000.0))
                 (t1 (mrk-before (object (editor self)) time))
                 (t2 (mrk-after (object (editor self)) time)))
            (setf (cursor-interval self) (list (round (* t1 1000)) (round (* t2 1000))))
            (setf (cursor-pos self) (car (cursor-interval self)))
            )))
      (om-invalidate-view self t)
      )))

(defmethod control-actives ((self soundPanel) where)
  (unless (om-shift-key-p)
    (setf (selection? self) nil))
  (om-init-motion-functions self 'make-selection-rectangle 'release-selection-rectangle)
  (om-new-movable-object self (om-point-h where) (om-point-v where) 4 4 'om-selection-rectangle))

(defmethod make-selection-rectangle ((self soundPanel) pos)
  (let ((rect  (om-get-rect-movable-object self (om-point-h pos) (om-point-v pos))))
    (when rect
      (om-update-movable-object self (first rect) (second rect) (max 4 (third rect)) (max 4 (fourth rect))))))

(defmethod release-selection-rectangle ((self soundPanel) pos) 
  (let* ((rect (om-get-rect-movable-object self (om-point-h pos) (om-point-v pos)))
         (dur (cadr (bounds-x self)))
         minx maxx)
    (when rect
      (om-erase-movable-object self)
      (let (user-rect)
        (setf user-rect (om-make-rect  (first rect) (second rect) (+ (first rect) (third rect)) (+ (second rect) (fourth rect))))
        (setf minx (min (om-rect-left user-rect) (om-rect-right user-rect)))
        (setf maxx (max (om-rect-left user-rect) (om-rect-right user-rect)))
        (loop for item in (markers (object (editor self)))
              for k = 0 then (+ k 1) do
            (let ((marker-pix (round (* (om-point-h (om-field-size self)) item 1000) dur)))
              (when (and (>= marker-pix minx) (<= marker-pix maxx))
                (push k (selection? self))))))
      (om-invalidate-view self))
    ))

(defmethod omselect-with-shift ((self soundPanel) graph-obj)
  (if (member graph-obj (selection? self) :test 'equal)
    (setf (selection? self) (remove  graph-obj (selection? self) :test 'equal))
    (push graph-obj (selection? self)))
  (om-invalidate-view self))


(defmethod click-in-sound-marker-p ((self soundPanel) where &optional (approx 3))
  (let* ((thesound (object (om-view-container self)))
         (x (om-point-h where))
         dur rep)
    (when (and (valid-sound-p thesound) (numberp (om-sound-sample-rate thesound)))
        (setf dur (/ (om-sound-n-samples thesound) (om-sound-sample-rate  thesound)))
    (loop for item in (markers thesound)
          for i = 0 then (+ i 1)
          while (not rep) do
          (let ((pix (round (* (om-point-h (om-field-size self)) item) dur)))
            (when (and (> x (- pix approx) ) (< x (+ pix approx)) )
              (setf rep i))))
    rep)))

(defmethod add-sound-marker ((Self soundPanel) Where)
  (let* ((thesound (object (om-view-container self)))
         (point-x (om-point-h (pixel2point self where)))
         (newpoint (/ point-x 1000.0)))
    (setf (markers thesound) (remove-duplicates (sort (cons newpoint (markers thesound)) '<)))
    (setf (selection? self) (list (position newpoint (markers thesound))))
    (om-invalidate-view self t)
    (report-modifications (editor self))))

(defmethod delete-sound-marker ((Self soundPanel))
  (let* ((thesound (object (om-view-container self)))
         (copy (copy-list (markers thesound))))
    (loop for item in (selection? self) do
          (let ((list (remove (nth item copy) (markers thesound))))
            (setf (markers thesound) list)))
    (setf (selection? self) nil)
    (om-invalidate-view self t)
    (report-modifications (editor self))))

(defmethod editor-select-all ((self soundeditor)) 
  (let ((thesound (object self)))
    (setf (selection? (panel self) )
          (loop for item in  (markers thesound)
                for k = 0 then (+ k 1) collect k))
    (om-invalidate-view self t)))



;===================
;DRAW
;===================
; (capi::draw-metafile-to-image self (oa::themetafile (pic-to-draw thesound)) :width 1000 :height 1000)

(defparameter *zoom-steps* '((0 0) 
                             (500 10000) 
                             (900 5000)
                             (1750 2500)
                             (3000 1250)
                             (5000 1000)
                             (7500 500)
                             (14000 333.333)
                             (20000 250)
                             (25000 200)
                             (40000 100)
                             (80000 50)
                             (130000 33.3333)
                             (190000 25)
                             (250000 20)
                             (300000 nil)))

; (loop for n in (butlast (cdr *zoom-steps*)) collect (/ (car n) (cadr n)))
 
;;; tester avec un rapport constant entre xview et sr (env. xview/50)
(defun get-zoom-step (xview sr)
  (let ((n (cadr (find xview *zoom-steps* :test '>= :key 'car :from-end t))))
    (when n ;; IF N = NIL => TOO LONG (DRAW PICT) 
      (if (zerop n) 1  ;; N = 0 => SAMPLE ACCURATE
        (/ sr (float n))))))


(defmethod om-draw-contents ((self soundPanel))
  (call-next-method)  
  (if (equal (state (player (editor self))) :recording)
       (om-with-focused-view self  
         (om-with-fg-color self *om-red2-color*
           (om-with-font *om-default-font4b*
              (let ((halftext (round (om-string-size "Recording" *om-default-font4b*) 2)))
                (om-draw-string (- (round (w self) 2) halftext) (round (h self) 2) "Recording")))))
    (if (and (om-sound-file-name (object (om-view-container self)))
             (om-sound-sample-rate (object (om-view-container self)))) ;;; TEMP : crashes if there is a name but no actual sound
        (let* ((thesound (object (om-view-container self)))
               (sr (if (om-sound-las-using-srate-? thesound) 
                 las-srate
               (om-sound-sample-rate thesound)))
               (size (om-sound-n-samples-current thesound))
               (dur (or (and (and sr size)
                             (/ size sr)) 0))
               (dur-ms (round size (/ sr 1000.0)))
               (total-width (om-point-h (om-field-size self)))
               (thepicture (and dur (pic-to-draw thesound)))
               (window-h-size (om-point-h (om-view-size self)))
               (window-v-size (om-point-v (om-view-size self)))
               (stream-buffer (om-sound-sndbuffer thesound))
               (system-etat (get-system-etat self))
               (xmin (car (rangex self)))
               (pixmin (om-point-h (point2pixel self (om-make-point xmin 0) system-etat)))
               (xmax (cadr (rangex self)))
               (pixmax (om-point-h (point2pixel self (om-make-point xmax 0) system-etat)))
               (xview (- xmax xmin))
               (pict-threshold (if (> size (* 5 sr)) (/ dur-ms 3.0) 15000)) 
               (zoom-step (get-zoom-step xview sr)))

          (when (> xview pict-threshold) (setf zoom-step nil)) ;;; will draw-picture
          (om-with-focused-view self
            (when (and thesound thepicture)
              (om-with-fg-color self *om-dark-gray-color*
               ; (if (and zoom-step (not (pict-spectre? thesound)))
               ;     (om-draw-waveform self zoom-step)
               ;   (om-draw-picture self thepicture (om-make-point 0 0) (om-subtract-points (om-field-size self) (om-make-point 0 15)))
               ;   )

                (cond ((>= xview (* 3 (/ dur-ms 4))) 
                       (om-draw-picture self thepicture (om-make-point 0 0) (om-subtract-points (om-field-size self) (om-make-point 0 15))))
                      ((and (< xview (* 3 (/ dur-ms 4))) (>= xview (* 2 (/ dur-ms 4)))) 
                       (om-draw-picture self (aref (pict-zoom thesound) 0) (om-make-point 0 0) (om-subtract-points (om-field-size self) (om-make-point 0 15))))
                      ((and (< xview (* 2 (/ dur-ms 4))) (>= xview (/ dur-ms 4))) 
                       (om-draw-picture self (aref (pict-zoom thesound) 1) (om-make-point 0 0) (om-subtract-points (om-field-size self) (om-make-point 0 15))))
                      ((< xview (/ dur-ms 4))
                       (om-draw-picture self (aref (pict-zoom thesound) 2) (om-make-point 0 0) (om-subtract-points (om-field-size self) (om-make-point 0 15)))))

                (om-with-fg-color self *om-blue-color*
                  (loop for item in (markers thesound) 
                        for k = 0 then (+ k 1) do
                        (om-with-line-size (if (member k (selection? self)) 2 1)
                          (om-draw-line (round (* total-width item) dur) 0 (round (* total-width item) dur) (h self))
                          (om-fill-rect (- (round (* total-width item) dur) 2) 0 5 5)))))
              (when (grille-p self)
                (draw-grille self))
              (draw-interval-cursor self)
              (unless thepicture
                (if (and (om-sound-file-name thesound) (zerop dur))
                    (om-with-focused-view self
                      (om-draw-string 30 30 (format nil "Error: file ~s is empty" (om-sound-file-name (object (editor self))))))
                  (om-with-focused-view self 
                    (om-draw-string (round (w self) 2) (round (h self) 2) "..."))
                  )
                )))) 
      (om-with-focused-view self (om-draw-string 10 40 (format nil "No file loaded.."))))))


(defmethod om-draw-waveform ((self soundPanel) smpstep)
  (let* ((thesound (object (om-view-container self)))
         (maxsmp (om-sound-n-samples thesound))
         (sr (if (om-sound-las-using-srate-? thesound) 
                 las-srate
               (om-sound-sample-rate thesound)))
         (timestep (/ (/ sr 1000.0) smpstep))
         (nch (om-sound-n-channels thesound))
         (window-v-size (om-point-v (om-view-size self)))
         (stream-buffer (om-sound-sndbuffer thesound))
         (system-etat (get-system-etat self))
         (xmin (car (rangex self)))
         (pixmin (om-point-h (point2pixel self (om-make-point xmin 0) system-etat)))
         (xmax (cadr (rangex self)))
         (pixmax (om-point-h (point2pixel self (om-make-point xmax 0) system-etat)))
         (xtime (- xmax xmin))
         (nbpix (* xtime (round sr 1000)))
         (basicstep smpstep)
         (channels-h (round window-v-size nch))
         (offset-y (round channels-h 2))
         (datalist (loop for pt from 0 to (* timestep xtime) collect
                         (loop for chan from 0 to (- nch 1) collect 
                               (* 0.9 (fli::dereference stream-buffer 
                                                        :index (+ (* xmin (round sr 1000) nch) (round (* pt basicstep nch)) chan)
                                                        :type :float))))))

    (dotimes (i nch)  
      (om-draw-line pixmin (- (+ (* i channels-h) offset-y) 10) pixmax (- (+ (* i channels-h) offset-y) 10)))               
    (setf sampleprev (car datalist))
    (loop for sample in (cdr datalist)
          for i = 0 then (+ i 1) do 
          (loop for val in sample 
                for c = 0 then (+ c 1) do
                (setf pixpoint (round (* offset-y val))) ; scaled 0-1 --> 0 -->256/2
                (setf pixtime (om-point-h (point2pixel self (om-make-point (+ xmin (* i (/ 1 timestep)) (/ 1 timestep)) 0) system-etat)))
                (setf pixtimeprev (om-point-h (point2pixel self (om-make-point (+ xmin (* i (/ 1 timestep))) 0) system-etat)))
                (om-draw-line  pixtimeprev (- (+ offset-y (* c channels-h) (round (* offset-y (nth c sampleprev)))) 10)
                               pixtime (- (+ offset-y (* c channels-h) pixpoint) 10))
                ) 
          (setf sampleprev sample))))


(defmethod draw-grille  ((self soundpanel)) 
   (om-with-focused-view self
     (om-with-fg-color self *om-gray-color*
         (om-with-line '(2 2)
           ;(ruler-print-draw-grille (rulerx self) 'x 0 (om-h-scroll-position self) (get-system-etat self))
           (ruler-print-draw-grille (rulerx self) 'x 0 0 (get-system-etat self))
           ))))
   
(defmethod om-invalidate-view ((self soundpanel) &optional erase)
  (call-next-method)
  (om-invalidate-view (preview (editor self))))


;;;==============
;;; DRAG SOUND
;;;==============

(defmethod om-drag-selection-p ((self soundpanel) position) 
  (and (equal (cursor-mode self) :normal)
       (not (om-shift-key-p))
       (or (and (selection? self) (click-in-sound-marker-p self position))
           (and (cursor-interval self)
            (<= (om-point-h (pixel2point self position)) (cadr (cursor-interval self)))
            (>= (om-point-h (pixel2point self position)) (car (cursor-interval self)))))))

(defmethod om-view-drag-hilite-p ((self soundpanel)) nil)

(defmethod om-drag-container-view ((self soundpanel)) self)

(defmethod om-draw-contents-for-drag ((self soundpanel))
  (let ((m (dragged-list-objs *OM-drag&drop-handler*))
        (marks (markers (object (editor self)))))
    (cond ((and m (numberp m))
           (let ((pos (om-point-h (point2pixel self (om-make-big-point (round (* (nth m marks) 1000)) 0) (get-system-etat self)))))
             (om-with-fg-color nil (om-make-color-alpha 0.5 0.5 0.5 0.5)
               (om-fill-rect (- pos 2) 0 4 (h self))
               )))
          ((cursor-interval self)
           (let ((pos1 (om-point-h (point2pixel self (om-make-big-point (car (cursor-interval self)) 0) (get-system-etat self))))
                 (pos2 (om-point-h (point2pixel self (om-make-big-point (cadr (cursor-interval self)) 0) (get-system-etat self)))))
             (om-with-fg-color nil (om-make-color-alpha 0.5 0.5 0.5 0.5)
               (om-fill-rect pos1 0 (- pos2 pos1) (h self))
               )))
          (t nil))))

(defmethod om-drag-start ((self soundpanel))
  (when (om-drag-selection-p self (om-mouse-position self))
  (setf (dragged-view *OM-drag&drop-handler*) self
        (dragged-list-objs *OM-drag&drop-handler*) nil
        (container-view *OM-drag&drop-handler*) self
        (true-dragged-view *OM-drag&drop-handler*) self
        (drag-flavor *OM-drag&drop-handler*) :omvw)
  (let ((r (om-new-region))
        (marks (markers (object (editor self))))
        (m (click-in-sound-marker-p self (om-mouse-position self) 10)))
    (if m
        (progn 
          (setf (selection? self) (list m))
          (setf (dragged-list-objs *OM-drag&drop-handler*) m))
      (when (cursor-interval self)
        (setf r (om-set-rect-region r
                                    (+ (om-h-scroll-position self)
                                     )
                                    0 
                                    (om-point-h (point2pixel self (om-make-big-point (cadr (cursor-interval self)) 0) (get-system-etat self)))
                                       (h self))))
      )
    )
  ))
  

(defmethod extract-sound-selection ((self soundpanel) &optional filename)
  (let ((file (or filename (om-choose-new-file-dialog :prompt "Choose a New File" 
                                                      :directory *om-outfiles-folder*
                                                      ))
              ))
    (when file 
      (setf *last-saved-dir* (om-make-pathname :directory file))
      (save-sound (sound-cut (object (editor self)) (car (cursor-interval self)) (cadr (cursor-interval self)))
                  file))
    ))



(defmethod om-drag-receive ((target soundpanel) (dragged-ref t) position &optional (effect nil))
  (let ((dragged (dragged-view *OM-drag&drop-handler*)))
    (if (equal dragged target)
      (let* ((newpos (om-mouse-position target))
             (draggedobj (dragged-list-objs *OM-drag&drop-handler*)))
        (when (integerp draggedobj)
          (setf (nth draggedobj (markers (object (editor target))))
                (/ (om-point-h (pixel2point target newpos)) 1000.0))
          (om-invalidate-view target)
          (report-modifications (editor target))
          t
          ))
      )))


;;;============================
;;; SPECIAL AUDIO EDITOR TO PATCHPANEL

(defmethod om-drag-receive ((target patchpanel) (dragged-ref t) position &optional (effect nil))
  (let ((dragged (dragged-view *OM-drag&drop-handler*))
        (posi (om-mouse-position target)))
    (if (subtypep (class-name (class-of dragged)) 'soundpanel)
        (unless (integerp (car (selection? dragged)))
          (let* ((newsoundfile (extract-sound-selection dragged))
                 newsound newbox)
            (when newsoundfile (setf newsound (load-sound-file newsoundfile)))
            (when newsound
              (setf newbox (make-instance 'OMBoxEditCall
                                          :name "sound extract"
                                          :reference (class-of newsound) 
                                          :icon (icon (class-of newsound))
                                          :inputs (get-inputs-from-inst newsound)))
              (setf (value newbox) newsound)
              (set-edition-params (value newbox) newbox)
              (push newbox (attached-objs (class-of newsound)))
              (setf (numouts newbox) (length (get-outs-name (value newbox))))
              (setf (frame-position newbox) 
                    (borne-position posi))
              (loop for item in (get-actives target) do
                    (omG-unselect item))
              (let ((new-frame (make-frame-from-callobj newbox)))
                (omG-add-element target new-frame)
                (omG-select new-frame))
              )
            (om-invalidate-view target)
            t
            ))
      (call-next-method))))





