<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex08</title>
</head>
<body>
	<script>
		/*
			var i = 0;
			for(초기식; 조건식 증감식) {
				반복적으로 수행할 문장;
				반복적으로 수행할 문장;
			}
		*/
		var x, y;
		for (x = 2; x <= 5; x++) {
			document.write("<b> ---[" + x + "단]--- </b>" + "<br>");
			for (y = 1; y <= 9; y++) {
				document.write(x + " * " + y + " = " + (x * y) + "<br>");
			}
		}
		
	</script>
</body>
</html>