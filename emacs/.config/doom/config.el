;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you (e.g. GPG configuration, email
;; clients, file templates and snippets). It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `variable-pitch' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
(setq doom-font (font-spec :family "CaskaydiaCove Nerd Font" :size 16))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-one)
(setq doom-theme 'doom-tokyo-night)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Dropbox/org/")
(setq org-roam-directory "~/Dropbox/org/roam/")

;; Only list task files so the agenda stays fast (don't scan roam nodes).
(setq org-agenda-files '("~/Dropbox/org/inbox.org"
                         "~/Dropbox/org/todo.org"))

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;; - Setting file/directory variables (like `org-directory')
;; - Setting variables which explicitly tell you to set them before their
;;   package is loaded (see 'C-h v VARIABLE' to check this)
;; - Setting doom variables (which start with 'doom-' or '+')
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; --- Remote editing on vulcan (TRAMP + eglot) ---
;; Open files as /ssh:vulcan:~/src/...; eglot starts rust-analyzer on vulcan.
(after! tramp
  ;; Use the remote login shell's PATH so eglot can find ~/.cargo/bin/rust-analyzer
  ;; (TRAMP's default remote path skips per-user bin directories).
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path)
  ;; Multiplex everything over one persistent ssh connection instead of paying
  ;; connection setup per operation — the single biggest TRAMP latency win.
  (setq tramp-ssh-controlmaster-options
        "-o ControlMaster=auto -o ControlPath=~/.ssh/tramp.%%C -o ControlPersist=yes")
  ;; Skip lock files on remote saves; they cost a round-trip each and only
  ;; matter when multiple Emacsen edit the same remote file.
  (setq remote-file-name-inhibit-locks t))

;; rustic-mode hangs Emacs when opening Rust files over TRAMP (it shells out to
;; cargo/rustc during mode setup, which stalls on remote buffers). Remote .rs
;; files get plain rust-mode + eglot instead; local files keep rustic.
(defun +my/rust-mode-dispatch ()
  "Use rust-mode for TRAMP buffers, rustic-mode locally."
  (if (and buffer-file-name (file-remote-p buffer-file-name))
      (rust-mode)
    (rustic-mode)))
(add-to-list 'auto-mode-alist '("\\.rs\\'" . +my/rust-mode-dispatch))
(add-hook 'rust-mode-hook
          (lambda () (when (file-remote-p default-directory) (eglot-ensure))))

;; Open treemacs from anywhere (incl. the dashboard) without project detection.
;; Unlike `+treemacs/toggle' (SPC o p), the raw `treemacs' command just shows the
;; tree so you can navigate and open a file.
(map! :leader
      :desc "Treemacs" "t t" #'treemacs)

;; Size the initial frame to 55% width / 75% height of the display, centered.
;; Uses `display-pixel-width'/-height' so it stays correct on any monitor.
(defun +my/set-frame-size-and-center ()
  (let* ((frame-w (round (* 0.55 (display-pixel-width))))
         (frame-h (round (* 0.75 (display-pixel-height))))
         (frame-x (round (/ (- (display-pixel-width) frame-w) 2)))
         (frame-y (round (/ (- (display-pixel-height) frame-h) 2))))
    (set-frame-position (selected-frame) frame-x frame-y)
    (set-frame-size (selected-frame) frame-w frame-h t)))

(add-hook 'window-setup-hook #'+my/set-frame-size-and-center)

;; --- C development ---------------------------------------------------------

;; Xcode's Command Line Tools ship clangd, clang-format and lldb-dap, but only
;; clangd is symlinked into /usr/bin -- the rest live in the CLT bin directory,
;; which is not on PATH. Append it (so Homebrew still wins for anything it also
;; provides) rather than editing the shell profile, keeping the fix inside Emacs.
(when (eq system-type 'darwin)
  (let ((clt "/Library/Developer/CommandLineTools/usr/bin"))
    (when (file-directory-p clt)
      (add-to-list 'exec-path clt t)
      (setenv "PATH" (concat (getenv "PATH") ":" clt)))))

;; 4-space indent, no tabs. cc-mode and the tree-sitter mode keep separate
;; offset variables, so both have to be set.
;;
;; `c-basic-offset' is deliberately set globally rather than inside an
;; `after! cc-mode' block: apheleia builds its clang-format invocation as
;; "--style={IndentWidth: %d}" from `c-basic-offset', but C files open in
;; `c-ts-mode', where cc-mode never loads and the variable would be VOID --
;; which makes format-on-save fail outright. Setting the default keeps
;; clang-format's indent width agreed with the editor's.
(setq-default c-basic-offset 4)
(setq c-ts-mode-indent-offset 4)
(add-hook! '(c-mode-hook c-ts-mode-hook)
  (setq indent-tabs-mode nil))

;; clangd flags. --clang-tidy adds real bug detection (not just syntax) on top
;; of the compiler's own warnings, which is worth a lot while learning C.
;; --header-insertion=never stops it silently adding #includes you didn't type.
(after! eglot
  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode c++-mode c++-ts-mode)
                 . ("clangd" "--background-index" "--clang-tidy"
                    "--header-insertion=never" "--completion-style=detailed"))))

(defun +my/c--build-and-run (extra-flags &optional compiler)
  "Compile the current C file with EXTRA-FLAGS and run it.
COMPILER defaults to clang. Single-file only, which is all lessons 01-08
need. Output goes to the *compilation* buffer so warnings become clickable
file:line links."
  (let ((src (buffer-file-name)))
    (unless src (user-error "Buffer is not visiting a file"))
    (save-buffer)
    (let ((out (file-name-sans-extension src)))
      (compile (format "%s %s -g -O0 -std=c17 -Wall -Wextra %s -o %s && %s"
                       (or compiler "clang")
                       (shell-quote-argument src)
                       extra-flags
                       (shell-quote-argument out)
                       (shell-quote-argument out))))))

(defun +my/c-compile-and-run ()
  "Compile and run the current C file with warnings on."
  (interactive)
  (+my/c--build-and-run ""))

(defun +my/c-compile-and-run-asan ()
  "Compile and run the current C file under Address/UB sanitizer.
Catches buffer overflows and use-after-free with file:line. Note that ASan's
leak detector does NOT work on macOS -- use `+my/c-run-leaks' for leaks."
  (interactive)
  (+my/c--build-and-run "-fsanitize=address,undefined"))

(defun +my/c-run-leaks ()
  "Compile the current C file and run it under macOS `leaks'.
This is the Valgrind replacement for leak detection on Apple silicon;
MallocStackLogging makes the report name the allocating function and line."
  (interactive)
  (let ((src (buffer-file-name)))
    (unless src (user-error "Buffer is not visiting a file"))
    (save-buffer)
    (let ((out (file-name-sans-extension src)))
      (compile (format "clang %s -g -O0 -std=c17 -Wall -Wextra -o %s && \
MallocStackLogging=1 leaks --atExit -- %s"
                       (shell-quote-argument src)
                       (shell-quote-argument out)
                       (shell-quote-argument out))))))

;; Keep the compilation buffer scrolled to the newest output.
(setq compilation-scroll-output t)

;; Localleader (SPC m) bindings. c-mode-map and c-ts-mode-map are different
;; keymaps from different features, so each gets its own `after!' -- one that
;; never loads simply never runs.
(after! cc-mode
  (map! :localleader
        :map c-mode-map
        "c" #'+my/c-compile-and-run
        "a" #'+my/c-compile-and-run-asan
        "l" #'+my/c-run-leaks))
(after! c-ts-mode
  (map! :localleader
        :map c-ts-mode-map
        "c" #'+my/c-compile-and-run
        "a" #'+my/c-compile-and-run-asan
        "l" #'+my/c-run-leaks))

;; --- Terminals -------------------------------------------------------------

;; Ghostel is the terminal *inside* Emacs -- same VT engine as the Ghostty app,
;; so lldb, ncurses, true color and shell integration all behave. Doom's :term
;; vterm module is disabled in favour of it; `+my/open-ghostty' below still
;; launches the real standalone Ghostty when a separate window is wanted.
(use-package! ghostel
  :defer t
  :init
  (setq
   ;; Keep the native module OUT of straight's build tree. Upstream warns that a
   ;; package rebuild will otherwise delete the .dylib while Emacs has it loaded;
   ;; doom-data-dir survives `doom sync' and `doom upgrade' (it is where the
   ;; tree-sitter grammars live too).
   ghostel-module-directory (expand-file-name "ghostel/" doom-data-dir)
   ;; If the module ever goes missing -- version bump, fresh machine -- fetch the
   ;; prebuilt binary instead of prompting.
   ghostel-module-auto-install 'download)
  ;; Terminal buffers should take keystrokes, not evil normal-state motions.
  (after! evil
    (evil-set-initial-state 'ghostel-mode 'insert))
  :config
  ;; Open as a bottom split instead of taking over the window. Matches both
  ;; "*ghostel*" and the per-title "*ghostel: TITLE*" buffers.
  (set-popup-rule! "^\\*ghostel" :size 0.35 :vslot -4 :select t :quit nil :ttl nil))

(map! :leader
      :desc "Terminal (ghostel)"      "o t" #'ghostel
      :desc "Terminal in project"     "o T" #'ghostel-project)

(defun +my/open-ghostty ()
  "Open a real Ghostty window at the current project root."
  (interactive)
  (let ((dir (expand-file-name (or (doom-project-root) default-directory))))
    (call-process "open" nil 0 nil "-na" "Ghostty"
                  "--args" (concat "--working-directory=" dir))
    (message "Ghostty -> %s" dir)))

(map! :leader
      :desc "Ghostty at project root" "o g" #'+my/open-ghostty)

;; --- Org-roam capture system ---

;; Capture templates (dumb inbox drops).
(after! org
  (setq org-capture-templates
        '(("t" "Todo → inbox" entry
           (file+headline "~/Dropbox/org/inbox.org" "Inbox")
           "* TODO %?\n  %U" :prepend t)
          ("n" "Note → inbox" entry
           (file+headline "~/Dropbox/org/inbox.org" "Notes")
           "* %?\n  %U" :prepend t)
          ("l" "Link/article → read later" entry
           (file+headline "~/Dropbox/org/inbox.org" "Read Later")
           "* TODO %?\n  %U\n  %x" :prepend t))))
;; %? = cursor, %U = inactive timestamp, %x = clipboard (paste a URL)

;; Roam ref template (for the optional browser clipper).
(after! org-roam
  (setq org-roam-capture-ref-templates
        '(("r" "ref" plain "%?"
           :target (file+head "web/${slug}.org"
                    "#+title: ${title}\n#+created: %U\n\n")
           :unnarrowed t))))

;; Keybinds.
(map! "C-c c" #'org-capture)                       ; capture menu
(map! "C-c t" (cmd! (org-capture nil "t")))        ; straight into a TODO

;; Global quick-capture frame (used by the Dock shortcut).
(after! org
  (defun my/org-capture-frame ()
    "Pop a small dedicated frame for a quick org capture."
    (interactive)
    (select-frame-set-input-focus
     (make-frame '((name . "org-capture") (width . 100) (height . 18))))
    (org-capture))

  (defun my/delete-capture-frame (&rest _)
    "Close the dedicated capture frame after finalize or abort."
    (when (equal "org-capture" (frame-parameter nil 'name))
      (delete-frame)))
  (advice-add 'org-capture-finalize :after #'my/delete-capture-frame))
