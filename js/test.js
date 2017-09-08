const examples = [
    '355/113',
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
    'a∧b∧c',
    'a*b∧c',
    'x²',
    'a**b**c',
    'foo*(a-b)',
    '3.14*r**2',
    '1/2*3/5',
    '(2/3)**2',
    '1+1',
    'u·v',
    'no',
    'ni',
    'no²',
    'ni²',
    'no·ni',
    'no·e0',
    'pi = 355/113',
    'pi',
    '(a-b)(a+b)',
    '1+u∧v',
    'no∧ni',
    'e0**2',
    'e0*e1',
    'e1*e1',
    'e0·e1',
    'e0·e0',
    'ē0',
    'ē0·ē0',
    'ē0·ē1',
    'ē0·e1',
    'e1·ē1',
    'a·b∧c',
    'no + x*e1 + y*e2 + z*e3 + (x² + y² + z²)/2*ni'
];


let parser = require('./clifford').parser,
    errors = 0;
for (let example of examples) {
    try {
        let compute = parser.parse(example).compute();
        console.log(`"${example}" parsed as ${compute}`);
    } catch (e) {
        errors++;
        console.log(`"${example}": ${e}`);
    }
}
console.log(`${errors} errors out of ${examples.length} attempts`);
