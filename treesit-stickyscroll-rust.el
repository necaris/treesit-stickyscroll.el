;;; treesit-stickyscroll-rust.el --- Show context information around current point -*- lexical-binding: t; -*-

(require 'treesit-stickyscroll-common)

(defconst treesit-stickyscroll--rust-node-types '("if_expression" "else_clause" "match_expression" "match_arm" "for_expression" "while_expression" "loop_expression" "closure_expression" "function_item" "impl_item" "trait_item" "struct_item" "enum_item" "mod_item")
  "Node types that may be shown.")

(defconst treesit-stickyscroll--rust-query
  (treesit-query-compile 'rust '(
                                 (if_expression consequence: (_) @context.end) @context
                                 (else_clause (block (_)) @context.end) @context
                                 (match_expression body: (_) @context.end) @context
                                 (match_arm pattern: (_) :anchor (_) @context.end) @context
                                 (for_expression body: (_) @context.end) @context
                                 (while_expression body: (_) @context.end) @context
                                 (loop_expression body: (_) @context.end) @context
                                 (closure_expression body: (_) @context.end) @context
                                 (function_item body: (_) @context.end) @context
                                 (impl_item body: (_) @context.end) @context
                                 (trait_item body: (_) @context.end) @context
                                 (struct_item body: (_) @context.end) @context
                                 (enum_item body: (_) @context.end) @context
                                 (mod_item body: (_) @context.end) @context))
  "Query patterns to capture desired nodes.")

(cl-defmethod treesit-stickyscroll-collect-contexts (&context (major-mode rust-ts-mode))
  "Collect all of current node's parent nodes."
  (treesit-stickyscroll-collect-contexts-base treesit-stickyscroll--rust-node-types treesit-stickyscroll--rust-query))

(provide 'treesit-stickyscroll-rust)
;;; treesit-stickyscroll-rust.el ends here
