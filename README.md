Geometric Algebra in Perl 6
===========================

[![Build Status](https://travis-ci.org/grondilu/clifford.svg)](https://travis-ci.org/grondilu/clifford)

This module is an attempt to implement basic [Geometric
Algebra](http://en.wikipedia.org/wiki/Geometric_Algebra) in Perl 6.

With this module you can create euclidean and anti-euclidean vectors of
arbitrary size.  You can then add and substract them, as well as multiplying
them by real scalars as you would do with any vectors, but you can also
multiply and divide as made possible by the geometric algebra.

Euclidean space
---------------

The module exports an array constant `@e` which serves as an orthonormal basis
for an Euclidean space of infinite, countable dimension.

    use Clifford;

    say @e[0]**2;         # +1
    say @e[0] + 2*@e[1];  # e0+2*e1
    say @e[0]*@e[1];      # e0∧e1

Anti-Euclidean space
--------------------

The module also exports an array constant `@ē` which serves as an orthonormal
basis for an anti-Euclidean space of infinite, countable dimension.  This
space is orthogonal to the Euclidean space.

    use Clifford;

    say @ē[0]**2;        # -1
    say @e[0] + @ē[0];   # e0 + ē0
    say @e[0]*@ē[0];     # e0∧ē0

The `ē` character is the voyel `e` with a [macron](https://en.wikipedia.org/wiki/Macron).
It is available as a default digraph on [Vim](http://www.vim.org) as `e-`.

Minkowski plane
---------------

The module exports two constants `no` and `ni` which form a null basis of a
[Minkowski plane](https://en.wikipedia.org/wiki/Minkowski_plane).  This plane
is orthogonal to both the Euclidean space and the anti-Euclidean space.

    use Clifford;
    say no;                 # 𝑜
    say ni;                 # ∞
    say no**2;              # 0
    say ni**2;              # 0
    say no*@e[0];           # 𝑜∧e0
    say ni*@ē[0];           # ∞∧ē0
    say no*ni;              # -1+𝑜∧∞
    say (no*ni + ni*no)/2   # -1

Grade projection
----------------

The `AT-POS` method returns the grade projection:

    say (no + @e[1] + @e[0]*@e[1])[1];   # 𝑜+e1

Operations
----------

There are many multiplicative operators derived from the geometric product, but
as of today the module only defines the outer product:

    say (@e[0] + @e[1] + @e[0]∧@e[2])∧@e[1];   # e0∧e1 - e0∧e1∧e2

It is tighter than `&[*]`.

The symbol `∧` is the wedge symbol usually used for logical AND.
It can be displayed in *Vim* with the digraph `AN`.

The module also implements the three involutions:

    given 1 + @e[0] + @e[0]∧@e[1] + @e[0]∧@e[1]∧@e[2] {
	say .reversion;    # 1+e0-e0∧e1-e0∧e1∧e2
	say .involution;   # 1-e0+e0∧e1-e0∧e1∧e2
	say .conjugation;  # 1-e0-e0∧e1+e0∧e1∧e2
    }

External links
--------

* [Geometric Algebra for Computer science](http://www.geometricalgebra.net) : a
  website and a book that helped for this project ;
* [Versor](https://github.com/wolftype/versor), a C++ implementation of the
  above reference.  This uses advanced optimizations with precompilation and
stuff.  Ideally it should be possible to copy ideas from this, but it will need
work.
