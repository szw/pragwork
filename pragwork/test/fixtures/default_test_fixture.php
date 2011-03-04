<?php
const USE_COLOR = true;
modules('test');

# Add your setup stuff specific to your test suite here, e.g. fill the test
# database with default testing data.

$suite = new Test\TestSuite('Pragwork Tests');
$suite->require_all('Models');
$suite->require_all('Controllers');
$suite->run();
?>