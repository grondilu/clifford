Geometric Algebra in Perl 6
===========================

This module is an attempt to implement basic [Geometric
Algebra](http://en.wikipedia.org/wiki/Geometric_Algebra) in Perl 6.

Geometric algebra is a mathematical formalism in which a vector space is given
a multiplicative operation called "geometric product".  The geometric product
is normally non-commutative and is usually seen as the oriented measure of the
space described by two or more vectors.

For instance, two vectors form a triangle and the product of these two vectors
represents the oriented area of that triangle.  Kind of as with the cross
product.

Geometric Algebras are sometimes called 'Clifford Algebras', thus the title of
this module.

Introduction
------------

The vector space is assumed to be given an orthogonal basis e0, e1, e2 ...etc.
There is no limit to the dimension, but it is countable.

The module exports a `sub e(Int $) {...}` function that allows you to create
those vectors easily:

    use Clifford;

    my $e = e(6);

Be aware that there is nothing special about `e(0)`.  It is not a scalar, but
the first unit vector or the orthogonal basis.  In other words, indexes do
start with 0 and not 1 (it's a difference often seen between maths and
computing).

`&e` can also return a lazy list of the elements of the orthogonal basis.  It is done
via a `*` parameter:

    .say for e(*)   # this shows the infinite list of basis vectors.  Press ^C to stop.
    
There is a non-exported global array called `@signature`, which is used to set
the squares values of the vectors of the orthogonal basis.  By default, this
signature is set to `1 xx *` so that all squares of `e($i)` is 1.  This corresponds
to a so-called Euclidean space but you can change this if you want:

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
    say no cdot ni;      # -1


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

Optimized imlementations for homogeneous and conformal models of the 3D Euclidean space.

Use stuff found in [this paper](http://hdl.handle.net/11245/2.52687)
