;;; treesit-stickyscroll-go.el --- Show context information around current point -*- lexical-binding: t; -*-

(require 'treesit-stickyscroll-common)

(defconst treesit-stickyscroll--go-node-types '("function_declaration" "func_literal" "method_declaration" "if_statement" "for_statement" "communication_case" "expression_switch_statement" "expression_case" "type_switch_statement" "type_case" "default_case")
  "Node types that may be shown.")

(defconst treesit-stickyscroll--go-query
  (treesit-query-compile 'go '(
                               (function_declaration body: (_) @context.end) @context
                               (func_literal body: (_) @context.end) @context
                               (method_declaration body: (_) @context.end) @context
                               (if_statement consequence: (_) @context.end) @context
                               (for_statement body: (_) @context.end) @context
                               (expression_switch_statement value: (_) :anchor (_) @context.end) @context
                               (expression_case value: (_) :anchor) @context
                               (expression_case value: (_) :anchor (_) @context.end) @context
                               (type_switch_statement value: (_) :anchor (_) @context.end) @context
                               (type_case type: (_) :anchor) @context
                               (type_case type: (_) :anchor (_) @context.end) @context
                               (default_case :anchor (_) @context.end) @context
                               (communication_case communication: (_) @context.end) @context))
  "Query patterns to capture desired nodes.")

(cl-defmethod treesit-stickyscroll-collect-contexts (&context (major-mode go-ts-mode))
  "Collect all of current node's parent nodes."
  (treesit-stickyscroll-collect-contexts-base treesit-stickyscroll--go-node-types treesit-stickyscroll--go-query))

(provide 'treesit-stickyscroll-go)
;;; treesit-stickyscroll-go.el ends here
