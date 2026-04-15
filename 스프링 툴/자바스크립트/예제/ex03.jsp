<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex03</title>
</head>
<body>
	<script>
		var x = 5, y = "5";
		document.write(typeof (x + y) + "<br>")
		document.write((x + y) + "<br>")
		
		// 비교 연산
		document.write(" x > y : " + (x > y) + "<br>");

		// 두 값이 같은지 비교
		document.write(" x == y : " + (x == y) + "<br>");

		// 두 값과 타입이 같은지 비교
		document.write(" x === y : " + (x === y) + " <br>");

		// 두 값이 다른지 비교
		document.write(" x != y : " + (x != y) + "<br>");

		// 두 값이 다르거나 또는 타입이 다른지 비교
		document.write(" x !== y : " + (x !== y) + "<br>");
	</script>
</body>
</html>