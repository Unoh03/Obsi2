<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>6</title>
    <style>
		.ps {
        position: static;
        background-color: cyan;
        width: 400px;
        height: 50px;
	}
    .pf {
        position: fixed;
        right: 40px; top: 40px;
        background-color: orange;
        width: 400px;
        height: 50px;
    }
    .pa {
        position: absolute;
        left: 50px; top: 10px;
        background-color: lightgreen;
        width: 400px;
        height: 50px;
    }
    </style>
</head>
<body>
    <h1>positioning style2</h1>
    <p class="ps">정적 위치 설정 적용</p>
    <div class="pf">고정 위치 설정 적용</div>
    <p class="pa">절대 위치 설정 적용</p>
    <p class="ps">정적 위치 설정 적용</p>
    <p class="ps">정적 위치 설정 적용</p>
    고정 위치 : 창의 스크롤을 움직여도 사라지지 않고 고정된 위치에 그대로 있음.<br>
    절대 위치 : 웹 문서의 흐름과 상관 없이 전체 페이지를 기준으로 배치
</body>
</html>