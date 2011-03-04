<?php
namespace Test;

/**
 * Functional test class for controller testing.
 * 
 * @package Test
 * @author Szymon Wrozynski
 */
class ControllerTestCase extends UnitTestCase
{
	/**
	 * The controller instance extended with special testing methods. 
	 * This instance is created anew before each test. The controller class
	 * is guessed after the test class name.
	 *
	 * @var \Application\Controller
	 */
	protected $controller;
	
	protected function do_run_one(TestInvoker $tmi) 
	{
		$controller = substr($this->get_name(), 0, -4);
		$this->controller = $controller::instance();
		try 
		{
			parent::do_run_one($tmi);
		} 
		catch (\Exception $e) 
		{
			$this->controller->clean_up();
			throw $e;
		}
		$this->controller->clean_up();
		$this->controller = null;
	}
	
	/**
	 * Sets the test environment and perform an action. It creates a new request, passes it to the
	 * {@link process()} method of the {@link Application\Controller} class and returns the
	 * {@link TestResponse} object.
	 *
	 * The following options are available:
	 *
	 * <ul>
	 * <li><b>locale</b>: the locale code used in the simulated request</li>
	 * <li><b>path_params</b>: the parameters passed via the path
	 * <li><b>query_params</b>: the parmeters passed as the query string</li>
	 * <li><b>request_params</b>: the parameters passed through the request 
	 *	   body</li>
	 * <li><b>session</b>: the array used in the {@link Session}</li>
	 * <li><b>cookies</b>: the array used in the {@link Cookies}</li>
	 * <li><b>method</b>: the request method (GET, POST, PUT, DELETE)</li>
	 * <li><b>ip</b>: the client ip (default 127.0.0.1)</li>
	 * </ul>
	 *
	 * @param string $action The action name
	 * @param array $options Options
	 * @return TestResponse The response object
	 */
	public function action($action, $options=array())
	{
		$request = TestRequest::instance($action, $options);
		$response = TestResponse::instance(true);
		$this->controller->process($request, $response);
		$response->render();
		return $response;
	}
}
?>