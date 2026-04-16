<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex22</title>
<script>
	function myClick(){
		alert("안녕하세요.\n환영합니다");

		var result = confirm("처음?")

		if(result){
			document.getElementById("myclick").innerHTML = "ㅎㅇ"
		}else{
			document.getElementById("myclick").innerHTML = "ㅎㅇㅎㅇ"
		}
	}
</script>
</head>
<body>
	<input type="button" value="클릭" onclick="myClick()">
	<p id="myclick"></p>
</body>
</html>