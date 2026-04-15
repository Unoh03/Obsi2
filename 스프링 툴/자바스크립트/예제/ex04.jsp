<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex04</title>
</head>
<body>
	<script>
/* 	
 	true && true  -> true
	
	true && false -> false
	false && true -> false
	
	false && false -> false
	------------------------------
	true || true  -> true
	
	true || false -> true
	false || true -> true
	
	false && false -> false 
*/
	
	var x = 5, y = 7;
	document.write("(x < 10 && y > 10) : " + (x < 10 && y > 10) + "<br>");
	document.write("(x < 10 || y > 10) : " + (x < 10 || y > 10) + "<br>");
	document.write("!(x < 10 && y > 10) : " + !(x < 10 && y > 10) + "<br>");

	// true or false ? true일때 실행할 문장 : false일 때 실행할 문장;
		
	result = (x > y) ? x : y; // 조건 연산
	document.write("큰 값 : " + result + "<br>");
	result = (x < y) ? x - y : y - x; // 조건 연산
	document.write("큰 값 - 작은 값 : " + result + "<br>");
	</script>
</body>
</html>