<?php
/**
 * ActiveRecord Module 1.1 for Pragwork 1.1.0
 *
 * @copyright Kien La, Jacques Fuentes (PHP ActiveRecord Library), 
 *			  Szymon Wrozynski (the module and additions)
 * @license Licensed under the MIT License
 * @version 1.1.0
 * @package Activerecord
 */

/*
Copyright (c) 2009

AUTHORS:
Kien La
Jacques Fuentes

Modifications for Pragwork: Szymon Wrozynski
TablelessModel: Szymon Wrozynski
Some bug fixes: Szymon Wrozynski

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

namespace ActiveRecord;
/*
 * Thanks to http://www.eval.ca/articles/php-pluralize (MIT license)
 *	http://dev.rubyonrails.org/browser/trunk/activesupport/lib/active_support/inflections.rb (MIT license)
 *			 http://www.fortunecity.com/bally/durrus/153/gramch13.html
 *			 http://www2.gsu.edu/~wwwesl/egw/crump.htm
 *
 * Changes (12/17/07)
 *	 Major changes
 *	 --
 *	 Fixed irregular noun algorithm to use regular expressions just like the original Ruby source.
 *		 (this allows for things like fireman -> firemen
 *	 Fixed the order of the singular array, which was backwards.
 *
 *	 Minor changes
 *	 --
 *	 Removed incorrect pluralization rule for /([^aeiouy]|qu)ies$/ => $1y
 *	 Expanded on the list of exceptions for *o -> *oes, and removed rule for buffalo -> buffaloes
 *	 Removed dangerous singularization rule for /([^f])ves$/ => $1fe
 *	 Added more specific rules for singularizing lives, wives, knives, sheaves, loaves, and leaves and thieves
 *	 Added exception to /(us)es$/ => $1 rule for houses => house and blouses => blouse
 *	 Added excpetions for feet, geese and teeth
 *	 Added rule for deer -> deer
 *
 * Changes:
 *	 Removed rule for virus -> viri
 *	 Added rule for potato -> potatoes
 *	 Added rule for *us -> *uses
 */
function classify($class_name, $singularize=false)
{
	if ($singularize)
		$class_name = Utils::singularize($class_name);

	$class_name = Inflector::instance()->camelize($class_name);
	return ucfirst($class_name);
}

// http://snippets.dzone.com/posts/show/4660
function array_flatten(array $array)
{
	$i = 0;

	while ($i < count($array))
	{
		if (is_array($array[$i]))
			array_splice($array,$i,1,$array[$i]);
		else
			++$i;
	}	
	return $array;
}

/**
 * Somewhat naive way to determine if an array is a hash.
 */
function is_hash(&$array)
{
	if (!is_array($array))
		return false;

	$keys = array_keys($array);
	return @is_string($keys[0]) ? true : false;
}

/**
 * Strips a class name of any namespaces and namespace operator.
 *
 * @param string $class
 * @return string stripped class name
 * @access public
 */
function denamespace($class_name)
{
	if (is_object($class_name))
		$class_name = get_class($class_name);

	if (has_namespace($class_name))
	{
		$parts = explode('\\', $class_name);
		return end($parts);
	}
	return $class_name;
}

/**
 * Adds the 'Models' namespace to the given class name if there is no namespace 
 * yet.
 *
 * $param string $class_name
 * return string Class name prepended with the 'Models' namespace
 */
function add_namespace($class_name)
{
	return (strpos($class_name, '\\') === false)
		? 'Models\\' . $class_name
		: $class_name;
}

function get_namespaces($class_name)
{
	if (has_namespace($class_name))
		return explode('\\', $class_name);
	return null;
}

function has_namespace($class_name)
{
	if (strpos($class_name, '\\') !== false)
		return true;
	return false;
}

/**
 * Returns true if all values in $haystack === $needle
 * @param $needle
 * @param $haystack
 * @return unknown_type
 */
function all($needle, array $haystack)
{
	foreach ($haystack as $value)
	{
		if ($value !== $needle)
			return false;
	}
	return true;
}

function collect(&$enumerable, $name_or_closure)
{
	$ret = array();

	foreach ($enumerable as $value)
	{
		if (is_string($name_or_closure))
			$ret[] = is_array($value) ? $value[$name_or_closure] : $value->$name_or_closure;
		elseif ($name_or_closure instanceof Closure)
			$ret[] = $name_or_closure($value);
	}
	return $ret;
}

function get_public_properties($obj)
{
	return get_object_vars($obj);
}

spl_autoload_register(function($class)
{
	if (strpos($class, 'ActiveRecord\\') === 0)
		require MODULES . str_replace('\\', DIRECTORY_SEPARATOR, $class) . '.php';
});

require CONFIG . 'activerecord.php';
?>