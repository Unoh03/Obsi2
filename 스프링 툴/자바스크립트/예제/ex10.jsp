<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>ex10</title>
	<script>
	
		
/* 		function 함수이름(함수가 전달받은 값을 저장할 변수, 변수 )
		{
			함수의 기능
			return "함수가 데이터를 반환할 때 입력하는 곳, 값은 1개";
		} */
		function printMsg() {
			document.write('함수 호출 메시지 : <br>');
		}
		function printMsg2(msg, data1, data2) {
			document.write('함수 호출 메시지 : '+ msg +'<br>');
			var total = data1 + data2;
			document.write('연산 결과 : '+ total +'<br>');
		}
		function printMsg3( data1, data2) {
			var total = data1 + data2;
			return total;
		}
	</script>
</head>
<body>
	<script>
		printMsg(); // 함수 호출
		printMsg2('전달 데이터', 1, 2); // 함수 호출
		var total = printMsg3(1, 2); // 함수 호출
		document.write('결과 : '+ total +'<br>');
	</script>
</body>
</html>