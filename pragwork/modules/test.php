<?php
/**
 * Test Module 1.0 for Pragwork 1.1.0
 *
 * @copyright Copyright (c) 2009 Jason Frame (ztest), 
 *			  Szymon Wrozynski (the module and additions)
 * @license Licensed under the MIT License
 * @version 1.1.0
 * @package Activerecord
 */

// Assertions are written as normal functions and we use a static property on
// Test_Base to keep track of state. The reason: it's less to type. No one likes
// writing $this->assert() over and over.

function pass() 
{
	ensure(true);
}

function fail($msg='') 
{
	ensure(false, $msg);
}

/**
 * Assert
 * 
 * @param $v value to be checked for truthiness
 * @param $msg message to report on failure
 */
function ensure($v, $msg='') 
{
	if (!$v) 
	{
		Test\TestCase::$reporter->assert_fail();
		throw new Test\AssertionFailed($msg);
	} else {
		Test\TestCase::$reporter->assert_pass();
	}
}

function assert_each($iterable, $test, $msg='') 
{
	foreach ($iterable as $i) 
		ensure($test($i), $msg);
}

function assert_object($v, $msg='') 
{
	ensure(is_object($v), $msg ?: "'" . strval($v) . "' should be an object.");
}

function assert_array($v, $msg='') 
{
	ensure(is_array($v), $msg ?: "'" . strval($v) . "' should be an array.");
}

function assert_scalar($v, $msg='') 
{
	ensure(is_scalar($v), $msg ?: "'" . strval($v) . "' should be a scalar.");
}

function assert_not_equal($l, $r, $msg='') 
{
	ensure($l != $r, $msg ?: 'Values should not be equal.');
}

function assert_equal($l, $r, $msg='') 
{
	ensure($l == $r, $msg ?: "Values should be equal (expected '" . strval($l) . "' but was '" . strval($r) . "').");
}

function assert_identical($l, $r, $msg='') 
{
	ensure($l === $r, $msg ?: "Values should be identical (expected '" . strval($l) . "' but was '" . strval($r)."')."); 
}

function assert_equal_strings($l, $r, $msg='') 
{
	ensure(strcmp($l, $r) === 0, $msg ?: "Dtrings should be equal (expected '$l' but was '$r').");	
}

function assert_match($regex, $r, $msg='') 
{
	ensure(preg_match($regex, $r), $msg ?: "'$r' does not match the pattern '$r'.");	
}

function assert_null($v, $msg='') 
{
	ensure($v === null, $msg ?: "Value should be null (was '".strval($v)."').");
}

function assert_not_null($v, $msg='') 
{
	ensure($v !== null, $msg ?: 'Value should not be null.');
}

// NOTE: this assertion swallows all exceptions
function assert_throws($exception_class, $lambda, $msg='') 
{
	try 
	{
		$lambda();
		fail($msg ?: "Expected $exception_class but nothing was thrown.");
	} 
	catch (Exception $e) 
	{
		if (is_a($e, $exception_class))
			pass();
		else
			fail($msg ?: "Expected $exception_class but was " . get_class($e) . '.');
	}
}

/**
 * Wraps the common pattern of having a map of input => expected output that you
 * wish to check against some function.
 * 
 * @param $data_array map of input value => expected output
 * @param $lambda each input value will be passed to this function and compared
 *		  against expected output.
 */
function assert_output($data_array, $lambda) 
{
	foreach ($data_array as $input => $expected_output)
		assert_equal($expected_output, $lambda($input));
}

/**
 * This one's a bit dubious - it tests that an assertion made by the supplied
 * lambda fails. It primarily exists for self-testing the ztest library, and
 * using it causes the displayed assertion stats to be incorrect.
 */
function assert_fails($lambda, $msg='') 
{
	$caught = false;
	try 
	{
		$lambda();
	} 
	catch (Test\AssertionFailed $e) 
	{
		$caught = true;
		pass();
	}
	if (!$caught) 
	{
		throw new Test\AssertionFailed($msg ?: 'The assertion should fails.');
	}
}

## Assertions for controller testing (Szymon Wrozynski)

function assert_status($status, $msg='')
{
	$r = Test\TestResponse::instance();
	
	if (!$r)
		throw new \ErrorException('No response yet.');
	
	$expected = Test\TestResponse::resolve_full_status($status);
	$was = $r->full_status();
	ensure($was === $expected, $msg ?: "Expected status $expected but was: $was.");
}

function assert_redirected_to($options, $msg='')
{
	$r = Test\TestResponse::instance();
	
	if (!$r)
		throw new \ErrorException('No response yet.');
	
	$url = url_for($options);
	ensure($r->location === $url, $msg ?: "Expected a redirection to $url but was: $r->location.");
}

function assert_content_type($expected, $msg='')
{
	$r = Test\TestResponse::instance();
	
	if (!$r)
		throw new \ErrorException('No response yet.');
	
	ensure($r->content_type == $expected, 
		$msg ?: "Expected the rendered content type to be $expected but was: $r->content_type.");
}

function assert_template($expected, $msg='')
{
	$r = Test\TestResponse::instance();
	
	if (!$r)
		throw new \ErrorException('No response yet.');
	
	ensure($r->template == $expected, $msg ?: "Expected the rendered template to be $expected but was: $r->template.");
}

function assert_layout($expected, $msg='')
{
	$r = Test\TestResponse::instance();
	
	if (!$r)
		throw new \ErrorException('No response yet.');
	
	ensure($r->layout == $expected, $msg ?: "Expected the rendered layout to be $expected but was: $r->layout.");
}

spl_autoload_register(function($class)
{
	if (strpos($class, 'Test\\') === 0)
		require MODULES . str_replace('\\', DIRECTORY_SEPARATOR, $class).'.php';
	elseif (strpos($class, 'Application\\') === 0)
	{
		$file = MODULES . 'Test' . DIRECTORY_SEPARATOR . str_replace('\\', DIRECTORY_SEPARATOR, $class) . '.php';
		if (is_file($file))
			require $file;
	}
}, true, true);
?>