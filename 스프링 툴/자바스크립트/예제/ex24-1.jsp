<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex24-1</title>
<script>
	function myClick(){
		window.open('http://localhost/ex24-2', '_blank', 'width=600, height=600, top=400, left=400');
	}
</script>
</head>
<body>
	<input type="button" name="새창" onclick="myClick()">
</body>
</html>