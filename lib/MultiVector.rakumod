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
