<?php
namespace ActiveRecord;
/**
 * Manages configuration options for ActiveRecord.
 *
 * <code>
 * ActiveRecord\Configuration::initialize(function($cfg) {
 *	 $cfg->connections = array(
 *	   'development' => 'mysql://user:pass@development.com/awesome_development',
 *	   'production' => 'mysql://user:pass@production.com/awesome_production'
 *   );
 * });
 * </code>
 *
 * @package ActiveRecord
 */
class Configuration extends \Application\ModuleConfiguration
{
	protected static $instance;
	
	protected static $defaults = array(
		'connection' => null,
		'logging' => false,
		'logger' => null
	);
	
	/**
	 * Returns a connection string if found otherwise null.
	 *
	 * @param string $environment Name of the environment
	 * @return string connection info for specified environment
	 */
	public function connection_for($environment)
	{
		if (isset($this->env_vars[$environment]['connection']))
			return $this->env_vars[$environment]['connection'];
	}
	
	/**
	 * Sets the url for the cache server to enable query caching.
	 *
	 * Only table schema queries are cached at the moment. A general query cache
	 * will follow.
	 *
	 * Example:
	 *
	 * <code>
	 * $config->set_cache("memcached://localhost");
	 * $config->set_cache("memcached://localhost",array("expire" => 60));
	 * </code>
	 *
	 * @param string $url Url to your cache server.
	 * @param array $options Array of options
	 */
	public function set_cache($url, $options=array())
	{
		Cache::initialize($url, $options);
	}
}
?>