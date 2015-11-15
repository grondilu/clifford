Geometric Algebra in Perl 6
===========================

[![Build Status](https://travis-ci.org/grondilu/clifford.svg)](https://travis-ci.org/grondilu/clifford)

This module is an attempt to implement basic [Geometric
Algebra](http://en.wikipedia.org/wiki/Geometric_Algebra) in Perl 6.

Geometric algebra is a mathematical formalism in which a vector space is given
a multiplicative operation called "geometric product".  The geometric product
is normally non-commutative and is usually seen as the oriented measure of the
space described by two or more vectors.

For instance, two vectors form a triangle and the product of these two vectors
represents the oriented area of that triangle.  Kind of as with the cross
product, except that with geometric algebra there is no arbitrary choice of
sign.

Geometric Algebras are sometimes called 'Clifford Algebras', thus the title of
this module.

Introduction
------------

The module exports a `sub e(Int $) {...}` function that allows you to create
vectors of an orthonormal basis e0, e1, e2 ...etc.

    use Clifford;

    my $e = e(6);

It is also possible to call this function with `Whatever` to get the infinite
orthonormal basis itself.  It can be used to create a vector from an array of
coefficients.

    say [+] 1, 2 Z* e(*);  # e(0) + 2*e(1)

This `&e` subroutine is essentially the only user interface for the class.
Everything you can do with this module, you can do it with algebraic operations
on these vectors.

Be aware that there is nothing special about `e(0)`.  It is not a scalar, but
the first unit vector or the orthogonal basis.  In other words, indexes do
start with 0 and not 1 (it's a difference often seen between maths and
computing).

There is a non-exported array called `@signature`, which is used to set the
squares values of the vectors of the orthogonal basis.  By default, this
signature is set to `1 xx *` so that all squares of `e($i)` is 1.  This
corresponds to a so-called Euclidean space but you can change this if you want:

    @Clifford::signature[0] = -1;  # Lorentzian metric
    say e(0)**2;   # -1;

The signature should normally only be -1, 0 or +1 but no safety check is made
about this, so be warry.  Also, it's not clear to me if it makes sense to accept
a nul value here, for the metric is assumed to be diagonalized.  For instance in order
to specify the conformal model, one should use e+ and e- in the metric, not no nor ni.
E.g. for the conformal model of the 3D space:

    @Clifford::signature[0] := -1;
    constant no = (e(0) - e(4))/2;
    constant ni = e(0) + e(4);

    say no**2;           # 0
    say ni**2;           # 0

    sub infix:<cdot>($a, $b) { ($a*$b + $b*$a)/2 }
    say no cdot ni;      # -1


Implementation
--------------

Although the knowledge of the implementation design is hopefully not required
for using this module, a basic understanding may be useful for instance to
people willing to write extensions or improvements.

The modules defines two roles `Vector` and `MultiVector` in two different unit
compilation files.

In order to implement the `MultiVector` role, a class must define the following
methods:

 * `blades` needs to return a hash for which all keys are positive integers and
   all values are real numbers.  The key is the binary encoding of the blade.
The value is the linear coefficient.  For instance, the pairs 0b1011 => -2
represents the blade `-2*e(0)*e(1)*e(3)`.
 * `grade-projection(UInt $n)` returns the grade projection on grade `$n`.  It
   should be an instance of the same class.

The `Vector` role inherits from `MultiVector` and `Positional`.  It provides
default `blades` and `grade-projection(UInt $)` methods, so any class
implementing `Positional` can be used as a Vector by just mixing it, with
fairly predicitble semantics.
 
What can be done?
-----------------

Well, you can add and multiply vectors and multivectors:

    my $a = e(1);
    my $b = e(3)*e(5);
    say $a + $b;
    say ($a + $b)**2;

You can get the grade projection of a multivector with `postcircumfix:<[ ]>($n)`:

    say (1 + e(1))[0];  # 1

Everything else follows.

TODO
----

More tests.  Better performance.  Possibly using NativeCall for the heavy lifting.

Optimized implementations for homogeneous and conformal models of the 3D Euclidean space.

Use stuff found in [this paper](http://hdl.handle.net/11245/2.52687)
