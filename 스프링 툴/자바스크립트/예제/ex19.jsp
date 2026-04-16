<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex19</title>
<script>
	function mouse_down(obj){
		 obj.innerHTML = "좌클 누름";
	}
	function mouse_up(obj){
		obj.innerHTML = "좌클 뗌";
	}
</script>
</head>
<body>
    <div onmousedown="mouse_down(this)" onmouseup="mouse_up(this)">
		좌클 ㄱㄱ
	</div>
</body>
</html>