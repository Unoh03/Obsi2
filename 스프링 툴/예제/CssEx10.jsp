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
        /*left: 30px; top: 30px;*/
        background-color: cyan;
        width: 400px;
        height: 50px;
	}
    .pr1 {
        position: relative;
        left: 40px; top: 40px;
        background-color: orange;
        width: 400px;
        height: 50px;
        top: 40px;
    }
    .pr1 {
        position: relative;
      /*  left: 40px; top: 40px; */
        background-color: lightgreen;
        width: 400px;
        height: 50px;
        top: 40px;
    }
    </style>
</head>
<body>
    <h1>positioning style</h1>
    <p class="ps">정적 위치 설정 적용</p>
    <div class="pr1">상대 위치 설정 적용</div>
    <p class="pr2">상대 위치 설정 적용</p>
    정적 위치 : 순서에 따라 나열되는 바식. 위치 조정을 해도 적용되지 않는다.
    <br> 상대 위치 : 현재 블록을 기준으로 위치를 선정한다.
</body>
</html>