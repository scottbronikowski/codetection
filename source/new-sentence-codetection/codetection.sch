(DEFINE-EXTERNAL (PREGEXP S) PREGEXP)
(DEFINE-EXTERNAL (MATLAB . STRINGS) TOOLLIB-MATLAB)
(DEFINE-EXTERNAL (START-MATLAB!) TOOLLIB-MATLAB)
(DEFINE-EXTERNAL (MATLAB-GET-VARIABLE NAME) TOOLLIB-MATLAB)
(DEFINE-EXTERNAL MALLOC TOOLLIB-C-BINDINGS)
(DEFINE-EXTERNAL FREE TOOLLIB-C-BINDINGS)
(DEFINE-EXTERNAL (LIST->C-EXACT-ARRAY ARRAY L ELEMENT-SIZE SIGNED?) TOOLLIB-C-BINDINGS)
(DEFINE-EXTERNAL (C-EXACT-ARRAY->LIST ARRAY ELEMENT-SIZE NR-ELEMENTS SIGNED?) TOOLLIB-C-BINDINGS)
(DEFINE-EXTERNAL (EASY-FFI:FREE N X V) EASY-FFI)
(DEFINE-EXTERNAL EASY-FFI:DOUBLE-TO-C EASY-FFI)