Geometric Algebra in Perl 6
===========================

[![Build Status](https://travis-ci.org/grondilu/clifford.svg)](https://travis-ci.org/grondilu/clifford)

This module is an attempt to implement basic [Geometric
Algebra](http://en.wikipedia.org/wiki/Geometric_Algebra) in Perl 6.

With this module you can create euclidean and anti-euclidean vectors of
arbitrary size.  You can then add and substract them, as well as multiplying
them by real scalars as you would do with any vectors, but you can also
multiply and divide as made possible by the geometric algebra.

Introduction
------------

The module exports two array constants `@e` and `@ē`.  They serve as orthonormal
basis for the Euclidean and anti-Euclidean spaces respectively.

    use Clifford;

    say @e[0]**2;   # +1
    say @ē[0]**2;   # -1

Any algebraic combination of those vectors is a multivector for which the
`AT-POS` method returns the grade projection:

    say (@e[0] + @e[0]*@e[1])[1];   # e0

Those two arrays, along with the grade projection, constitute the main
interface of the whole module.

Operations
----------

The module *does not* define any of the various products derived from the
geometric product.  However, the user can fairly easily define them.

For instance, for the inner product of two vectors:

    sub infix:<·> { ($^a*$^b + $a*$b)/2 }
    say @e[0]·(@e[0] + @e[1]);   # 1

The above example can only work if the arguments are vectors.  Ensuring this is
a bit involved and would probably cost in terms of performance.  That's why the
module does not try to find a compromise and let that decision to the user.

Defining a Vector subset can be done for instance as such:

    subset Vector of Clifford::MultiVector where { $_ == $_[1] }

External links
--------

* [Geometric Algebra for Computer science](http://www.geometricalgebra.net) : a
  website and a book that helped for this project ;
* [Versor](https://github.com/wolftype/versor), a C++ implementation of the
  above reference.  This uses advanced optimizations with precompilation and
stuff.  Ideally it should be possible to copy ideas from this, but it will need
work.
