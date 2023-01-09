Geometric Algebra in Raku
===========================

[![Build Status](https://travis-ci.org/grondilu/clifford.svg)](https://travis-ci.org/grondilu/clifford)
[![SparrowCI](https://ci.sparrowhub.io/project/gh-grondilu-clifford/badge)](https://ci.sparrowhub.io)

The `MultiVector` module in this repository is an attempt to implement basic
[Geometric Algebra](http://en.wikipedia.org/wiki/Geometric_Algebra) in Raku.

With this module you can create vectors of arbitrary, albeit countable
dimension.  You can then add and substract them, as well as multiplying them by
real scalars as you would do with any vectors, but you can also multiply and
divide them as made possible by the geometric algebra.

The module exports three array constants `@e`, `@i` and `@o`
which serve as normed bases for three orthogonal spaces respectively
Euclidean, anti-Euclidean and null.

In addition to the usual overloading of arithmetic operators, the module also
defines the infix operators `∧` and `·` (vim digraphs "AN" and ".M") as the
outer and scalar products.  The scalar product is defined only on vectors (i.e.
multivectors of grade one).

Synopsis
--------

```raku
use MultiVector;

say @e[0];         # e₀
say @e[1]*@e[0];   # -e₀∧e₁
say 1 + @e[4];     # 1+e₄
say @i[3]∧@e[2];   # -e₂∧i₃
say @o[2]∧@i[2];   # -i₂∧o₂

say @e[1]²;      # 1
say @i[1]²;      # -1
say @o[1]²;      # 0
```

External links
--------------

* [Geometric Algebra for Computer science](http://www.geometricalgebra.net) : a
  website and a book that helped for this project ;
* [Versor](https://github.com/wolftype/versor), a C++ implementation of the
  above reference.
* [Eric Lengyel's page on Geometric Algebra](https://projectivegeometricalgebra.org/),
  with links to his wikis on the subject.  Dr Eric Lengyel is the person who
  first suggested the use of the symbol `⟑`.
* [Bivector.net](https://bivector.net/), some kind of a GA community hub.
