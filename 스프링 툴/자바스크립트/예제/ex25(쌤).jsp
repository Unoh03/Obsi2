<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex25</title>
<script>
	function checkId(){
		id = document.getElementById('id').value;
		pw = document.getElementById('pw').value;
		if(id == "" ){
			alert('아이디는 필수 사항입니다.');
			return ;
		}
		if(pw == "" ){
			alert('비밀번호는 필수 사항입니다.');
			return ;
		}
		
		document.getElementById('f').action = "ex25";
		document.getElementById('f').method = "post";
		document.getElementById('f').submit();
	}
	
	function checkPw(){
		pw = document.getElementById('pw');
		 if(pw.value == "" ){
			document.getElementById('msg').innerHTML = '비밀번호를 입력하세요.';
		}else if(pw.value.length < 5){
			document.getElementById('msg').innerHTML = '5자리 이상 입력하세요.';
		} else {
			document.getElementById('msg').innerHTML = '비밀번호를 잘 입력했습니다.';
		}
	}
</script>
</head>
<body>
	<form id="f">
		<input type="text" placeholder="아이디" id="id" name="id">
		<span>(*필수 항목)</span><br>
		<input type="password" placeholder="비밀번호" id="pw" name="pw" onkeyup="checkPw()">
		<span id="msg"></span><br>
	
		<input type="button" value="로그인" onclick="checkId()">
		<input type="reset" value="취소">
	</form>
</body>
</html>





