<?php
namespace ActiveRecord;
/**
 * @package ActiveRecord
 */
class StandardInflector extends Inflector
{
	public function tableize($s) 
	{ 
		return Utils::pluralize(strtolower($this->underscorify($s))); 
	}
	
	public function variablize($s) 
	{ 
		return str_replace(
			array('-',' '),
			array('_','_'),
			$this->uncamelize(trim($s))
		);	   
	}
}
?>