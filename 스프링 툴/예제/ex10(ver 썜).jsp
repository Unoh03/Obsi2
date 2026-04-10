<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>ex10</title>
</head>
<body>
<!-- 
http://localhost/ex11?id=admin&pw=123123 
id or pw -> 매개변수(Parameter)
-->
<form method="get" action="ex11">  <!-- 데이터 전송 -->
	아이디 <input type="text" name="id"><br>
	비밀번호 <input type="password" name="pw"><br>
	사전지식 <br>
	네트워크 <input type="checkbox" name="background" value="network"> 
	리눅스 <input type="checkbox" name="background" value="linux"><br>
	개인정보 동의할거야?<br>
	네 <input type="radio" name="agree" value="yes"> <br> 
	아니오 <input type="radio" name="agree" value="no"><br>
	파일 <input type="file"><br>
	<input type="submit" value="전송">
</form>
</body>
</html>
















