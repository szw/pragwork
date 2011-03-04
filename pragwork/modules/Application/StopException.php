<?php
namespace Application;

/**
 * An exception throwing to stop the action processing. Throw it instead of 
 * calling <code>die()</code> or <code>exit()</code> functions.
 *
 * @author Szymon Wrozynski
 * @package Application
 */
class StopException extends \Exception {}
?>