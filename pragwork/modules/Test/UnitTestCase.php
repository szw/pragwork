<?php
namespace Test;

/**
 * Base unit test class
 * 
 * @package Test
 * @author Jason Frame
 */
class UnitTestCase extends TestCase
{
	/**
	 * Called before every test case
	 */
	protected function setup() {}
	
	/**
	 * Called after every test case
	 */
	protected function teardown() {}
	
	protected function do_run_one(TestInvoker $tmi) 
	{
		$this->setup();
		$tmi->invoke($this);
		$this->teardown();
	}
}
?>