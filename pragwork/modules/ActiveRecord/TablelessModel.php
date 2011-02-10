<?php
namespace ActiveRecord;
class TablelessModel
{
	public $errors;
	private $_callback;

	public function __construct($attributes=null)
	{
	    Reflections::instance()->add($this);
	    $this->_callback = new CallBack(get_class($this));
	    if ($attributes)
	        $this->set_attributes($attributes);
	}
	
	public function attributes()
	{
	    $attributes = get_public_properties($this);
	    unset($attributes['errors']);
		return $attributes;
	}
	
	public function get_validation_rules()
	{
		$validator = new Validations($this);
		return $validator->rules();
	}

	public function get_values_for($attributes)
	{
		$ret = array();
		$public_attributes = $this->attributes();
    	foreach ($attributes as $name)
		{
			if (array_key_exists($name, $public_attributes))
				$ret[$name] = $this->$name;
    	}
    	return $ret;
    }

	public function values_for($attribute_names)
	{
		$filter = array();
		foreach ($attribute_names as $name)
			$filter[$name] = $this->$name;

		return $filter;
	}

	private function _validate()
	{
    	$validator = new Validations($this);
    	
    	if ($this->_callback->invoke($this, 'before_validation', false) 
    	    === false)
			return false;
        
        $this->errors = $validator->get_record();
        $validator->validate();
		$this->_callback->invoke($this, 'after_validation', false);
		return $this->errors->is_empty();
    }

	public function is_valid()
	{
		return $this->_validate();
	}

    public function is_invalid()
    {
    	return !$this->_validate();
    }
    
    public function update_attributes($attributes)
	{
		$this->set_attributes($attributes);
		return $this->is_valid();
	}

    public function set_attributes($attributes)
    {   
    	foreach ($attributes as $name => $value)
    	{
    	    if ($name !== 'errors')
    	        $this->$name = $value;
    	}
    }
    
    public function __get($name)
    {
        $name = "get_$name";
        if (method_exists($this, $name))
            return $this->$name();
        
        throw new UndefinedPropertyException(get_called_class(), $name);
    }

    public function __set($name, $value)
    {        
        if (method_exists($this, "set_$name"))
        {
            $name = "set_$name";
            return $this->$name($value);
        }
           
        throw new UndefinedPropertyException(get_called_class(), $name);
    }
}
?>