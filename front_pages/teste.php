<?php

include "../db/connect.php";
 $query = "SELECT * FROM gll_automation.teste";	
 echo $query;
 if(!mysqli_query($con, $query)){
  				die('fatal error'.mysql_error());
  	}ELSE{
		echo "SuCESOOO!!";
	} 
 
 
 
 
?>