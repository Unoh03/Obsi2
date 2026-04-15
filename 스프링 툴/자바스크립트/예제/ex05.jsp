<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex05</title>
</head>
<body>
	<script>
		var x1 = x2 = x3 = x4 = x5 = 10;
		var st = "Hello ";
		x1 += 1; // x1 = x1 + 1;
		document.write("x1 : " + x1 + "<br>");
		x2 -= 2;  // x2 = x2 - 2;
		document.write("x2 : " + x2 + "<br>");
		x3 *= 3;  // x3 = x3 * 3;
		document.write("x3 : " + x3 + "<br>");
		x4 /= 4;  // x4 = x4 / 4;
		document.write("x4 : " + x4 + "<br>");
		x5 %= 5;  // x5 = x5 % 5;
		document.write("x5 : " + x5 + "<br>");
		st += "Javascript"; //st = st + "Javascript";
		document.write("st : " + st + "<br>");
	</script>
</body>
</html>