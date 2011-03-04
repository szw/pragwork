<?php
namespace Test;

/**
 * MethodInvoker runs a single test by invoking a method on the TestCase
 */
class MethodInvoker extends TestInvoker
{
	private $method;
	
	public function __construct(\ReflectionMethod $method) 
	{
		$this->method = $method;	
	}
	
	public function invoke(TestCase $instance) 
	{
		$this->method->invoke($instance);
	}
}
?>