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

Optimization
------------

This module attempts to optimize computations by generating code during
runtime, as inspired by Pablo Colapinto's work (see next section).

Consider for instance the geometric product of two vectors `X = x1*e1 + x2*e2 +
x3*e3` and `Y = y1*e1 + y2*e2 + y3*e3`:

    X*Y = (x1*y1+x2*y2+x3*y3) +
          (x1*y2-x2*y1)*e1∧e2 +
          (x2*y3-x3*y2)*e2∧e3 +
          (x3*y1-x1*y3)*e3∧e1
     
This multivector is a linear combination of the unit scalar and the basis
bivectors `e1∧e2`, `e2∧e3` and `e3∧e1`.  It would have been possible to know
that beforehand by taking all possible products from `e1`, `e2` and `e3` and
classify them, keeping track of the sign changes.

Assuming an array of coefficients can be associated with a list of basis unit multivectors in order
to form a generic multivector, the coefficients of a product of two vectors could have been
calculated by a function such as:

    sub (@x, @y) {
        @x[0]*@y[0]+@x[1]*@y[1]+@x[2]*@y[2],
	@x[0]*@y[1]-@x[1]*@y[0],
	@x[1]*@y[2]-@x[2]*@y[1],
	@x[2]*@y[0]-@x[0]*@y[2]
    }

This would be very efficient but we would have to use a different function for
all possible kinds of products, and there are infinitely many of them.  Since
it's not possible to precompute an infinity of things, the module starts from
nothing and generates a product at runtime, every time it encounters a product
type it has never seen before.

To generate a function we simply generate the literal string that defines it in
Perl 6 and we `EVAL` it.

External links
--------

* [Geometric Algebra for Computer science](http://www.geometricalgebra.net) : a
  website and a book that helped for this project ;
* [Versor](https://github.com/wolftype/versor), a C++ implementation of the
  above reference.  This uses advanced optimizations with precompilation and
stuff.  Some of the ideas used there have been used here.
