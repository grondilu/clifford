Geometric Algebra in Raku
===========================

[![Build Status](https://travis-ci.org/grondilu/clifford.svg)](https://travis-ci.org/grondilu/clifford)

This module is an attempt to implement basic [Geometric
Algebra](http://en.wikipedia.org/wiki/Geometric_Algebra) in Raku.

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

Operations
----------

### Grade projection

The `AT-POS` method returns the grade projection:

    say (no + @e[1] + @e[0]*@e[1])[1];   # 𝑜+e1

### Derived products

There are several multiplicative operators derived from the geometric product.
They are extensively discussed by Leo Dorst in his 2002 paper
*the inner products of Geometric Algebra*.

This module uses unicode symbols as infix operators, but a ASCII method form is
also available.

| name              |digraph| infix notation  | method notation |
|-------------------|-------|-----------------|-----------------|
| outer product     | `AN`  | `$a ∧ $b`       | `$a.op($b)`     |
| inner product     | `.M`  | `$a · $b`       | `$a.ip($b)`     |
| scalar product    | `*-`  | `$a ∗ $b`       | `$a.sp($b)`     |
| commutator        | `*X`  | `$a × $b`       | `$a.co($b)`     |
| left contraction  | `7>`  | `$a ⌋ $b`       | `$a.lc($b)`     |
| right contraction | `7<`  | `$a ⌊ $b`       | `$a.rc($b)`     |
| dot product       | `Sb`  | `$a ∙ $b`       | `$a.dp($b)`     |

All those infix operators are tighter than `&infix:<*>`.

All symbols are available as Vim digraphs by default.

Beware of the symbol used for the scalar product.  It is the asterisk operator
(digraph `*-`), not the usual multiplication sign (`*`).  Here they are besides
one an other: `∗*`.  Also the symbols for inner product ("centered dot") and
dot product ("bullet operator", or "fat dot") look very similar in certain
fonts, apparently.

### Involutions

The module also implements the three involutions:

    given 1 + @e[0] + @e[0]∧@e[1] + @e[0]∧@e[1]∧@e[2] {
        say .reversion;    # 1+e0-e0∧e1-e0∧e1∧e2
        say .involution;   # 1-e0+e0∧e1-e0∧e1∧e2
        say .conjugation;  # 1-e0-e0∧e1+e0∧e1∧e2
    }

Here the involution called 'involution' is the so-called *main* involution.

The module exports two postfix operators `&postfix:<~>` and `&postfix:<^>`
respectively for the reversion and the main involution.

Optimization
------------

This module attempts to optimize computations by generating code during
runtime, as inspired by Pablo Colapinto's work (see next section).  In order to
understand how the method works, consider for instance the geometric product of
two vectors `X = x1*e1 + x2*e2 + x3*e3` and `Y = y1*e1 + y2*e2 + y3*e3`:

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
nothing and generates a function at runtime, every time it encounters a product
type it has never seen before.

To generate a function, early versions of this module were simply generating the literal string that defines it in
Perl 6 and use `EVAL` on it.  Current version uses a closure.

External links
--------

* [Geometric Algebra for Computer science](http://www.geometricalgebra.net) : a
  website and a book that helped for this project ;
* [Versor](https://github.com/wolftype/versor), a C++ implementation of the
  above reference.
