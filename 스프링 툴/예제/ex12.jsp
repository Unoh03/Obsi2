<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex12</title>
</head>
<body>
	<form method="post" action="ex13"> <!--데이터 전송-->
		<fieldset>
			<legend>input 태그 외</legend>
			개시글 작성<br>
			<textarea rows="3" cols="50" name="data"></textarea>
			<br>

			<select name="country">
				<option value="ko">대한민국</option>
				<option value="usa">미국</option>
				<option value="ch">중국</option>
			</select>
		</fieldset>
		<input type="submit" value="전송"/>
	</form>
</body>
</html>