
;;; MIDI FUNCTIONS IN OM PATCHES
;;; THAT SEND EVENTS...

(in-package :om)

;================================
; MIDI - Send
;================================

(defmethod* midi-o ((bytes list) &optional port)
   :icon 912
   :indoc '("data bytes" "output port number")
   :initvals '((144 60 64) nil)
   :doc "Sends <bytes> out of the port number <port>. 
"
   (when bytes
     (unless port (setf port *outmidiport*))
     
     (if (list-subtypep bytes 'list)
       (if (integerp port)
         (loop for item in bytes do
               (midi-o item port))
         (loop for item in bytes 
               for item1 in port do
               (midi-o item item1)))
       
       (loop for aport in (list! port) do
             (let ((event (om-midi-new-evt (om-midi-get-num-from-type "Stream") :port aport :bytes bytes)))
               (when event (om-midi-send-evt event *midiplayer*)) 
               t)))))

;===================PITCHBEND & WHEEL

(defmethod* pitchwheel ((vals number) (chans number) &optional port)
   :icon 912
   :indoc '("pitch wheel value(s)" "MIDI channel(s) (1-16)" "output port number")
   :initvals '(0 1 nil)
   :doc "Sends one or more MIDI pitch wheel message(s) of <vals> in the MIDI channel(s) <chans>.  

<values> and <chans> can be single numbers or lists. 

The range of pitch wheel is between -8192 and 8190.
"
   (unless port (setf port *outmidiport*))
   (setf port (list! port))
   (loop for aport in port do
         (let ((event (om-midi-new-evt (om-midi-get-num-from-type "PitchWheel")
                                                                  :chan (- chans 1) :port aport 
                                                                  :bend vals)))
           (when event (om-midi-send-evt event *midiplayer*))
	   t)))

(defmethod* pitchwheel ((vals number) (chans list) &optional port)
   (loop for item in chans do
         (pitchwheel vals item port)))

(defmethod* pitchwheel ((vals list) (chans list) &optional port)
   (loop for item in chans 
         for item1 in vals do
         (pitchwheel item1 item port)))

;------------------------

;==== MODIFIED FUNCTION
(defmethod* pitchbend ((vals number) (chans number) &optional port)
   :icon 912
   :indoc '("pitch bend value(s)" "MIDI channel(s) (1-16)" "output port number")
   :initvals '(0 1 nil)
   :doc "Sends one or more MIDI pitch bend message(s) of <vals> in the MIDI channel(s) <chans>.  

<values> and <chans> can be single numbers or lists. 

The range of pitch wheel is between 0 and 127.
"
   (unless port (setf port *outmidiport*))
   (pitchwheel (round (* (/ vals 127) 16382 )) chans port))

(defmethod* pitchbend ((vals number) (chans list) &optional port)
   (loop for item in chans do
         (pitchbend vals item port)))

(defmethod* pitchbend ((vals list) (chans list) &optional port)
   (loop for item in chans 
         for item1 in vals do
         (pitchbend item1 item port)))

;===================PGCHANGE

;===== MODIFIED FUNCTION =====
(defmethod* pgmout ((progm integer) (chans integer) &optional port) 
   :icon 912
   :indoc '("program number" "MIDI channel(s)" "output port number")
   :initvals '(2 1 nil)
   :doc "Sends a program change event with program number <progm> to channel(s) <chans>.

<progm> and <chans> can be single numbers or lists."
   (unless port (setf port *outmidiport*))
   (setf port (list! port))
   (loop for aport in port do
         (let ((event (om-midi-new-evt (om-midi-get-num-from-type "ProgChange")
                                                                  :chan (- chans 1) :port aport
                                                                  :pgm progm)))
           (when event (om-midi-send-evt event *midiplayer*)))))

(defmethod* pgmout ((progm number) (chans list) &optional port)
  (loop for item in chans do
        (pgmout progm item port)))

(defmethod* pgmout ((progm list) (chans list) &optional port)
   (if (or (null port) (integerp port))
     (loop for item in chans 
           for item1 in progm do
           (pgmout item1 item port))
     (loop for item in chans 
           for item1 in progm
           for item2 in port do
           (pgmout item1 item item2))))


;===================POLY KEY PRESSURE
(defmethod* polyKeypres ((values integer) (pitch integer) (chans integer) &optional port) 
   :icon 912
   :indoc '("pressure value" "target pitch" "MIDI channel (1-16)" "output port number")
   :initvals '(100 6000 1 nil)
   :doc "
Sends a key pressure event with pressure <values> and <pitch> on channel <cahns> and port <port>.

Arguments can be single numbers or lists.
"
   (unless port (setf port *outmidiport*))
   (setf port (list! port))
   (loop for aport in port do
         (let ((event (om-midi-new-evt (om-midi-get-num-from-type "KeyPress")
                                                                  :chan (- chans 1) :port aport
                                                                  :kpress values :pitch (round pitch 100))))
           (when event (om-midi-send-evt event *midiplayer*)))))

(defmethod* polyKeypres ((values list) (pitch list) (chans list) &optional port)
   (loop for item in pitch
         for val in values
         for chan in chans do
         (polyKeypres val item chan port)))

(defmethod* polyKeypres ((values integer) (pitch list) (chans integer) &optional port)
   (loop for item in pitch  do
         (polyKeypres values item chans port)))

(defmethod* polyKeypres ((values integer) (pitch list) (chans list) &optional port)
   (loop for item in pitch
         for chan in chans do
         (polyKeypres values item chan port)))

(defmethod* polyKeypres ((values integer) (pitch list) (chans list) &optional port)
   (loop for val in values do
         (polyKeypres val pitch chans port)))

(defmethod* polyKeypres ((values list) (pitch integer) (chans list) &optional port)
   (loop for val in values
         for chan in chans do
         (polyKeypres val pitch chan port)))

(defmethod* polyKeypres ((values list) (pitch integer) (chans integer) &optional port)
   (loop  for val in values do
          (polyKeypres val pitch chans port)))

(defmethod* polyKeypres ((values list) (pitch list) (chans integer) &optional port)
   (loop for item in pitch
         for val in values do
         (polyKeypres val item chans port)))



;======================AFTER TOUCH
(defmethod* aftertouch ((val integer) (chans integer) &optional port) 
   :icon 912
   :indoc '("pressurev value"  "MIDI channel (1-16)" "output port number")
   :initvals '(100 1 nil)
   :doc "Sends an after touch event of <val> to channel <chans> and port <port>.

Arguments can be can be single numbers or lists.
"
   (unless port (setf port *outmidiport*))
   (setf port (list! port))
   (loop for aport in port do
         (let ((event (om-midi-new-evt (om-midi-get-num-from-type "ChanPress")
                                                                  :chan (- chans 1) :port aport
                                                                  :param val)))
               (when event (om-midi-send-evt event *midiplayer*)))))

(defmethod* aftertouch ((values number) (chans list) &optional port)
  (loop for item in chans do
        (aftertouch values item port)))

(defmethod* aftertouch ((values list) (chans list) &optional port)
   (if (or (null port) (integerp port))
     (loop for item in values
           for val in chans do
           (aftertouch item val port))
     (loop for item in values
           for val in chans
           for item2 in port do
           (aftertouch item val item2))))


;======================CTRL CHANGE 
(defmethod* ctrlchg ((ctrlnum integer) (val integer) (chans integer) &optional port) 
   :icon 912
   :indoc '("control number"  "value" "MIDI channel (1-16)" "output port number")
   :initvals '(7 100 1 nil)
   :doc "Sends a control change event with control number <ctrlnum> and value <val> to channel <chans> (and port <port>)."
   (unless port (setf port *outmidiport*))
   (setf port (list! port))
   (loop for aport in port do
         (let ((event (om-midi-new-evt (om-midi-get-num-from-type "CtrlChange")
                                                                  :chan (- chans 1) :port aport
                                                                  :ctrlchange (list ctrlnum val))))
           (when event (om-midi-send-evt event *midiplayer*)))))

(defmethod* ctrlchg ((ctrlnum integer) (val integer) (chans list) &optional port) 
  (loop for item in chans do
        (ctrlchg  ctrlnum val item port)))

(defmethod* ctrlchg ((ctrlnum list) (val list) (chans list) &optional port) 
  (loop for ctrl in ctrlnum
        for item in chans
        for aval in val do
        (ctrlchg  ctrl aval item port)))

(defmethod* ctrlchg ((ctrlnum list) (val list) (chans integer) &optional port) 
  (loop for ctrl in ctrlnum
        for aval in val do
        (ctrlchg  ctrl aval chans port)))

(defmethod* ctrlchg ((ctrlnum list) (val integer) (chans integer) &optional port) 
  (loop for ctrl in ctrlnum do
        (ctrlchg  ctrl val chans port)))

(defmethod* ctrlchg ((ctrlnum integer) (val integer) (chans list) &optional port) 
  (loop  for item in chans do
        (ctrlchg  ctrlnum val item port)))

(defmethod* ctrlchg ((ctrlnum list) (val integer) (chans list) &optional port) 
  (loop for ctrl in ctrlnum
        for item in chans do
        (ctrlchg  ctrl val item port)))

(defmethod* ctrlchg ((ctrlnum integer) (val list) (chans list) &optional port) 
  (loop for item in chans
        for aval in val do
        (ctrlchg  ctrlnum aval item port)))







;======================VOLUME 
(defmethod* volume ((vol integer) (chans integer) &optional port) 
   :icon 912
   :indoc '("value" "MIDI channel (1-16)" "output port number")
   :initvals '(100 1 nil)
   :doc "Sends MIDI volume message(s) to channel(s) <chans> and port <port>.

Arguments can be numbers or lists. 

The range of volume values is 0-127.
"
   (unless port (setf port *outmidiport*))
   (setf port (list! port))
   (loop for aport in port do
         (let ((event (om-midi-new-evt (om-midi-get-num-from-type "CtrlChange")
                                                                  :chan (- chans 1) :port aport
                                                                  :ctrlchange (list 7 vol))))
             (when event (om-midi-send-evt event *midiplayer*)))))

(defmethod* volume ((volume number)  (chans list) &optional port)
  (loop for item in chans do
        (volume volume item port)))

(defmethod* volume ((volume list)  (chans list) &optional port)
   (if (or (null port) (integerp port))
     (loop for item in volume
           for val in chans do
           (volume item val port))
     (loop for item in volume
           for val in chans
           for item2 in port do
           (volume item val item2))))


;======================SYSTEME EXCLUSIVE
(defmethod* sysex ((databytes list) &optional port) 
   :icon 912
   :indoc '("data bytes" "output port number")
   :initvals '((1 1 1 ) nil)
   :doc "Sends a system exclusive MIDI message on <port> with any number of data bytes, leading $F0 and tailing $F7"
   (when databytes
     (unless port (setf port *outmidiport*))
     (if (list-subtypep databytes 'list)
       (if (integerp port)
         (loop for item in databytes do
               (sysex item port))
         (loop for item in databytes 
               for item1 in port do
               (sysex item item1)))
       (loop for aport in (list! port) do
             (let ((event (om-midi-new-evt (om-midi-get-num-from-type "SysEx") :port aport :bytes databytes)))
               (when event (om-midi-send-evt event *midiplayer*)))))))


;======================RESET
(defmethod* midi-reset (port)
   :icon 912
   :indoc '("ouput MIDI port")
   :initvals '(0)
   :doc "Sends a MIDI Reset message on port <port>."
   (loop for chan from 0 to 15 do 
         (let ((event (om-midi-new-evt (om-midi-get-num-from-type "Reset") :port (or port *outmidiport*) :chan chan)))
           (when event (om-midi-send-evt event *midiplayer*))))
   nil)


;======================SEND ONE NOTE
(defmethod! send-midi-note (port chan pitch vel dur track)
   :icon 148
   :initvals '(0 1 60 100 1000 1)
   (when (< dur 65000)
     (let ((event (om-midi-new-evt (om-midi-get-num-from-type "Note") :port port :chan chan
                                                              :date 0 :ref track
                                                              :vals (list pitch vel dur)
                                                              )))
           (when event (om-midi-send-evt event *midiplayer*)))
     ))


; (send-midi-note 0 1 60 100 1000 1)


