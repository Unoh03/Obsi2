<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>6</title>
    <style>
        <!--가상 클래스-->
        a:link { color: pink; text-decoration: none; }
        a:visited { color: blue; }
        a:hover { text-decoration: overline; color: black; }
        a:active { background-color: yellow; }
    </style>
</head>
<body>
    <h2>Pseudo Class</h2>
    <p>
        <a href="ex05" target="_blink">test</a> : 마우스 이벤트에 따른 링크의 변화
    </p>
    <p>
        <a href="ex08" target="_blink">test</a> : 마우스 이벤트에 따른 링크의 변화
    </p>
    <hr>
        link : 웹 문서에서 사용자가 방문하지 않았던 곳을 표시한다. 
    <br>
        visited : 웹 문서에서 사용자가 방문한 곳을 표시한다. 
    <br>
        hover : 웹 문서에서 사용자가 링크에 마우스 포인터를 올리는 순간 나타난다.
    <br>
        active : 웹 문서에서 사용자가 링크를 클릭하는 순간 나타난다.
    <br>
</body>
</html>