<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex25</title>
<script>
	function check(){
		let idValue = document.getElementsByName('id')[0].value;
		let pwValue = document.getElementsByName('pw')[0].value;

		if (idValue.length <= 0 && pwValue.length <= 0) {
			alert("아디, 비번 입력.");
		}else{
			idcheck(); pwcheck();
		}
	}
	function idcheck() {
		if (idValue.length <= 0) {
			alert("아디 입력.");
		}
	}
	function pwcheck() {
		if (pwValue.length <= 0) {
			alert("비번 입력.");
		}else if (pwValue.length < 4) {
			alert("비번 5자리 입력.");
		}
	}
	function realTimepwCheck() {
    // 🚨 주의: name 속성으로 바로 접근(pw.value)하는 건 구식(Legacy) 브라우저의 잔재다.
    // 실무에서는 무조건 document.getElementsByName('pw')[0].value 를 쓰거나,
    // input 태그에 id="pw"를 주고 document.getElementById('pw').value 를 써야 안전하다.
    let pwValue = document.getElementsByName('pw')[0].value;
    
    
    if (pwValue.length <= 0) {
        document.getElementById('pwmsg').innerHTML = "비번 입력";
    } else if (pwValue.length < 4) {
        document.getElementById('pwmsg').innerHTML = "비번 5자리 이상 입력";
    } else {
        // 4자리 이상 정상 입력됐을 때 경고창을 지워주는 로직도 필요하다!
        document.getElementById('pwmsg').innerHTML = "✅ 안전한 비밀번호입니다.";
	}
}
</script>
</head>
<body>
	<form>
	<input type="text" name="id" placeholder="아디">(*필수항목)
	<br>
	<!-- onkeyup: 키보드를 눌렀다가 손가락을 떼는 그 0.1초의 순간마다 함수를 실행함 -->
	<input type="password" name="pw" placeholder="비번" onkeyup="realTimepwCheck()">
	<span id="pwmsg"></span>
	<br>
	<input type="button" value="로긴" onclick="check()">
	<input type="reset" value="취소">
	</form>
</body>
</html>