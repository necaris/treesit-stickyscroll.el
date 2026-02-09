;;; treesit-stickyscroll-java.el --- Show context information around current point -*- lexical-binding: t; -*-

(require 'treesit-stickyscroll-common)

(defconst treesit-stickyscroll--java-node-types '("if_statement" "for_statement" "enhanced_for_statement" "while_statement" "class_declaration" "method_declaration" "switch_expression" "switch_block_statement_group" "try_statement" "catch_clause" "interface_declaration" "enum_declaration")
  "Node types that may be shown.")

(defconst treesit-stickyscroll--java-query
  (treesit-query-compile 'java '(
                                 (if_statement consequence: (_) @context.end) @context
                                 (for_statement body: (_) @context.end) @context
                                 (while_statement body: (_) @context.end) @context
                                 (enhanced_for_statement body: (_) @context.end) @context
                                 (method_declaration body: (_) @context.end) @context
                                 (class_declaration body: (_) @context.end) @context
                                 (switch_expression body: (_) @context.end) @context
                                 (try_statement body: (_) @context.end) @context
                                 (catch_clause body: (_) @context.end) @context
                                 (interface_declaration body: (_) @context.end) @context
                                 (enum_declaration body: (_) @context.end) @context))
  "Query patterns to capture desired nodes.")

(cl-defmethod treesit-stickyscroll-collect-contexts (&context (major-mode java-ts-mode))
  "Collect all of current node's parent nodes."
  (treesit-stickyscroll-collect-contexts-base treesit-stickyscroll--java-node-types treesit-stickyscroll--java-query))

(provide 'treesit-stickyscroll-java)
;;; treesit-stickyscroll-java.el ends here
