const examples = [
    '355/113',
    'pi=355/113',
    '1/2 + 3',
    '1+2',
    '2*(3+4)',
    '3.14e0',
    '3.14*e0',
    'a',
    'a+b',
    'a*b',
    'a b',
    'x*e1',
    '(a+b)**2',
    '(a+b)∧c',
    '(a*b)∧c',
    'a*b∧c',
    'x²',
    'a**b**c',
    'foo*(a-b)',
    '3.14*r**2',
    'u·v',
    'no·ni',
    'pi = 355/113',
    '(a-b)(a+b)',
    '1+u∧v',
    'no∧ni',
    'e0**2',
    'a·b∧c',
    'no + x*e1 + y*e2 + z*e3 + (x² + y² + z²)/2*ni'
];


let parser = require('./clifford').parser,
    errors = 0;
for (let example of examples) {
    try {
        let ast = parser.parse(example);
        console.log(`"${example}" parsed as ${ast.simplify()}`);
    } catch (e) {
        errors++;
        console.log(`"${example}": ${e}`);
    }
}
console.log(`${errors} errors out of ${examples.length} attempts`);
