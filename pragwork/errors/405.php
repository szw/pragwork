<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<title>405 Method Not Allowed</title>
</head>
<body>
	<h1>Method Not Allowed</h1>
	<p>The requested method <?php echo $_SERVER['REQUEST_METHOD'] ?> is not allowed for the URL <?php echo $_SERVER['REQUEST_URI'] ?>.</p>
	<hr />
	<address>Pragwork 1.1.0 <?php echo $_SERVER['SERVER_SOFTWARE'] ?> Server at <?php echo $_SERVER['SERVER_NAME'] ?> Port <?php echo $_SERVER['SERVER_PORT'] ?></address>
</body>
</html>