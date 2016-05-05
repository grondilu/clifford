unit role MultiVector does Numeric;

# All implementations should be able to promote a Real
multi method new(Real $s) returns MultiVector {...}

# Grade projection
proto method AT-POS(UInt $n) returns MultiVector {*}

# The grades method should return a list of grades where
# the grade projection is not null.
# For instance (e0 + e0∧e1).grades should return 1, 2
method grades {...}

# real coefficients:
# for instance (no + 2*ni + 3*e0).reals --> (1, 2, 3);
# The order does not matter much.
method reals {...}

# conversion to Real as required by the Numeric role.
method Real {
    if any(self.grades) > 0 {
	fail X::Numeric::Real.new:
	target => Real,
	source => self,
	reason => 'not purely scalar'
	;
    }
    return self[0].reals[0];
}

# Boolean evaluation
multi method Bool { self.grades.elems > 0 }

# narrow method required by Numeric
method narrow returns Numeric {
    !self               ?? 0    !!
    self.grades.any > 0 ?? self !!
    self.Real.narrow
}

# addition prototype
proto method add($) returns MultiVector {*}

# scalar multiplication prototype
proto method scale(Real $) {*}
multi method scale(0) returns MultiVector { self.new: 0 }
multi method scale(1) returns MultiVector { self.clone }
multi method scale(Real $) returns MultiVector {...}

# Derived products:
# - gp: geometric product
# - ip: inner product
# - op: outer product
# - sp: scalar product
# - lc: left contraction
# - rc: right contraction
# - dp: dot product (a.k.a "fat" dot)
method gp(MultiVector $) returns MultiVector {...};
method ip(MultiVector $) returns MultiVector {...};
method op(MultiVector $) returns MultiVector {...};
method sp(MultiVector $) returns MultiVector {...};
method lc(MultiVector $) returns MultiVector {...};
method rc($a: MultiVector $b) returns MultiVector {
    ($b.reversion.lc($a.reversion)).reversion
}
method dp(MultiVector $) returns MultiVector {...};

# involutions
method reversion returns MultiVector {
    !self.grades ?? self.new(0) !!
    reduce { $^a.add($^b) },
    (self[$_].scale((-1)**($_*($_-1) div 2)) for self.grades)
}
method involution returns MultiVector {
    !self.grades ?? self.new(0) !!
    reduce { $^a.add($^b) },
    (self[$_].scale((-1)**$_) for self.grades)
}
method conjugation returns MultiVector {
    !self.grades ?? self.new(0) !!
    reduce { $^a.add($^b) },
    (self[$_].scale((-1)**($_*($_+1) div 2)) for self.grades)
}
