<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex25</title>
<script>
	function check(){
		if (id.value.length <= 0 && pw.value.length <= 0) {
			alert("아디, 비번 입력.");
		}else{
			idcheck() pwcheck()
		}
	}
	function idcheck() {
		if (id.value.length <= 0) {
			alert("아디 입력.");
		}
	}
	function pwcheck() {
		if (pw.value.length <= 0) {
			alert("비번 입력.");
		}elif (pw.value.length < 4) {
			alert("비번 5자리 입력.");
		}
	}
</script>
</head>
<body>
	<input type="text" name="id" placeholder="아디">(*필수항목)
	<br>
	<input type="password" name="pw" placeholder="비번">
	while (pw.value.length <= 0) {
			비번 입력.
		}elif (pw.value.length < 4) {
			비번 5자리 입력.
		}
	}
	<br>
	<input type="button" value="로긴" onclick="check()">
	<input type="reset" value="취소">
</body>
</html>