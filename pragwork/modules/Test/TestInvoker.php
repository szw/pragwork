<?php
namespace Test;

/**
 * TestInvoker instances know how to run a single test on a given TestCase.
 */
abstract class TestInvoker
{
	public abstract function invoke(TestCase $instance);
}
?>