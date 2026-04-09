<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex06</title>
		<!--권장-->
		<meta charset="UTF-8">
		<title>ex06</title>
		<style type="text/css">
			div {
				text-align: center;
			}
			.header { background-color: #F3FF48; height: 100px;}
			.header { background-color: orange; height: 200px;}
			#footer { background-color: skyblue; height: 300px;}
		</style>
</head>

<body>

	<!-- 권장하지 않는 방법 -->
	<div style="background: #53FF4C; height: 100px" align="center">
		<br>header<br> 사전 / 뉴스 / 증권 / 영화 / 뮤직
	</div>
	<div style="background: orange; height: 200px" align="center">
		<br>center<br> 컨텐츠가 들어갈 영역 <br>환영합니다.
	</div>
	<div style="background: skyblue; height: 100px" align="center">
		<br>footer<br>바닥글 들어갈 영역<br> 회사소개 | 인재채용 | 제휴제안 | 이용약관
	</div>
	
	<!--권장-->
	<div class="header">
		<br>header<br> 사전 / 뉴스 / 증권 / 영화 / 뮤직
	</div>
	<div class="center">
		<br>center<br> 컨텐츠가 들어갈 영역 <br>환영합니다.
	</div>
	<div id="footer">
		<br>footer<br>바닥글 들어갈 영역<br> 회사소개 | 인재채용 | 제휴제안 | 이용약관
	</div>


</body>
</html>
