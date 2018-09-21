<!DOCTYPE html>
<html lang="en">

  <head>
  
	<link href="/favicon.ico" rel="shortcut icon">
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="issues found">
    <meta name="author" content="Marcelo Roland">
    <title>Issues found</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">
	<link href="//netdna.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/bootstrap-select/1.6.3/css/bootstrap-select.min.css" />
	<link rel="stylesheet" href="style.css">
  </head>
  <body>
  	<div class="container">
  		<div class="row" style="white-space:nowrap">
  			<div class="col-md-6 col-md-offset-3">
  				<h1 class="page-header text-center">Issues found</h1>
				<form class="form-horizontal" role="form" method="post" action="index.php">
						<?php
					include "../db/connect.php";	
					$query = "SELECT error_msg, filename FROM gll_automation.executions";
					if(!mysqli_query($con, $query)){
						die('fatal error'.mysqli_error());
					}else{
					} 
				
				$result = mysqli_query($con, $query);
				echo "Results from : $query</br>";
				echo "<table border='1'>"; //Criamos a tabela
				echo "<tr>" 	//Aqui criamos o cabeçalho da tabela.
						."<td>FileName</td>"
						."<td>Error Message</td>"
						."</tr>"; // 
				while($row = mysqli_fetch_array($result)) {
				 $filename   = $row['filename'];
				 $error_msg  = $row['error_msg'];
		echo "<tr><td>$filename"
				."<td>$error_msg</td>"
				."</tr>";
	}	
		echo "</table>"; // E fora do while fechamos a tabela.
				
				


    /* free result set */
    mysqli_free_result($result);

				
					?>		
				</form> 
			</div>
		</div>
	</div>   
	<form class="form-horizontal" role="form">
   
    
</form>
<div class="footer" >
<img src="images/ibm.png" alt="IBM" style="float:left;width:42px;height:18px;">
&copy; <a href="">Issues found	</a>
<i class="fa fa-circle-thin">Created by <a href="mailto:mroland@br.ibm.com"> </i>Marcelo</a> <i class="fa fa-circle-thin">at IBM </i>
</div>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
  <script src="//cdnjs.cloudflare.com/ajax/libs/bootstrap-select/1.6.3/js/bootstrap-select.min.js"></script>
  </body>
</html>