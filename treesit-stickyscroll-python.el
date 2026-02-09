;;; treesit-stickyscroll-python.el --- Show context information around current point -*- lexical-binding: t; -*-

(require 'treesit-stickyscroll-common)

(defconst treesit-stickyscroll--python-node-types '("class_definition" "function_definition" "try_statement" "with_statement" "if_statement" "elif_clause" "else_clause" "case_clause" "while_statement" "except_clause" "match_statement" "for_statement")
  "Node types that may be shown.")

(defconst treesit-stickyscroll--python-query
  (treesit-query-compile 'python '(
                                   (class_definition body: (_) @context.end) @context
                                   (function_definition parameters: (_) :anchor ":" @context.end) @context
                                   (try_statement body: (_) @context.end) @context
                                   (with_statement :anchor body: (_) @context.end) @context
                                   (for_statement right: (_) :anchor ":" @context.end) @context
                                   (if_statement condition: (_) :anchor ":" @context.end) @context
                                   (elif_clause condition: (_) :anchor ":" @context.end) @context
                                   (else_clause :anchor ":" @context.end) @context
                                   (case_clause consequence: (_) @context.end) @context
                                   (while_statement body: (_) @context.end) @context
                                   (except_clause (block) @context.end) @context
                                   (match_statement body: (_) @context.end) @context))
  "Query patterns to capture desired nodes.")

(cl-defmethod treesit-stickyscroll-collect-contexts (&context (major-mode python-ts-mode))
  "Collect all of current node's parent nodes."
  (treesit-stickyscroll-collect-contexts-base treesit-stickyscroll--python-node-types treesit-stickyscroll--python-query))

(provide 'treesit-stickyscroll-python)
;;; treesit-stickyscroll-python.el ends here
