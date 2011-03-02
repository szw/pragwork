<?php
namespace Tags;

/**
 * The helper class used inside the form body building closure of the {@link form_for()} function. 
 * 
 * It serves as a container of functions creating fields of the form as well as a wrapper of the attached model. 
 * All public properties of the model are available as properties of the form class.
 * Also, all form methods are aware of corresponding model values. 
 *
 * @see form_for()
 * @author Szymon Wrozynski
 */
class Form
{
	private $_model;
	
	/**
	 * The default constructor. 
	 * 
	 * The model might be an object, an array, or a null. If the array is passed it is automatically cast to an object.
	 *
	 * @param mixed $model Model passed to the {@link form_for()} function
	 */
	public function __construct($model=null)
	{
		if ($model)
			$this->_model = ((array) $model === $model) ? (object) $model : $model;
	}
		
	/**
	 * Sets a model property (if a model has been attached).
	 *
	 * @param string $name Name of the property
	 * @param mixed $value Property value
	 */
	public function __set($name, $value)
	{
		if ($this->_model)
			$this->_model->$name = $value;
	}
	
	/**
	 * Gets a model property (if a model has been attached).
	 *
	 * @param string $name Name of the property
	 * @return mixed Model property or null
	 */
	public function __get($name)
	{
		return ($this->_model) ? $this->_model->$name : null;
	}
		
	/**
	 * Returns a model reference.
	 *
	 * @return mixed Reference to the attached model (or null)
	 */
	public function &model()
	{
		return $this->_model;
	}
	
	/**
	 * Returns <code>true</code> if there are any error messages in the model for the specified field or for all fields
	 * (if none given).
	 *
	 * @param mixed $name Field name or e.g. null for all fields
	 * @return bool True if there are error messages or false otherwise
	 */
	public function is_error($name=null)
	{
		return $name 
			? $this->_model && $this->_model->errors && $this->_model->errors->$name
			: $this->_model && $this->_model->errors && !$this->_model->errors->is_empty();
	}

	/**
	 * Returns error messages after the form validation for the given field name or for all fields if no name was 
	 * passed. 
	 * 
	 * If there are no errors the null is returned. It works with ActiveRecord validation engine and expects 
	 * {@link ActiveRecords\Errors} object to be present in the model.
	 *
	 * The following options are available:
	 *
	 * <ul>
	 * <li><b>separator</b>: separator between a displayed name and a message. If empty, the field names in the
	 *     constructed messages are omitted. Otherwise field names optionally translated are used.  Default: ' '</li>
	 * <li><b>wrap_in</b>: name of the enclosing tag</li>
	 * <li><b>localize</b>: <b>true</b>/<b>false</b> to explicitly turn on/off localization</li>
	 * </ul>
	 *
	 * If the <code>wrap_in</code> is not present then error messages are separated with a dot. If localization is
	 * turned on, the message and name are translated separately.
	 *
	 * All other options are appended to the enclosing tag as attributes.
	 *
	 * @param mixed $name Field name or e.g. null for all fields
	 * @param array $options Formatting options
	 * @return string Error messages or HTML tag(s)
	 */
	public function error_messages($name, $options=array())
	{
		if ($this->_model && $this->_model->errors)
		{
			static $localization;
			
			if (!isset($localization))
				$localization = \Application\Configuration::instance()->localization;
			
			$localize = isset($options['localize']) ? $options['localize'] : ($localization !== false);
			$separator = isset($options['separator']) ? $options['separator'] : ' ';
			
			if ($name)
			{
				$error_messages = $this->_model->errors->$name;
			
				if (!$error_messages)
					return;
				
				if ($separator)
					$name = $localize ? t($name) : ucfirst(str_replace('_', ' ', $name));
				else
					$name = '';
				
				foreach ($error_messages as &$em)
					$em = $name . $separator . ($localize ? t($em) : $em);
			}
			else
				$error_messages = $this->_model->errors->full_messages($separator, $localize);
			
			if (isset($options['wrap_in']))
			{
				$tag_opening = '<' . $options['wrap_in'];
				$tag_close = '</' . $options['wrap_in'] . '>'; 
				
				unset($options['wrap_in'], $options['localize'], $options['separator']);
				
				foreach ($options as $n => $v) 
					$tag_opening .= ' ' . $n . '="' . $v . '"';
				
				$tag_opening .= '>';
				
				$html = '';
				
				foreach ($error_messages as $msg)
					$html .= $tag_opening . $msg . $tag_close;
				
				return $html;
			}
			else
				return implode('. ', $error_messages);
		}
	}
	
	/**
	 * Creates the <code><label></code> tag for the given field name. 
	 * 
	 * It uses localization or simple name humanization if no value supplied.
	 * 
	 * @param string $name Field name
	 * @param string $value Label value
	 * @param array $options Formatting options
	 * @return string <code><label></code> HTML tag
	 */
	public function label($name, $value=null, $options=array())
	{
		static $localization;
		
		if (!isset($localization))
			$localization = \Application\Configuration::instance()->localization;
		
		$html = '<label';
		
		if ($value === null) 
			$value = ($localization !== false) ? t($name) : ucfirst(str_replace('_', ' ', $name));
		
		if (!isset($options['for']))
			$html .= ' for="' . $name . '-field"';
		
		foreach ($options as $n => $v)
			$html .= ' ' . $n . '="' . $v . '"';
		
		return $html . '>' . $value . '</label>';
	}

	/**
	 * Creates the <code><select></code> tag for the given field name. 
	 *
	 * The passed <code>$collection</code> is an array of possible select values. The array may contain objects and/or
	 * key-value pairs, or just strings (strings will be used both as keys and values). For objects it is possible to
	 * set property names for the option text and value or even more specified closures.
	 *
	 * Formatting options:
	 *
	 * <ul>
	 * <li><b>option_text</b>: property name or a closure</li>
	 * <li><b>option_value</b>: property name or a closure</li>
	 * <li><b>selected</b>: closure comparing the current value and the
	 *	   model</li>
	 * <li><b>blank</b>: special blank option value</li>
	 * </ul> 
	 *
	 * The <code>option_text</code> and <code>option_value</code> might be property names or anonymous functions which
	 * transform an object from the <code>$collection</code> into the option text or value:
	 *
	 * <code>
	 * $f->select('person', $this->persons, array('option_text' =>
	 *	   function($p) { return $p->first_name . ' ' . $p->last_name; }));
	 * </code>
	 *
	 * The default value for <code>option_text</code> is <code>name</code> and 
	 * for <code>option_value</code> - <code>id</code>.
	 *
	 * The <code>selected</code> could be a closure of form: 
	 *
	 * <code> 
	 * bool function($model, $value)
	 * </code>
	 *
	 * The default closure used looks similarily to this one: 
	 *
	 * <code>
	 * function($model, $value) use ($name) 
	 * {
	 *	   return $model && $model->$name == $value;
	 * }
	 * </code>
	 *
	 * The <code>blank</code> option could be: 
	 *
	 * <code>
	 * $f->select('opt', $this->options, array('blank' => array(
	 *	   'Please choose a value' => 0
	 * )));
	 * </code>
	 *
	 * Other options are appended as the <code><select></code> tag attributes.
	 *
	 * @param string $name Field name
	 * @param string $collection Possible selectable options
	 * @param array $options Formatting options
	 * @return string <code><select></code> HTML tag
	 */
	public function select($name, $collection, $options=array())
	{
		$html = '<select name="' . $name . '"';
		
		if (!isset($options['id'])) 
			$html . ' id="' . $name . '-field"';
		
		if (isset($options['option_text'])) 
		{
			$option_text = $options['option_text'];
			unset($options['option_text']);
		} 
		else 
			$option_text = 'name';
		
		if (isset($options['option_value'])) 
		{
			$option_value = $options['option_value'];
			unset($options['option_value']);
		}
		else 
			$option_value = 'id';
			
		if (isset($options['selected']))
		{
			$selected_closure = $options['selected'];
			unset($options['selected']);
		}
		else
		{
			$selected_closure = function($model, $value) use ($name) 
			{
				return $model && $model->$name == $value;
			};
		}
		
		if (isset($options['blank']))
		{
			if ((array) $options['blank'] === $options['blank'])
				$collection = array_merge($options['blank'], $collection);
			else
				array_unshift($collection, $options['blank']);
			
			unset($options['blank']);
		}
		
		foreach ($options as $n => $v)
			$html .= ' ' . $n . '="' . $v . '"';
		
		$html .= '>';
		
		foreach ($collection as $n => $v) 
		{
			if ((object) $v === $v)
			{
				$n = ((string) $option_text === $option_text) ? $v->$option_text : $option_text($v);
				$v = ((string) $option_value === $option_value) ? $v->$option_value : $option_value($v);
			}
			elseif ((int) $n === $n)
				$n = $v;
			
			$html .= '<option value="' . $v . '"';
			
			if ($selected_closure($this->_model, $v))
				$html .= ' selected="selected"';
			
			$html .= '>' . $n . '</option>';
		}
		
		return $html . '</select>';
	}

	private function checked_input($name, $options) 
	{
		$html = '<input name="' . $name . '"';
		
		if (!isset($options['id']))
			$html .= ' id="' . $name . '-field"';
		
		if (!isset($options['value'])) 
			$options['value'] = 1;
		
		if (isset($options['checked'])) 
		{
			if ($options['checked'])
				$html .= ' checked="checked"';
			
			unset($options['checked']);
		} 
		elseif ($this->_model && ($this->_model->$name == $options['value']))
			$html .= ' checked="checked"';
		
		foreach ($options as $n => $v)
			$html .= ' ' . $n . '="' . $v . '"';
			
		return $html . ' />';
	}

	/**
	 * Creates the <code><input></code> radio tag for the given field name. 
	 *
	 * The options serve as tag attributes. The default <code>name</code> attribute is set to the field name, 
	 * the default value is set to 1. The <code>checked</code> attribute can be set explicitly or estimated 
	 * from the comparision of the model field (<code>$name</code>) and the value.
	 *
	 * @see check_box()
	 * @param string $name Field name
	 * @param array $options Formatting options
	 * @return string <code><input></code> radio button
	 */
	public function radio_button($name, $options=array()) 
	{
		$options['type'] = 'radio';
		return $this->checked_input($name, $options);
	}
	
	/**
	 * Creates the <code><input></code> check box tag for the given field name. 
	 *
	 * Formatting options:
	 *
	 * <ul>
	 * <li><b>unchecked</b>: value of the unchecked box</li>
	 * </ul>
	 *
	 * There is a hidden field put before the the check box containing the value of the <code>unchecked</code> option.
	 * If the check box is not checked, the hidden field value is sent instead of nothing. If the <code>unchecked</code> 
	 * option is not present then it is implicitly set to 0. If the <code>unchecked</code> is set to <code>false</code> 
	 * then no hidden field prepends the check box tag.
	 *
	 * The other options serve as attributes. The default <code>name</code> attribute is set to the field name, 
	 * the default value is set to 1. The <code>checked</code> attribute can be set explicitly or estimated
	 * from the comparision of the model field (<code>$name</code>) and the value.
	 *
	 * @see radio_button()
	 * @param string $name Field name
	 * @param array $options Formatting options
	 * @return string <code><input></code> check box
	 */
	public function check_box($name, $options=array())
	{
		$options['type'] = 'checkbox';

		if (isset($options['unchecked']))
		{	
			$hidden = ($options['unchecked'] === false)
				? '' 
				: $this->hidden_field($name, array('value' => $options['unchecked']));
			
			unset($options['unchecked']);
			return $hidden . $this->checked_input($name, $options);
		}
		else
			return $this->hidden_field($name, array('value' => 0)) . $this->checked_input($name, $options);
	}
	
	/**
	 * Creates the <code><textarea></code> tag for the given field name. 
	 *
	 * The options serve as tag attributes. The default <code>name</code> attribute is set to the field name as well 
	 * as the <code>id</code> one. 
	 *
	 * @param string $name Field name
	 * @param array $options Formatting options
	 * @return string <code><textarea></code> HTML tag
	 */
	public function text_area($name, $options=array()) 
	{
		$html = '<textarea name="' . $name . '"';
			
		if (!isset($options['id']))
			$html .= ' id="' . $name . '-field"';
		
		foreach ($options as $n => $v)
			$html .= ' ' . $n . '="' . $v . '"';
		
		return $html . '>' . htmlspecialchars($this->_model->$name) . '</textarea>';
	}
	
	/**
	 * Creates the <code><input></code> file tag for the given field name. 
	 *
	 * The options serve as tag attributes. The default <code>name</code> attribute is set to the field name as well 
	 * as the <code>id</code> one. 
	 *
	 * @param string $name Field name
	 * @param array $options Formatting options
	 * @return string <code><input></code> file HTML tag
	 */
	public function file_field($name, $options=array())
	{
		$html = '<input type="file" name="' . $name . '"';
			
		if (!isset($options['id']))
			$html .= ' id="' . $name . '-field"';
		
		foreach ($options as $n => $v)
			$html .= ' ' . $n . '="' . $v . '"';
			
		return $html . ' />';
	}
	
	private function valued_input($name, $options)
	{
		$html = '<input name="' . $name . '"';
		
		if (!isset($options['id']))
			$html .= ' id="' . $name . '-field"';
		
		if (!isset($options['value']) && $this->_model)
			$html .= ' value="' .htmlspecialchars($this->_model->$name).'"';
		
		foreach ($options as $n => $v)
			$html .= ' ' . $n . '="' . $v . '"';
		
		return $html . ' />';
	}
	
	/**
	 * Creates the <code><input></code> hidden tag for the given field name. 
	 *
	 * The options serve as tag attributes. The default <code>name</code> attribute is set to the field name as well 
	 * as the <code>id</code> one. The <code>value</code> is set to the field name by default.
	 *
	 * @param string $name Field name
	 * @param array $options Formatting options
	 * @return string <code><input></code> hidden tag
	 */
	public function hidden_field($name, $options=array())
	{
		$options['type'] = 'hidden';
		return $this->valued_input($name, $options);
	}
	
	/**
	 * Creates the <code><input></code> text tag for the given field name.
	 * 
	 * The options serve as tag attributes. The default <code>name</code> attribute is set to the field name as well 
	 * as the <code>id</code> one. The <code>value</code> is set to the field name by default.
	 *
	 * @param string $name Field name
	 * @param array $options Formatting options
	 * @return string <code><input></code> text tag
	 */
	public function text_field($name, $options=array())
	{
		$options['type'] = 'text';
		return $this->valued_input($name, $options);
	}
	
	/**
	 * Creates the <code><input></code> password tag for the given field name. 
	 *
	 * The options serve as tag attributes. The default <code>name</code> attribute is set to the field name as well 
	 * as the <code>id</code> one. The <code>value</code> is set to the field name by default.
	 *
	 * @param string $name Field name
	 * @param array $options Formatting options
	 * @return string <code><input></code> password tag
	 */
	public function password_field($name, $options=array()) 
	{
		$options['type'] = 'password';
		return $this->valued_input($name, $options);
	}
	
	/**
	 * Creates the <code><input></code> submit button. 
	 * 
	 * The options serve as tag attributes. The <code>value</code> is set to the given parameter value.
	 *
	 * @param string $value Submit button value
	 * @param array $options Formatting options
	 * @return string <code><input></code> submit button
	 */
	public function submit($value, $options=array()) 
	{
		$html = '<input type="submit" value="' . $value . '"';
		
		foreach ($options as $n => $v)
			$html .= ' ' . $n . '="' . $v . '"';
		
		return $html . ' />';			 
	}
	
	/**
	 * Creates the <code><input></code> button tag. 
	 * 
	 * The options serve as tag attributes. The <code>value</code> is set to the given parameter value.
	 *
	 * @param string $value Button value
	 * @param array $options Formatting options
	 * @return string <code><input></code> button tag
	 */
	public function button($value, $options=array())
	{
		$html = '<input type="button" value="' . $value . '"';
		
		foreach ($options as $n => $v)
			$html .= ' ' . $n . '="' . $v . '"';
		
		return $html . ' />';
	}
	
	/**
	 * Creates the <code><input></code> image button tag. 
	 * 
	 * Options serve as tag attributes. The image file is resolved in the same way as in the 
	 * {@link image_tag()} function.
	 *
	 * @see image_tag
	 * @param string $file Button image file
	 * @param array $options Formatting options
	 * @return string <code><input></code> image button tag
	 */
	public function image($file, $options=array()) 
	{
		static $images_path;
		
		if (!isset($images_path))
			$images_path = \Application\Configuration::instance()->images_path;
		
		$html = '<input type="image" src="' . _asset_url($images_path, $file) . '"';
		
		foreach ($options as $n => $v)
			$html .= ' ' . $n . '="' . $v . '"';
		
		return $html . ' />';
	}
	
	/**
	 * Creates the <code><input></code> reset button tag. 
	 * 
	 * Options serve as tag attributes. The <code>value</code> is set to the given parameter value.
	 *
	 * @param string $value Button value
	 * @param array $options Formatting options
	 * @return string <code><input></code> reset button tag
	 */
	public function reset($value, $options=array())
	{
		$html = '<input type="reset" value="' . $value . '"';
		
		foreach ($options as $n => $v)
			$html .= ' ' . $n . '="' . $v . '"';
		
		return $html . ' />';			 
	}
}
?>