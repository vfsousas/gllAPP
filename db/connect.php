<?php
$host="localhost";
$user="gll_user";
$password="gllDTV2017";
$con=mysqli_connect($host,$user,$password);
if(!$con) {
	die( '<h1>MySQL Server is not connected</h1>');
}
?>