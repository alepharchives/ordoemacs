
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; ordo-mode -- view / edit encrypted files in GNU Emacs.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Copyright (c) 2000 David James Riddoch <david@riddoch.org.uk>
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
;;
;; Available from: http://www.riddoch.org.uk/software/
;;
;; $Id: ordo.el,v 1.1 2001/12/21 12:07:05 djr23 Exp $
;;


;;;;;;;;;;;;;;;;;
;; Introduction
;;
;; ordo-mode is a minor mode for GNU Emacs, which provides a means to view
;; or edit encrypted files conveniently and reasonably securely.  When you
;; save a buffer in ordo-mode, the buffer is transparently encrypted before
;; being written to disk.
;;
;; It is built on top of mailcrypt, and hence supports the same methods of
;; encryption as mailcrypt (namely PGP and GPG).
;;
;; ordo-mode is inspired by `ordoemacs' from Neal Stephenson's
;; "Cryptonomicon".
;;
;; A similar job is done by the crypt++ emacs package.
;;


;;;;;;;;;;;;;;;;;;;;;;;;;
;; Installing ordo-mode
;;
;; Firstly mailcrypt must be installed and configured.  It is available
;; from:
;;
;;   http://www.nb.net/~lbudney/linux/software/mailcrypt.html
;;
;; This file should be renamed ordo.el, and placed in a directory which is
;; on the emacs load-path.  For example I put it in ~/emacs/, and add that
;; directory to the load-path as follows (in ~/.emacs):
;;
;;      (setq load-path (append (list (concat (getenv "HOME") "/emacs"))
;;                              load-path))
;;
;; Then add the following lines to ~/.emacs
;;
;;      (autoload 'ordo "ordo" nil t)
;;      (autoload 'ordoify "ordo" nil t)
;;      (autoload 'ordo-mode "ordo" nil t)
;;
;; I also add the following line to ensure that ordo uses my public key for
;; encryption (without prompting).
;;
;;      (setq ordo-mode-default-recipient "david james riddoch")
;;


;;;;;;;;;;;;;;;;;;;;
;; Using ordo-mode
;;
;; ordo-mode does not auto-load by default.
;;
;; To decrypt an encrypted file for editing or viewing:
;;
;;   o  load the encrypted file into an emacs buffer
;;   o  M-x ordo
;;
;; You will be prompted to enter the passphrase.  By default mailcrypt will
;; remember the passphrase for up to 60 seconds.  See the mailcrypt
;; documentation for more details.
;;
;; You can then edit and save the contents of the buffer.  When the buffer
;; is saved, it is first re-encrypted.  In theory the plain text will never
;; be written to disk.  See 'Caveats' below.
;;
;; To create a new encrypted buffer from a plain-text buffer:
;;
;;   o  M-x ordoify
;;
;; You will be prompted for a filename into which the encrypted file will
;; be saved.
;;


;;;;;;;;;;;;
;; Caveats
;;
;; ordo-mode and mailcrypt are pretty careful, but should not be considered
;; to be 100% secure.  Here are some examples of how you might be stung:
;;
;; You *must* only run ordo-mode on an emacs session that is running on the
;; local machine, or over a secure network connection.  Otherwise your
;; plaintext and passphrase may be 'snooped' by someone on the network.
;; This also applies to any other passwords you type when interacting over
;; a network.
;;
;; Emacs stores the buffer as plaintext in memory.  This can be accessed by
;; someone else by:
;;
;;    a) attaching to emacs with a debugger and reading the memory directly
;;      (only accessible by root or anyone who breaks into your account --
;;      which is *much* easier than breaking the encryption).
;;
;;    b) if emacs crashes (unlikely but possible) then the plaintext would
;;      be written into a core file.  Again accessible by root or someone
;;      who has broken into your account.
;;
;;    c) parts of emacs' memory might be swapped out onto disk.  Probably
;;    only accessible by root.
;;
;; When you kill a buffer, no attempt is made to overwrite the memory that
;; contained the plaintext.  Thus you are still vunerable to the above
;; attacks.  Likewise mailcrypt does not guarentee that the passphrase will
;; be entirely removed from memory (and may be trivially retrieved with M-x
;; view-lossage).  Anyone fancy modifying emacs to provide a way to thwart
;; this?
;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; notes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Consider making filename for ordo buffers 'magic' as an alternative way
;; of hooking attempts to save ordo buffers.  See:
;; http://www.cl.cam.ac.uk/texinfodoc/elisp_23.html#SEC323
;;
;; Main problem with this is making it optional (per buffer) ...
;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Configurable options.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar ordo-mode-default-recipient nil
  "Set to the name(s) of the public key(s) in your keyring that should be
used for encryption.  If not set you will be prompted.")

(defvar ordo-suffix-alist nil
  "List of suffixes that ordo recognises as containing encrypted files.
Defaults to ordo, pgp and gpg (do not include the period '.'")

(or ordo-suffix-alist (setq ordo-suffix-alist '("ordo" "pgp" "gpg")))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Stuff to do at load time
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(autoload 'mc-decrypt "mc-toplev" nil t)
(autoload 'mc-encrypt-generic "mc-toplev" nil t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; ordo-mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar ordo-mode-string " ordo"
  "*String to put in mode line when ordo-mode is active.")

(make-variable-buffer-local 'ordo-mode)

(defvar ordo-mode nil
  "Non-nil means ordo mode is active.")

(defvar ordo-mode-map nil
  "Keymap for ordo-mode bindings.")

(or ordo-mode-map
    (progn
      (setq ordo-mode-map (make-sparse-keymap))
      (define-key ordo-mode-map "\C-x\C-w" 'ordo-write-file)
      ))

;; ?? We would like to search active maps for all bindings to
;; write-file.  We could then have a taylored keymap, that overrode
;; each of those bindings ... tricky.

(or (assq 'ordo-mode minor-mode-map-alist)
    (setq minor-mode-map-alist
	  (cons (cons 'ordo-mode ordo-mode-map)
		minor-mode-map-alist)))

(or (assq 'ordo-mode minor-mode-alist)
    (setq minor-mode-alist
	  (cons '(ordo-mode ordo-mode-string) minor-mode-alist)))


(defun ordo-mode (&optional arg)
  "Ordo is an encryption wrapper for emacs.  It allows you to open
encrypted files, decrypt and edit them, and save them back to
disk in encrypted form.  Ordo ensures that the plaintext is never
written to disk (modulo emacs itself being paged).

Ordo is inspired by 'ordoemacs' from Neal Stephenson's Cryptonomicon."
  (interactive)

  (let ((new-ordo-mode (if (null arg) (not ordo-mode)
			  (> (prefix-numeric-value arg) 0))))
    (if	new-ordo-mode (ordo-mode-on) (ordo-mode-off))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; ordo functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ordo-strip-ordo-suffix (filename)
  "Ordo internal function.  Strips any suffix in ordo-suffix-alist
from the given filename."

  (let ((s ordo-suffix-alist)
	eofn
	(result filename))
    (while s
      (setq eofn (string-match (concat "\\." (car s)  "$") filename))
      (if eofn
	  (progn
	    (setq result (substring filename 0 eofn))
	    (setq s nil))
	(setq s (cdr s))))

    result))


(defun ordo-has-ordo-suffix (filename)
  "Ordo internal function.  Returns t if filename has an ordo suffix."

  (let ((s ordo-suffix-alist)
	eofn
	(result nil))
    (while s
      (setq eofn (string-match (concat "\\." (car s)  "$") filename))
      (if eofn
	  (progn
	    (setq result t)
	    (setq s nil))
	(setq s (cdr s))))

    result))


(defun ordo-set-auto-mode ()
  "Ordo internal function.  Set the major-mode according to the
file name minus any ordo suffix."

  (when buffer-file-name
    (let* ((fn buffer-file-name)
	   (fnss (ordo-strip-ordo-suffix buffer-file-name)))

      (setq buffer-file-name fnss)
      (set-auto-mode t)
      (setq buffer-file-name fn))))


(defun ordo-mode-on1 ()
  "Ordo internal function to switch on ordo-mode."

  (setq ordo-mode t)

  ;; ?? It would be nice if autosaving worked, but we cannot easily
  ;; hook the auto-save mechanism.  It may be necassary to use 'magic'
  ;; files to do this...
  ;;  Whatever -- it should be a global 'ordo' option.
  ;;  Or consider 'backup-enable-predicate'.
  (setq buffer-auto-save-file-name nil)

  ;; We want to catch _all_ attempts to save this buffer, and do
  ;; so via the encrypted buffer ... I'm not at all sure this
  ;; will catch everything though.
  (or (memq 'ordo-write-file-hook local-write-file-hooks)
      (setq local-write-file-hooks 
	    (cons 'ordo-write-file-hook local-write-file-hooks))))


(defun ordo-mode-off-no-prompt ()
  "Ordo internal function to detach from the encrypted buffer and
switch off ordo-mode."

  (setq buffer-file-name nil)
  (setq ordo-mode nil)
  (setq local-write-file-hooks 
	(delq 'ordo-write-file-hook local-write-file-hooks))
  )


(defun ordo-write-file-hook ()
  "Ordo internal function to write an ordo buffer through
the encrypted buffer."

  ;; ?? Ought to behave sensibly if file is not writable.  At
  ;; the moment we just get an error.

  ;; ?? We also barf if buffer has no buffer-file-name.

  (if (not ordo-mode) (error "Ooops!  Not in ordo-mode!"))

  (if (not buffer-file-name) (error "Ooops!  Buffer is not visiting a file"))

  (let* ((eb (generate-new-buffer "ordo"))
	 (filename buffer-file-name))
    (unwind-protect
	(progn
	  (copy-to-buffer eb (point-min) (point-max))
	  (save-excursion
	    (set-buffer eb)
	    (mc-encrypt-generic ordo-mode-default-recipient)
	    ;; ?? We would like to use the same recipient that was used
	    ;; to decrypt.  If we can't get that info, then prompt the
	    ;; first time, and save the value.  We could also allow the
	    ;; user to set a default in their .emacs.
	    (write-region (point-min) (point-max) filename)
	    ))
      (kill-buffer eb)
      )

    ;; Mark buffer as unmodified, update the modtime (to stop emacs
    ;; thinking it's been modified under our feet), and return non-nil
    ;; to indicate that we have indeed saved the file.
    (set-buffer-modified-p nil)
    (set-visited-file-modtime)
    t
    ))


(defun ordo-write-file (filename &optional confirm)
  "Ordo replacement for (write-file)."
;;  (interactive "FWrite file: ")
  (interactive
   (list (if buffer-file-name
	     (read-file-name "Write file: " nil nil nil nil)
	   (read-file-name "Write file: " default-directory
			   (expand-file-name
			    (file-name-nondirectory (buffer-name))
			    default-directory)
			   nil nil))
	 (not current-prefix-arg)))

  (or (null filename) (string-equal filename "")
      (progn
	;; If arg is just a directory,
	;; use the default file name, but in that directory.
	(if (file-directory-p filename)
	    (setq filename (concat (file-name-as-directory filename)
				   (file-name-nondirectory
				    (or buffer-file-name (buffer-name))))))
	(and confirm
	     (file-exists-p filename)
	     (or (y-or-n-p (format "File `%s' exists; overwrite? " filename))
		 (error "Canceled")))

	;; If filename has an ordo suffix, then go ahead and save
	;; it encrypted as usual.  Otherwise prompt to see what
	;; they wanna do ...

	(if (ordo-has-ordo-suffix filename)
	    (ordo-write-file-encrypted filename confirm)
	  (ordo-query-write-file filename confirm))
	)))


(defun ordo-write-file-encrypted (filename confirm)
  "Ordo internal function.  Writes an ordo buffer to a new file,
keeping it encrypted."

  (set-visited-file-name filename (not confirm))

  ;; The above trashes everything about the buffer, so we
  ;; reset all the state.

  (ordo-set-auto-mode)
  (ordo-mode-on1)

  ;; Mark as modified, and save!
  (and buffer-file-name
       (file-writable-p buffer-file-name)
       (setq buffer-read-only nil))
  (save-buffer))


(defun ordo-query-write-file (filename confirm)
  "Ordo internal function.  Ask user whether they want to write the
file encrypted or as plaintext."

  (let ((char))

    (message "Write (e)ncrypted or (p)laintext? ")
    (while (not (memq (setq char (downcase (read-char)))
		      '(?e ?p)))
      (beep)
      (message "Please enter e, p or C-g ...")
      (sit-for 1)
      (message "Write (e)ncrypted or (p)laintext? "))
    (if (= char ?e) (ordo-write-file-encrypted filename confirm))
    (if (= char ?p) (write-file filename confirm))
    ))


(defun ordo-do-decrypt ()
  "Ordo internal function to decrypt a buffer."

  ;; Switch off autosaving for the mo' (we don't want the plaintext
  ;; to be saved by accident!)
  (setq buffer-auto-save-file-name nil)

  ;; Preserve clean-ness and read-only-ness.

  (let ((read-only buffer-read-only)
	(clean (not (buffer-modified-p))))

    (if read-only (setq buffer-read-only nil))
    (unwind-protect
	(mc-decrypt)
      (if clean (set-buffer-modified-p nil))
      (if read-only (setq buffer-read-only t))
      )))


(defun ordo-mode-on ()
  "Ordo internal function.  Switch on ordo-mode."

  (if ordo-mode (error "This buffer is already in ordo-mode"))

  (ordo t))


(defun ordo-mode-off ()
  "Ordo internal function.  Switch off ordo-mode."

  (if (not ordo-mode) (error "This buffer is not in ordo-mode"))

  (if (yes-or-no-p "Really switch off ordo-mode? ")
      (ordo-mode-off-no-prompt)))


(defun ordo (&optional already-decrypted)
  "Decrypt buffer contents and switch on ordo-mode."
  (interactive)

  (if ordo-mode (error "This buffer is already in ordo-mode"))

  (unless already-decrypted (ordo-do-decrypt))

  (ordo-set-auto-mode)

  (ordo-mode-on1)
  )


(defun ordoify ()
  "Encrypt the contents of the current buffer, and switch on
ordo-mode.  Prompts for a filename to save the encrypted
contents into."
  (interactive)

  (if ordo-mode (error "This buffer is already in ordo-mode"))

  (let ((filename
	(if buffer-file-name
	    (read-file-name "Store encrypted buffer in: " nil nil nil nil)
	  (read-file-name "Store encrypted buffer in: " default-directory
			  (expand-file-name
			   (file-name-nondirectory (buffer-name))
			   default-directory)
			  nil nil))))

    (set-visited-file-name filename)
    (ordo-set-auto-mode)
    (ordo-mode-on1)))

