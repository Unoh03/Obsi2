<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>WTF</title>
	<style type="text/css">
		table{margin: auto}
	</style>
</head>
<body>
	<form method="post" action="WTF">
	<table border="1"><!--9행, 3열-->
		<tr> <!--1행[다음 내용~|이미지{5행}]-->
			<td colspan="2">다음 <b>내용에 맞게 입력</b> 하시오.</td>
			<th rowspan="5"><img src="icon2.png" width="100%" /></th>
		</tr>
		<tr> <!--2행(전공 분야~,셀렉트)-->
			<td colspan="2">전공 입력<select name="M">
				<option value="sw">소프트웨어</option>
				<option value="sys">시스템</option>
				<option value="net">네트워크</option>
				<option value="db">데이터베이스</option>
			</select></td>
		</tr>
		<tr> <!--3행(이름|텍스트)-->
			<td>이름</td><td><input type="text" name="name"></td>
		</tr>
		<tr> <!--4행(아디|텍)-->
			<td>아디</td><td><input type="text" name="id"></td>
		</tr>
		<tr> <!--5행(비번|패스워드)-->
			<td>비번</td><td><input type="password" name="pw"></td>
		</tr>
		<tr> <!--6행(레전드(성별조사){3열},인풋 타입 라디오)-->
			<td colspan="3">
				<fieldset>
					<legend>성</legend>
					여자<input type="radio" name="G" value="W">
					남자<input type="radio" name="G" value="M">
				</fieldset>
			</td>
		</tr>
		<tr> <!--7행(레전드(취미 조사){3열},인풋 타입 체크박스)-->
			<td colspan="3">
				<fieldset>
					<legend>취미</legend>
					책 읽기<input type="checkbox" name="H" value="read">
					공부 하기<input type="checkbox" name="H" value="study">
					책 읽으며 공부하기<input type="checkbox" name="H" value="read&study">
					컴퓨터<input type="checkbox" name="H" value="computer">
					자기<input type="checkbox" name="H" value="sleep">
				</fieldset>
			</td>
		</tr>
		<tr> <!--8행(레전드(하고픈말){3열},텍.에)-->
			<td colspan="3">
				<fieldset>
					<legend>말</legend>
					<textarea rows="3" cols="50" name="word"></textarea>
				</fieldset>
			</td>
		</tr>
		<tr> <!--9행(완료(인풋 타입 서밋),다시 작성(인풋 타입 중 하나.))-->
			<td>
				<input type="submit" value="전송">
				<input type="reset" value="쓴거 엎어버리기">
			</td>
		</tr>
	</table>
	</form>
</body>
</html>