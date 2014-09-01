# Geometric Algebra in Perl 6

This module is an attempt to implement basic Geometric Algebra in Perl 6.

Geometric algebra is a mathematical formalism in which a vector space is given
a multiplicative operation called "geometric product".  The geometric product
is normally non-commutative and is usually seen as the oriented measure of the
space described by two or more vectors.

For instance, two vectors form a triangle and the product of these two vectors
represents the oriented area of that triangle.  Kind of as with the cross product.

Geometric Algebras are sometimes called 'Clifford Algebras', thus the title of
this module.


## Introduction

The vector space is assumed to be given an orthonormal basis e[0], e[1], e[2] etc.

The module exports a `&circumfix:<e[ ]>` operator that allows you to create those vectors easily:

    my $e = e[6];

As a special case, `e[ ]` returns 1.  It is the scalar unit of the Geometric Algebra.

    say e[] + 1;   # 2

There is a non-exported global array called `@signature` that is used to set
the squares values of the vectors of the orthonormal basis.  By default, this signature is set to
`1 xx *` so that all squares of `e[i]` is 1.  You can change that if you want:

    @Clifford::signature[0] = -1;
    say e[0]**2;   # -1;

The signature should normally only be -1, 0 or +1 but no safety check is made
about this, so be warry.

`&circumfix:<e[ ]>` can also be called with several, strictly increasing
indexes, in which case it means the product of the corresponding vectors of the
orthonormal basis.

    my $a = e[1, 3, 5];  # fine
    my $b = e[-1, 3, 5]; # WRONG (will die) : only non-negative indexes
    my $c = e[4, 3, 5];  # WRONG (will die) : index list must be increasing
    my $d = e[4, 4, 5];  # WRONG (will die) : index list must be strictly increasing


## What can be done?

Well, you can add and multiply vectors and multivectors:

    my $a = e[1];
    my $b = e[3, 4];
    say $a + $b;
    say ($a + $b)**2;

You can get the grade projection of a multivector with `postcircumfix:<[ ]>($n)`:

    say (1 + e[1])[0];  # 1

Everything else follows.
