<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex13</title>
	<script type="text/javascript">
		function inputDataPrint() {
			var name1 = document.getElementById('name1');
			var displayMSG = document.getElementById('displayMSG');
			displayMSG.innerHTML = '졸려';
            name1.value = "";
		}
	</script>
</head>
<body>
	name1 : <input type="text" id="name1" value="ㅎㅇ"> <br>
	<span id="displayMSG" > </span><br>
	<input type="button" value="버튼" onclick="inputDataPrint()">
</body>
</html>