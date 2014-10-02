requires 'perl', '5.008005';

requires 'Moo';
requires 'XML::Simple';
requires 'Mojo::UserAgent';

on test => sub {
    requires 'Test::More', '0.96';
};
