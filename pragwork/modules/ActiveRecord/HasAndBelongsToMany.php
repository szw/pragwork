<?php
namespace ActiveRecord;
/**
 * @todo implement me
 * @package ActiveRecord
 * @see http://www.phpactiverecord.org/guides/associations
 */
class HasAndBelongsToMany extends AbstractRelationship
{
	public function __construct($options=array())
	{
		/* options =>
		 *   join_table - name of the join table if not in lexical order
		 *   foreign_key -
		 *   association_foreign_key - default is {assoc_class}_id
		 *   uniq - if true duplicate assoc objects will be ignored
		 *   validate
		 */
	}

	public function load(Model $model)
	{

	}
};
?>