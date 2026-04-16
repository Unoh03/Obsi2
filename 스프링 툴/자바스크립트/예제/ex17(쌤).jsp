<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex17</title>
<script>
	function changeText(id){
		 id.innerHTML = "change text!";
		 id.style.color="lightblue";
	}
	function defaultText(){
		var h1_id = document.getElementById("h1_id");
		h1_id.innerHTML="Click on this text!";
		h1_id.style.color="black";
	}
</script>
</head>
<body>
    <h1 onclick="changeText(this)" 
   		onmouseover="defaultText()" 
    	id="h1_id">
   	 	Click on this text!
    </h1>
</body>
</html>







