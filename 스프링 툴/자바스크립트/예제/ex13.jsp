<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex13</title>
	<script type="text/javascript">
		function input {
			var name1 = document.getElementById('name1');
			document.write('name.value : ' + name1.value);
			if(name1.length < 5){
				document.write('다섯 자리 미만은 너무함');
			}else{
				document.write('요구조건에 맞음')
			}
		}
	</script>
</head>
<body>
	name : <input type="text" id="name1" onchange="input()"> <br>
	name : <input type="text" id="name2"> <br>
</body>
</html>