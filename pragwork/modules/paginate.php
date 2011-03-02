<?php
/**
 * Paginate Module 1.1 for Pragwork 1.1.0
 *
 * @copyright Copyright (c) 2009-2011 Szymon Wrozynski
 * @license Licensed under the MIT License
 * @version 1.1.0
 * @package Paginate
 */

/**
 * Splits the collection into smaller chunks and returns the chunk, its ordinal number (page) and the overall number 
 * of extracts (total pages).
 * 
 * <code>
 * list($people, $current_page, $total_pages) = paginate($all_people, 3, 10);
 * </code>
 * 
 * Creates the $people array containing 10 people max (if possible it would be records 20 to 29 of the 
 * <code>$all_people array</code>) along with the <code>$current_page</code> and <code>$total_pages</code> variables. 
 * The <code>$current_page</code> it is not always the same as the passed <code>$page</code> parameter. 
 * If the passed <code>$page</code> parameter was lower than 1 the <code>$current_page</code> is set to 1, 
 * and if the passed <code>$page</code> was greater than the greatest possible value, the <code>$current_page</code> 
 * is corrected accordingly. The <code>$total_pages</code> is computed according to the <code>$per_page</code> parameter
 * and the passed collection size.	 
 *
 * @param array $collection Collection to split
 * @param int $page Ordinal number of the extract to return
 * @param int $per_page Extract size
 * @return array Array of the extract, current page, and total pages count
 * @author Szymon Wrozynski
 */
function paginate($collection, $page, $per_page)
{
	if ($page < 1)
		$page = 1;
	
	$size = count($collection);
	$total_pages = ($size > $per_page) ? intval(ceil($size / $per_page)) : 1;
	
	if ($page > $total_pages)
		$page = $total_pages;
	
	$start = $per_page * ($page - 1);
	return array(array_slice($collection, $start, $per_page), $page, $total_pages);
}
?>