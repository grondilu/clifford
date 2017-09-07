const examples = [
    '355/113',
    'pi=355/113',
    '1/2 + 3',
    '1+2',
    '2*(3+4)',
    '3.14e0',
    'a',
    'a+b',
    '(a+b)**2',
    'a**b**c',
    'foo*(a-b)',
    '3.14*r**2',
    'u·v',
    'no·ni',
    'x=pi/3',
    'y = pi/5',
    '355/113*x',
    '(a-b)(a+b)',
    '1+u∧v',
    'no∧ni',
    'e0**2',
    'a·b∧c',
];

let parser = require('./clifford').parser,
    errors = 0;
for (let example of examples) {
    try {
        parser.parse(example);
        console.log(`"${example}" parsed`);
    } catch (e) {
        errors++;
        console.log(`"${example}": ${e}`);
    }
}
console.log(`${errors} errors out of ${examples.length} attempts`);
