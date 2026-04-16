<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex17</title>
<script>
	function mouse_over(obj){
		 obj.innerHTML = "mouse_out";
	}
	function mouse_out(obj){
		obj.innerHTML = "mouse_over";
	}
</script>
</head>
<body>
    <div onmouseover="mouse_over(this)" onmouseout="mouse_out(this)">
		mouse Over
	</div>
</body>
</html>