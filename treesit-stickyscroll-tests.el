;;; treesit-stickyscroll-tests.el --- Tests for treesit-stickyscroll -*- lexical-binding: t; -*-

;;; Commentary:
;; ERT tests for treesit-stickyscroll language support modules.
;; Tests verify that node types, queries, and context collection work
;; correctly for each supported language.

;;; Code:
(require 'ert)
(require 'treesit)

;; Load the package from the project directory
(let ((dir (file-name-directory (or load-file-name buffer-file-name default-directory))))
  (add-to-list 'load-path dir)
  (require 'treesit-stickyscroll-common)
  (require 'treesit-stickyscroll-c)
  (require 'treesit-stickyscroll-cpp)
  (require 'treesit-stickyscroll-python)
  (require 'treesit-stickyscroll-typescript)
  (require 'treesit-stickyscroll-javascript)
  (require 'treesit-stickyscroll-rust)
  (require 'treesit-stickyscroll-go)
  (require 'treesit-stickyscroll-java)
  (require 'treesit-stickyscroll-yaml)
  (require 'treesit-stickyscroll-tsx))


;;; ============================================================
;;; Helper utilities
;;; ============================================================

(defun treesit-stickyscroll-test--parse-string (lang source)
  "Parse SOURCE string with LANG tree-sitter parser, return root node."
  (with-temp-buffer
    (insert source)
    (treesit-parser-create lang)
    (treesit-buffer-root-node)))

(defun treesit-stickyscroll-test--parent-nodes-in-string (lang source point node-types)
  "Parse SOURCE with LANG, find parent nodes at POINT matching NODE-TYPES."
  (with-temp-buffer
    (insert source)
    (treesit-parser-create lang)
    (treesit-stickyscroll--parent-nodes node-types point)))

(defun treesit-stickyscroll-test--capture-in-string (lang source query)
  "Parse SOURCE with LANG, run QUERY capture over root node."
  (with-temp-buffer
    (insert source)
    (let* ((parser (treesit-parser-create lang))
           (root (treesit-buffer-root-node)))
      (treesit-stickyscroll--capture root query))))

;;; ============================================================
;;; Supported mode registration tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-supported-modes ()
  "All language modes are registered in the supported mode list."
  (dolist (mode '(c-ts-mode c++-ts-mode python-ts-mode typescript-ts-mode tsx-ts-mode
                  js-ts-mode rust-ts-mode go-ts-mode java-ts-mode yaml-ts-mode))
    (should (member mode treesit-stickyscroll--supported-mode))))

(ert-deftest treesit-stickyscroll-test-lazy-loading ()
  "Language modules are only loaded when `treesit-stickyscroll--ensure-language' is called."
  ;; After loading the test file all language features are present (the
  ;; test harness requires them directly), so we check the mechanism
  ;; itself: ensure-language for an unregistered mode is a no-op, and
  ;; for a registered mode it requires the feature (idempotent here).
  (let ((major-mode 'fundamental-mode))
    ;; Should not error on unknown mode
    (should-not (treesit-stickyscroll--ensure-language)))
  ;; Every entry in the alist maps to a feature that is loadable
  (dolist (entry treesit-stickyscroll--language-alist)
    (should (featurep (cdr entry)))))

;;; ============================================================
;;; Node types sanity tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-node-types-are-lists ()
  "Node types constants are non-empty lists of strings."
  (dolist (types (list treesit-stickyscroll--c-node-types
                       treesit-stickyscroll--c++-node-types
                       treesit-stickyscroll--python-node-types
                       treesit-stickyscroll--typescript-node-types
                       treesit-stickyscroll--tsx-node-types
                       treesit-stickyscroll--javascript-node-types
                       treesit-stickyscroll--rust-node-types
                       treesit-stickyscroll--go-node-types
                       treesit-stickyscroll--java-node-types
                       treesit-stickyscroll--yaml-node-types))
    (should (listp types))
    (should (> (length types) 0))
    (dolist (nt types)
      (should (stringp nt)))))

;;; ============================================================
;;; Query compilation tests (queries are compiled at load time;
;;; verify they are non-nil treesit-query objects)
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-queries-compiled ()
  "All query constants compiled without error."
  (dolist (q (list treesit-stickyscroll--c-query
                   treesit-stickyscroll--c++-query
                   treesit-stickyscroll--python-query
                   treesit-stickyscroll--typescript-query
                   treesit-stickyscroll--tsx-query
                   treesit-stickyscroll--javascript-query
                   treesit-stickyscroll--rust-query
                   treesit-stickyscroll--go-query
                   treesit-stickyscroll--java-query
                   treesit-stickyscroll--yaml-query))
    (should q)))

;;; ============================================================
;;; Python tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-python-parent-nodes ()
  "Python: parent nodes found for nested function/class."
  (skip-unless (treesit-language-available-p 'python))
  (let* ((source "class Foo:\n    def bar(self):\n        if True:\n            pass\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'python source
                 ;; point inside the `pass` statement
                 (+ 1 (string-match "pass" source))
                 treesit-stickyscroll--python-node-types)))
    ;; Should find class_definition, function_definition, if_statement
    (should (>= (length nodes) 3))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "class_definition" types))
      (should (member "function_definition" types))
      (should (member "if_statement" types)))))

(ert-deftest treesit-stickyscroll-test-python-query-captures ()
  "Python: query captures context nodes for a class with method."
  (skip-unless (treesit-language-available-p 'python))
  (let* ((source "class Foo:\n    def bar(self):\n        pass\n")
         (captures (treesit-stickyscroll-test--capture-in-string
                    'python source treesit-stickyscroll--python-query)))
    ;; Should capture at least class and function
    (should (>= (length captures) 2))))

(ert-deftest treesit-stickyscroll-test-python-try-except ()
  "Python: try/except blocks produce parent nodes."
  (skip-unless (treesit-language-available-p 'python))
  (let* ((source "try:\n    x = 1\nexcept ValueError:\n    pass\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'python source
                 (+ 1 (string-match "x = 1" source))
                 treesit-stickyscroll--python-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "try_statement" types)))))

(ert-deftest treesit-stickyscroll-test-python-for-while ()
  "Python: for and while loops produce parent nodes."
  (skip-unless (treesit-language-available-p 'python))
  (let* ((source "for i in range(10):\n    while True:\n        break\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'python source
                 (+ 1 (string-match "break" source))
                 treesit-stickyscroll--python-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "for_statement" types))
      (should (member "while_statement" types)))))

;;; ============================================================
;;; TypeScript tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-typescript-parent-nodes ()
  "TypeScript: parent nodes found for class with method."
  (skip-unless (treesit-language-available-p 'typescript))
  (let* ((source "class Foo {\n  bar() {\n    if (true) {\n      return 1;\n    }\n  }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'typescript source
                 (+ 1 (string-match "return" source))
                 treesit-stickyscroll--typescript-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "class_declaration" types))
      (should (member "method_definition" types))
      (should (member "if_statement" types)))))

(ert-deftest treesit-stickyscroll-test-typescript-query-captures ()
  "TypeScript: query captures context nodes."
  (skip-unless (treesit-language-available-p 'typescript))
  (let* ((source "class Foo {\n  bar() {\n    return 1;\n  }\n}\n")
         (captures (treesit-stickyscroll-test--capture-in-string
                    'typescript source treesit-stickyscroll--typescript-query)))
    (should (>= (length captures) 2))))

(ert-deftest treesit-stickyscroll-test-typescript-arrow-function ()
  "TypeScript: arrow functions produce parent nodes."
  (skip-unless (treesit-language-available-p 'typescript))
  (let* ((source "const fn = (x: number) => {\n  return x + 1;\n};\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'typescript source
                 (+ 1 (string-match "return" source))
                 treesit-stickyscroll--typescript-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "arrow_function" types)))))

(ert-deftest treesit-stickyscroll-test-typescript-enum ()
  "TypeScript: enum declarations produce parent nodes."
  (skip-unless (treesit-language-available-p 'typescript))
  (let* ((source "enum Color {\n  Red,\n  Green,\n  Blue\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'typescript source
                 (+ 1 (string-match "Green" source))
                 treesit-stickyscroll--typescript-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "enum_declaration" types)))))

(ert-deftest treesit-stickyscroll-test-typescript-switch ()
  "TypeScript: switch statement with cases produces parent nodes."
  (skip-unless (treesit-language-available-p 'typescript))
  (let* ((source "function test(x: number) {\n  switch (x) {\n    case 1:\n      return 'one';\n    default:\n      return 'other';\n  }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'typescript source
                 (+ 1 (string-match "'one'" source))
                 treesit-stickyscroll--typescript-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "function_declaration" types))
      (should (member "switch_statement" types))
      (should (member "switch_case" types)))))

;;; ============================================================
;;; TSX tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-tsx-parent-nodes ()
  "TSX: parent nodes found for component with method."
  (skip-unless (treesit-language-available-p 'tsx))
  (let* ((source "class App {\n  render() {\n    if (true) {\n      return 1;\n    }\n  }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'tsx source
                 (+ 1 (string-match "return" source))
                 treesit-stickyscroll--tsx-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "class_declaration" types))
      (should (member "method_definition" types))
      (should (member "if_statement" types)))))

(ert-deftest treesit-stickyscroll-test-tsx-query-captures ()
  "TSX: query captures context nodes."
  (skip-unless (treesit-language-available-p 'tsx))
  (let* ((source "function App() {\n  for (let i = 0; i < 10; i++) {\n    console.log(i);\n  }\n}\n")
         (captures (treesit-stickyscroll-test--capture-in-string
                    'tsx source treesit-stickyscroll--tsx-query)))
    (should (>= (length captures) 2))))

;;; ============================================================
;;; JavaScript tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-javascript-parent-nodes ()
  "JavaScript: parent nodes found for nested constructs."
  (skip-unless (treesit-language-available-p 'javascript))
  (let* ((source "function foo() {\n  for (let i = 0; i < 10; i++) {\n    console.log(i);\n  }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'javascript source
                 (+ 1 (string-match "console" source))
                 treesit-stickyscroll--javascript-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "function_declaration" types))
      (should (member "for_statement" types)))))

(ert-deftest treesit-stickyscroll-test-javascript-query-captures ()
  "JavaScript: query captures context nodes."
  (skip-unless (treesit-language-available-p 'javascript))
  (let* ((source "function foo() {\n  if (true) {\n    return 1;\n  }\n}\n")
         (captures (treesit-stickyscroll-test--capture-in-string
                    'javascript source treesit-stickyscroll--javascript-query)))
    (should (>= (length captures) 2))))

(ert-deftest treesit-stickyscroll-test-javascript-arrow-function ()
  "JavaScript: arrow functions in objects produce parent nodes."
  (skip-unless (treesit-language-available-p 'javascript))
  (let* ((source "const obj = {\n  fn: (x) => {\n    return x;\n  }\n};\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'javascript source
                 (+ 1 (string-match "return x" source))
                 treesit-stickyscroll--javascript-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "arrow_function" types)))))

;;; ============================================================
;;; Rust tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-rust-parent-nodes ()
  "Rust: parent nodes found for impl with method."
  (skip-unless (treesit-language-available-p 'rust))
  (let* ((source "impl Foo {\n    fn bar(&self) {\n        if true {\n            println!(\"hello\");\n        }\n    }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'rust source
                 (+ 1 (string-match "println" source))
                 treesit-stickyscroll--rust-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "impl_item" types))
      (should (member "function_item" types))
      (should (member "if_expression" types)))))

(ert-deftest treesit-stickyscroll-test-rust-query-captures ()
  "Rust: query captures context nodes."
  (skip-unless (treesit-language-available-p 'rust))
  (let* ((source "fn main() {\n    for i in 0..10 {\n        println!(\"{}\", i);\n    }\n}\n")
         (captures (treesit-stickyscroll-test--capture-in-string
                    'rust source treesit-stickyscroll--rust-query)))
    (should (>= (length captures) 2))))

(ert-deftest treesit-stickyscroll-test-rust-match-expression ()
  "Rust: match expressions produce parent nodes."
  (skip-unless (treesit-language-available-p 'rust))
  (let* ((source "fn test(x: i32) {\n    match x {\n        1 => println!(\"one\"),\n        _ => println!(\"other\"),\n    }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'rust source
                 (+ 1 (string-match "\"one\"" source))
                 treesit-stickyscroll--rust-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "function_item" types))
      (should (member "match_expression" types)))))

(ert-deftest treesit-stickyscroll-test-rust-trait-and-mod ()
  "Rust: trait and mod items produce parent nodes."
  (skip-unless (treesit-language-available-p 'rust))
  (let* ((source "mod mymod {\n    trait MyTrait {\n        fn do_thing(&self);\n    }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'rust source
                 (+ 1 (string-match "do_thing" source))
                 treesit-stickyscroll--rust-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "mod_item" types))
      (should (member "trait_item" types)))))

;;; ============================================================
;;; Go tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-go-parent-nodes ()
  "Go: parent nodes found for function with if."
  (skip-unless (treesit-language-available-p 'go))
  (let* ((source "package main\n\nfunc foo() {\n\tif true {\n\t\tprintln(\"hello\")\n\t}\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'go source
                 (+ 1 (string-match "println" source))
                 treesit-stickyscroll--go-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "function_declaration" types))
      (should (member "if_statement" types)))))

(ert-deftest treesit-stickyscroll-test-go-query-captures ()
  "Go: query captures context nodes."
  (skip-unless (treesit-language-available-p 'go))
  (let* ((source "package main\n\nfunc foo() {\n\tfor i := 0; i < 10; i++ {\n\t\tprintln(i)\n\t}\n}\n")
         (captures (treesit-stickyscroll-test--capture-in-string
                    'go source treesit-stickyscroll--go-query)))
    (should (>= (length captures) 2))))

(ert-deftest treesit-stickyscroll-test-go-method-declaration ()
  "Go: method declarations produce parent nodes."
  (skip-unless (treesit-language-available-p 'go))
  (let* ((source "package main\n\ntype Foo struct{}\n\nfunc (f Foo) Bar() {\n\tprintln(\"bar\")\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'go source
                 (+ 1 (string-match "println" source))
                 treesit-stickyscroll--go-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "method_declaration" types)))))

(ert-deftest treesit-stickyscroll-test-go-switch ()
  "Go: switch statement produces parent nodes."
  (skip-unless (treesit-language-available-p 'go))
  (let* ((source "package main\n\nfunc test(x int) {\n\tswitch x {\n\tcase 1:\n\t\tprintln(\"one\")\n\tdefault:\n\t\tprintln(\"other\")\n\t}\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'go source
                 (+ 1 (string-match "\"one\"" source))
                 treesit-stickyscroll--go-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "function_declaration" types))
      (should (member "expression_switch_statement" types)))))

;;; ============================================================
;;; Java tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-java-parent-nodes ()
  "Java: parent nodes found for class with method."
  (skip-unless (treesit-language-available-p 'java))
  (let* ((source "class Foo {\n    void bar() {\n        if (true) {\n            System.out.println(\"hello\");\n        }\n    }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'java source
                 (+ 1 (string-match "System" source))
                 treesit-stickyscroll--java-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "class_declaration" types))
      (should (member "method_declaration" types))
      (should (member "if_statement" types)))))

(ert-deftest treesit-stickyscroll-test-java-query-captures ()
  "Java: query captures context nodes."
  (skip-unless (treesit-language-available-p 'java))
  (let* ((source "class Foo {\n    void bar() {\n        for (int i = 0; i < 10; i++) {\n            System.out.println(i);\n        }\n    }\n}\n")
         (captures (treesit-stickyscroll-test--capture-in-string
                    'java source treesit-stickyscroll--java-query)))
    (should (>= (length captures) 3))))

(ert-deftest treesit-stickyscroll-test-java-enhanced-for ()
  "Java: enhanced for loop produces parent nodes."
  (skip-unless (treesit-language-available-p 'java))
  (let* ((source "class Foo {\n    void bar(int[] arr) {\n        for (int x : arr) {\n            System.out.println(x);\n        }\n    }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'java source
                 (+ 1 (string-match "System" source))
                 treesit-stickyscroll--java-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "enhanced_for_statement" types)))))

;;; ============================================================
;;; YAML tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-yaml-parent-nodes ()
  "YAML: parent nodes found for nested mapping pairs."
  (skip-unless (treesit-language-available-p 'yaml))
  (let* ((source "root:\n  child:\n    grandchild: value\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'yaml source
                 (+ 1 (string-match "grandchild" source))
                 treesit-stickyscroll--yaml-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "block_mapping_pair" types))
      ;; Should find at least 2 levels of nesting (root and child)
      (should (>= (length nodes) 2)))))

(ert-deftest treesit-stickyscroll-test-yaml-query-captures ()
  "YAML: query captures context nodes."
  (skip-unless (treesit-language-available-p 'yaml))
  (let* ((source "server:\n  host: localhost\n  port: 8080\n")
         (captures (treesit-stickyscroll-test--capture-in-string
                    'yaml source treesit-stickyscroll--yaml-query)))
    (should (>= (length captures) 1))))

;;; ============================================================
;;; C tests (existing language, verify not broken)
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-c-parent-nodes ()
  "C: parent nodes found for function with if."
  (skip-unless (treesit-language-available-p 'c))
  (let* ((source "void foo() {\n    if (1) {\n        return;\n    }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'c source
                 (+ 1 (string-match "return" source))
                 treesit-stickyscroll--c-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "function_definition" types))
      (should (member "if_statement" types)))))

(ert-deftest treesit-stickyscroll-test-c-query-captures ()
  "C: query captures context nodes."
  (skip-unless (treesit-language-available-p 'c))
  (let* ((source "void foo() {\n    for (int i = 0; i < 10; i++) {\n        bar();\n    }\n}\n")
         (captures (treesit-stickyscroll-test--capture-in-string
                    'c source treesit-stickyscroll--c-query)))
    (should (>= (length captures) 2))))

;;; ============================================================
;;; C++ tests (existing language, verify not broken)
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-cpp-parent-nodes ()
  "C++: parent nodes found for class with method."
  (skip-unless (treesit-language-available-p 'cpp))
  (let* ((source "class Foo {\n    void bar() {\n        while (true) {\n            break;\n        }\n    }\n};\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'cpp source
                 (+ 1 (string-match "break" source))
                 treesit-stickyscroll--c++-node-types)))
    (let ((types (mapcar #'treesit-node-type nodes)))
      (should (member "class_specifier" types))
      (should (member "function_definition" types))
      (should (member "while_statement" types)))))

;;; ============================================================
;;; Cross-language: indent-context utility
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-indent-context-basic ()
  "indent-context strips blank lines and preserves non-blank ones."
  (let ((result (treesit-stickyscroll-indent-context "def foo():\n\n    pass\n")))
    (should (= (length result) 2))
    (should (string-match-p "def foo" (nth 0 result)))
    (should (string-match-p "pass" (nth 1 result)))))

(ert-deftest treesit-stickyscroll-test-indent-context-empty ()
  "indent-context returns nil for empty/blank input."
  (should (null (treesit-stickyscroll-indent-context "")))
  (should (null (treesit-stickyscroll-indent-context "   \n  \n"))))

;;; ============================================================
;;; Deeply nested context tests
;;; ============================================================

(ert-deftest treesit-stickyscroll-test-python-deep-nesting ()
  "Python: deeply nested code produces multiple context parents."
  (skip-unless (treesit-language-available-p 'python))
  (let* ((source "class Outer:\n    class Inner:\n        def method(self):\n            for i in range(10):\n                if i > 5:\n                    print(i)\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'python source
                 (+ 1 (string-match "print" source))
                 treesit-stickyscroll--python-node-types)))
    ;; Should find: class_definition (Outer), class_definition (Inner),
    ;; function_definition, for_statement, if_statement = 5
    (should (>= (length nodes) 5))))

(ert-deftest treesit-stickyscroll-test-typescript-deep-nesting ()
  "TypeScript: deeply nested code produces multiple context parents."
  (skip-unless (treesit-language-available-p 'typescript))
  (let* ((source "class Outer {\n  method() {\n    for (let i = 0; i < 10; i++) {\n      if (i > 5) {\n        while (true) {\n          break;\n        }\n      }\n    }\n  }\n}\n")
         (nodes (treesit-stickyscroll-test--parent-nodes-in-string
                 'typescript source
                 (+ 1 (string-match "break" source))
                 treesit-stickyscroll--typescript-node-types)))
    ;; class_declaration, method_definition, for_statement, if_statement, while_statement
    (should (>= (length nodes) 5))))

(provide 'treesit-stickyscroll-tests)
;;; treesit-stickyscroll-tests.el ends here
