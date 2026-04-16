<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex25</title>
<script>
	function check(){
		if (id.value.length <= 0 && PW.value.length <= 0) {
			alert("아디, 비번 입력.");
		}else{
			idcheck(); PWcheck();
		}
	}
	function idcheck() {
		if (id.value.length <= 0) {
			alert("아디 입력.");
		}
	}
	function PWcheck() {
		if (PW.value.length <= 0) {
			alert("비번 입력.");
		}else if (PW.value.length < 4) {
			alert("비번 5자리 입력.");
		}
	}
	if (PW.value.length <= 0) {
			document.getElementById('PWmsg').innerHTML = "비번 입력";
		}else if (PW.value.length < 4) {
			document.getElementById('PWmsg').innerHTML = "비번 5자리 입력";
		}
</script>
</head>
<body>
	<form>
	<input type="text" name="id" placeholder="아디">(*필수항목)
	<br>
	<input type="password" name="PW" placeholder="비번"><span id="PWmsg"></span>
	<br>
	<input type="button" value="로긴" onclick="check()">
	<input type="reset" value="취소">
	</form>
</body>
</html>