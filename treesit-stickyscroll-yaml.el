;;; treesit-stickyscroll-yaml.el --- Show context information around current point -*- lexical-binding: t; -*-

(require 'treesit-stickyscroll-common)

(defconst treesit-stickyscroll--yaml-node-types '("block_mapping_pair")
  "Node types that may be shown.")

(defconst treesit-stickyscroll--yaml-query
  (treesit-query-compile 'yaml '((block_mapping_pair key: (_) :anchor ":" (_) @context.end) @context))
  "Query patterns to capture desired nodes.")

(cl-defmethod treesit-stickyscroll-collect-contexts (&context (major-mode yaml-ts-mode))
  "Collect all of current node's parent nodes."
  (treesit-stickyscroll-collect-contexts-base treesit-stickyscroll--yaml-node-types treesit-stickyscroll--yaml-query))

(provide 'treesit-stickyscroll-yaml)
;;; treesit-stickyscroll-yaml.el ends here
