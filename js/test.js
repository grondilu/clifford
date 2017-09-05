const examples = [
    '1',
    '3.14',
    '-1',
    'a',
    'foo',
    'a + b',
    'x+y',
    'a*(b+c)',
    '2/3',
    '2/7 + x**2/2',
    '(a - b)(a + b)'
];
let Parser = require('./parser'),
    parser = new Parser();

for (let example of examples) {
    console.log(parser.parse(example).toString());
}

