<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex16</title>
<script>
	function textstyle() {
		var msg = document.getElementById("msg");
		msg.style.color = "blue";
		msg.style.fontSize = "30px";
		msg.style.fontStyle = "italic";
	}
	function texthidden() {
		document.getElementById("msg").style.visibility = "hidden";
	}
	function textvisible() {
		document.getElementById("msg").style.visibility = "visible";
	}
</script></head>
<body>
	<p id="msg">문서 객체 스타일 변경하기</p>
	<input type="button" onclick="textstyle()" value="텍스트 스타일 변경">
	<input type="button" onclick="texthidden()" value="텍스트 숨기기">
	<input type="button" onclick="textvisible()" value="텍스트 보이기">
</body>
</html>