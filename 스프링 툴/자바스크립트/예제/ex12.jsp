<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex12</title>
</head>
<body>
	<script>
		function add(data1, data2, data3) {
			var total;
			if (data2 === undefined && data3 === undefined)
				total = data1;
			else if (data3 === undefined)
				total = data1 + data2;
			else
				total = data1 + data2 + data3;

			return total;
		}
		
		document.write(add(2) + "<br>");
		document.write(add(2, 3) + "<br>");
		document.write(add(2, 4, 6) + "<br>");
		document.write(add(2, 4, 6, 7) + "<br>");
	</script>
</body>
</html>

