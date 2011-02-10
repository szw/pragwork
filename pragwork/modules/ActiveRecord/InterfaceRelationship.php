<?php
namespace ActiveRecord;
/**
 * Interface for a table relationship.
 *
 * @package ActiveRecord
 */
interface InterfaceRelationship
{
	public function __construct($options=array());
	public function build_association(Model $model, $attributes=array());
	public function create_association(Model $model, $attributes=array());
}
?>