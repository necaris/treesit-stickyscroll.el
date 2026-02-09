;;; treesit-stickyscroll-javascript.el --- Show context information around current point -*- lexical-binding: t; -*-

(require 'treesit-stickyscroll-common)

(defconst treesit-stickyscroll--javascript-node-types '("if_statement" "else_clause" "for_statement" "for_in_statement" "while_statement" "class_declaration" "class" "function" "arrow_function" "function_declaration" "generator_function_declaration" "method_definition" "switch_statement" "switch_case" "switch_default" "pair" "variable_declarator")
  "Node types that may be shown.")

(defconst treesit-stickyscroll--javascript-query
  (treesit-query-compile 'javascript '(
                                       (if_statement consequence: (_) @context.end) @context
                                       (else_clause :anchor (_) @context.end) @context
                                       (for_statement body: (_) @context.end) @context
                                       (for_in_statement body: (_) @context.end) @context
                                       (while_statement body: (_) @context.end) @context
                                       (class_declaration body: (_) @context.end) @context
                                       (class body: (_) @context.end) @context
                                       (function body: (_) @context.end) @context
                                       (arrow_function body: (_) @context.end) @context
                                       (function_declaration body: (_) @context.end) @context
                                       (generator_function_declaration body: (_) @context.end) @context
                                       (method_definition body: (_) @context.end) @context
                                       (switch_statement body: (_) @context.end) @context
                                       (switch_case body: (_) @context.end) @context
                                       (switch_default body: (_) @context.end) @context
                                       (variable_declarator name: (_) :anchor (_):? @context.end) @context
                                       (pair value: (_) @context.end) @context))
  "Query patterns to capture desired nodes.")

(cl-defmethod treesit-stickyscroll-collect-contexts (&context (major-mode js-ts-mode))
  "Collect all of current node's parent nodes."
  (treesit-stickyscroll-collect-contexts-base treesit-stickyscroll--javascript-node-types treesit-stickyscroll--javascript-query))

(provide 'treesit-stickyscroll-javascript)
;;; treesit-stickyscroll-javascript.el ends here
