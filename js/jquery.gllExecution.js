	$(document).ready(function(){	
	
		hideExecuteDumpFiles();
		$('#new_execution').click(function(e){	
			showMainPage();
			hideExecutePanel();
			hideExecuteDumpFiles();
			showExecuteGLLButton();
			hideTickets_main_page();
			
		});
		
		$('#dump_test').click(function(e){	
			showMainPage();
			hideExecutePanel();
			hideExecuteGLLButton();
			showExecuteDumpFiles();
			hideTickets_main_page();
			
		});
		
		$('#your_ticketsOnClick').click(function(){	
			hideMainPage();
			hideExecutePanel();
			hideExecuteGLLButton();
			hideExecuteDumpFiles();
			showTickets_main_page();
			updateYourTicketList();
			
		});
		
		
		
		$('#all_tickets').click(function(){	
			hideMainPage();
			hideExecutePanel();
			hideExecuteGLLButton();
			hideExecuteDumpFiles();
			showTickets_main_page();
			updateallTicketList();
			
		});
		
		$('#delete_all_files').click(function(){	
			delete_all_files();			
		});
		
		$('#logout').click(function(){	
			logout();			
		});
		
		
		$('#executegll').click(function(){	
			var timestamp = Date.now();
			hideMainPage();
			showExecutePanel();
			unziINPFiles(timestamp);
			
		});
		
		$('#executedump_test').click(function(){	
			var timestamp = Date.now();
			hideMainPage();
			showExecutePanel();
			unziINPFiles_dump(timestamp);
			
		});
		
		
  });
  
   function unziINPFiles(timestamp){
	  		$.ajax({
				async: true,
				url: 'actions/unzipINPFiles.php',
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').html("<b>TASK:</b> Unziping INP files");
						$('div#loader').show();
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> Unzip INP Files sucess!<BR>");
						executeinpUpload(timestamp);
				},
				success: function(data){
					printOutPut(data);
				}
				});
  }
  
  function executeinpUpload(timestamp){
	  		$.ajax({
				async: true,
				url: 'actions/uploadGLLFilesToDB.php?username=vanderson&nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Uploading INP files to databse");
						$('div#loader').show();
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> INP Files uploaded with sucess!<BR>");
						executexlsUpload(timestamp);
				},
				success: function(data){
						printOutPut(data);
					}
				});
  }
  
  function executexlsUpload(timestamp){
				$.ajax({
				async: true,
				url: 'actions/uploadXLSFilesToDB.php?username=vanderson&nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Uploading XLS files to databse");
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> XLS Files uploaded with sucess!<BR>");
						createTableResults(timestamp);
				},
				success: function(data){
					printOutPut(data);
				}
				});
}

function createTableResults(timestamp){
				$.ajax({
				async: true,
				url: 'actions/createResultstable.php?username=vanderson&nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Create table to save the results");
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> Table results to save the results created!<BR>");
						createScedule(timestamp)
				},
				success: function(data){
						printOutPut(data);
					}
				});
}

function createScedule(timestamp){
				$.ajax({
				async: true,
				url: 'actions/callProcedures.php?username=vanderson&nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Schedulling the new execution<BR>");
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> Execution schedulled!<BR>");
						$('div#executegllContent').append("<b>Your tickect:</b> "+ timestamp);
						$('div#tickets_main_page').html("Your ticket:" + timestamp);
						$('div#loader').hide(5000);
						 hideExecutePanel();
						 showMainPage();
						 location.reload();
				},
				success: function(data){
						$('div#executegllContent').append(data+"<br>");	
					}
				});
}

function updateYourTicketList(){
				$.ajax({
				async: true,
				url: 'actions/list_tickets.php?username=vanderson',
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#tickets_main_page').html("Retriving tickets list<BR>");
				},
				complete: function(data){	
						$('div#tickets_main_page').append("All tickects displayed");
				},
				success: function(data){
						$('div#tickets_main_page').append(data);
					}
				});
}

function updateallTicketList(){
				$.ajax({
				async: true,
				url: 'actions/list_all_tickets.php',
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#tickets_main_page').html("Retriving tickets list<BR>");
				},
				complete: function(data){	
						$('div#tickets_main_page').append("All tickects displayed");
				},
				success: function(data){
						$('div#tickets_main_page').append(data);
					}
				});
}

function viewTicket(timestamp){
				$.ajax({
				async: true,
				url: 'actions/viewTicket.php?ticket='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#tickets_main_page').html("Retriving tickets list<BR>");
				},
				complete: function(data){	
						$('div#tickets_main_page').append("Only 100 tickects displayed");
				},
				success: function(data){
						$('div#tickets_main_page').append(data);
					}
				});
}

function showExecutePanel(){		
			var executeGllButton = document.getElementById("executegllContent");
			executeGllButton.disabled = true; 
		
			var lTable = document.getElementById("executegllContent");
		    lTable.style.display="block";
			
}

function hideExecutePanel(){
			$("div#executegllContent").hide(3000);
}

function showMainPage(){
			var executeGllButton = document.getElementById("executegll");
			executeGllButton.disabled = false; 
			$("div#fileupload_div").show(3000);
			$("div#fileupload").show(3000);
}

function hideMainPage(){
			var executeGllButton = document.getElementById("executegll");
			executeGllButton.disabled = true; 

			$("div#fileupload_div").hide(1000);
			$("div#fileupload").hide(1000);
			
}

function hideExecuteGLLButton(){ 
			$('div#executegll_div').hide(1000); 
}

function showExecuteGLLButton(){
			$('div#executegll_div').show(1000);		
}

function showExecuteDumpFiles(){
			$('div#executedump_test').show(1000);		
}

function hideExecuteDumpFiles(){

			$('div#executedump_test').hide(1000);		
}

function hideTickets_main_page(){ 
			$('div#tickets_main_page_div').hide(1000); 
}

function showTickets_main_page(){
			$('div#tickets_main_page_div').show(3000);		
}

function downlodCSV(ticketNumber){
			window.location.href = 'actions/exportResults.php?ticket='+ticketNumber+'&type=csv';
  }
  function downlodXLS(ticketNumber){
			window.location.href = 'actions/exportResults.php?ticket='+ticketNumber+'&type=xls';
  }
  
    function deleteExecution(ticketNumber){
		if (confirm('Are you sure??')) {
			$.ajax({
				async: true,
				url: 'actions/delete_tickets.php?ticket='+ticketNumber,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body
			});
		} 

		 
		
		updateYourTicketList();
  }
  
  function delete_all_files(){
		if (confirm('Are you sure??')) {
			$.ajax({
				async: true,
				url: 'actions/delete_all_files.php',
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
			complete: function(data){	
				location.reload();
				}
			});
			
		} 
  }
  
  function logout(){
		if (confirm('Are you sure??')) {
			window.location.href="login/logout.php";
			
		} 
  }
// sleep time expects milliseconds
function sleep (milliseconds) {
   var start = new Date().getTime();
   while (new Date().getTime() < start + milliseconds);
}


//---- DUMP FileUpload



function unziINPFiles_dump(timestamp){
	  		$.ajax({
				async: true,
				url: 'actions/unzipINPFiles.php',
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').html("<b>TASK:</b> Unziping INP files");
						$('div#loader').show();
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> Unzip INP Files sucess!<BR>");
						executeinpUpload_dump(timestamp);
				},
				success: function(data){
					printOutPut(data);
					}
				});
  }
  
    function executeinpUpload_dump(timestamp){
	  		$.ajax({
				async: true,
				url: 'actions/uploadGLLFilesToDB.php?nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Uploading INP files to databse");
						$('div#loader').show();
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> INP Files uploaded with sucess!<BR>");
						executexlsUpload(timestamp);
				},
				success: function(data){
						printOutPut(data);
					}
				});
  }
  
    function executexlsUpload_dump(timestamp){
				$.ajax({
				async: true,
				url: 'actions/uploadXLSFilesToDB.php?nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Uploading XLS files to databse");
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> XLS Files uploaded with sucess!<BR>");
						createTableResults(timestamp);
				},
				success: function(data){
							printOutPut(data);
					}
				});
}

function createTableResults(timestamp){
				$.ajax({
				async: true,
				url: 'actions/createResultstable.php?username=vanderson&nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Create table to save the results");
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> Table results to save the results created!<BR>");
						createTableResults_dump(timestamp)
				},
				success: function(data){
					printOutPut(data);		
					}
				});
}

function createTableResults_dump(timestamp){
				$.ajax({
				async: true,
				url: 'actions_dump/createDumpResultstable.php?nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Create table to save DUMP the results");
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> Table results to save the DUMP results created!<BR>");
						uploadDUMPFiletoDB_dump(timestamp)
				},
				success: function(data){
						printOutPut(data);		
						}
				});
}


function uploadDUMPFiletoDB_dump(timestamp){
				$.ajax({
				async: true,
				url: 'actions_dump/uploadDUMPFiletoDB.php?nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Uploadig the DUMP Files");
				},
				complete: function(data){	
						$('div#executegllContent').append("<b>DONE:</b> Uploadig the DUMP Files DONE!<BR>");
						createScedule_dump(timestamp)
						$('div#loader').hide();
				},
				success: function(data){
						printOutPut(data);		
					}
				});			
}

function createScedule_dump(timestamp){
				$.ajax({
				async: true,
				url: 'actions_dump/callProceduresDUMP.php?nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Executing procedures, please wait<BR>");
				},
				complete: function(data){	
						
				},
				success: function(data){
						process_dump(timestamp);
						printOutPut(data);		
					}
				});
}

function process_dump(timestamp){
				$.ajax({
				async: true,
				url: 'actions_dump/processdump.php?nowtime='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#executegllContent').append("<b>TASK:</b> Executing the action dump comparation<BR>");
				},
				complete: function(data){	
					
				},
				success: function(data){
						printOutPut(data);	
						$('div#loader').hide();						
					}
				});
}

function viewTicketDUMP(timestamp){
				$.ajax({
				async: true,
				url: 'actions_dump/viewTicketDUMP.php?ticket='+timestamp,
				type:'GET',
				timeout: 500000,
				contentType: 'html',
				context: document.body,
				beforeSend: function(data){	
						$('div#tickets_main_page').html("Retriving tickets list<BR>");
				},
				complete: function(data){	
						$('div#tickets_main_page').append("Only 100 tickects displayed");
				},
				success: function(data){
						$('div#tickets_main_page').append(data);
					}
				});
}

function printOutPut(textStr){
	if(textStr.match("ERROR")){
		$('div#executegllContent').append("<h3><font color='red'>" +textStr+"</font></h3><br>");	
	}else{
		$('div#executegllContent').append("<h5><font color='blue'>" +textStr+"</font></h5><br>");	
	}
}