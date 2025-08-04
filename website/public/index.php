<?php
$pdo = new PDO('mysql:host=db;dbname=' . getenv('MYSQL_DATABASE'), getenv('MYSQL_USER'), getenv('MYSQL_PASSWORD'));
echo "<body style='background:black;color:white'><h1>Hello from PHP!</h1></body>";
?>
