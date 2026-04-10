<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Form, Input</title>
</head>
<body>
	<!-- action 속성: 이 데이터를 어느 컨트롤러(URL)로 보낼지 목적지를 명시해야 한다. -->
	<form method="post" action="ex11"> <!--데이터 전송-->

<!--id, pw -> 매개변수(paremeter) 라고 부름-->

		<!-- name 속성: 서버(Java)에서 request.getParameter("userId")로 꺼내 쓸 수 있는 '변수명'이다. -->
		아디 <input type="text" name="id"><br>

		<!-- type="password": 화면에 입력할 때 까만 별표(***)로 마스킹 처리해 주는 UI 보안 기능 -->
		비번 <input type="password" name="pw"><br>

		<!-- checkbox: 여러 개 동시 선택 가능 (배열로 날아감) -->
		취미 선택<br>
		겜 <input type="checkbox" name="hobby" value="game"><br>
		코딩 <input type="checkbox" name="hobby" value="coding"><br>
		리눅스 <input type="checkbox" name="hobby" value="linux"><br>
		네트워크 <input type="checkbox" name="hobby" value="network"><br>
		
		<!-- radio: name을 똑같이 맞춰줘야 둘 중 하나만 선택되는 그룹핑이 성립된다. -->
		개인 정보 주세요<br>
		ㅇㅇ<input type="radio" name="injung" value="Y"><br>
		ㄴㄴ<input type="radio" name="injung" value="N"><br>
		
		<!-- file: 파일을 보낼 때는 form 태그에 반드시 enctype="multipart/form-data" 속성을 추가해야 서버가 파일을 인식한다. (나중에 배울 것) -->
		파일 <input type="file"><br>
		<input type="submit" value="전송">
	</form>
</body>
</html>