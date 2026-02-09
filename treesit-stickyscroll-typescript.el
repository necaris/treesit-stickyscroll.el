;;; treesit-stickyscroll-typescript.el --- Show context information around current point -*- lexical-binding: t; -*-

(require 'treesit-stickyscroll-common)

(defconst treesit-stickyscroll--typescript-node-types '("if_statement" "else_clause" "for_statement" "for_in_statement" "while_statement" "class_declaration" "class" "function" "arrow_function" "function_declaration" "generator_function_declaration" "method_definition" "switch_statement" "switch_case" "switch_default" "pair" "variable_declarator" "internal_module" "enum_declaration" "enum_assignment")
  "Node types that may be shown.")

(defconst treesit-stickyscroll--typescript-query
  (treesit-query-compile 'typescript '(
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
                                       (pair value: (_) @context.end) @context
                                       (enum_declaration body: (_) @context.end) @context
                                       (enum_assignment name: (_) :anchor "=" @context.end) @context
                                       (internal_module body: (_) @context.end) @context))
  "Query patterns to capture desired nodes.")

(cl-defmethod treesit-stickyscroll-collect-contexts (&context (major-mode typescript-ts-mode))
  "Collect all of current node's parent nodes."
  (treesit-stickyscroll-collect-contexts-base treesit-stickyscroll--typescript-node-types treesit-stickyscroll--typescript-query))

(provide 'treesit-stickyscroll-typescript)
;;; treesit-stickyscroll-typescript.el ends here
