<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>6</title>
    <style>
        a:link { background-color: red; color: white; text-decoration: none;}
        a:visited { background-color: blue; color: white;}
        a:hover { text-decoration: underline; }
        a:active { background-color: yellow; color: white; }
	.back {
	
	}
	.ps {
    position: static;
    background-color: pink;
    width: 2000px;
    height: 500px;
    align-content: center;
	}
    .shell {
        position: relative;
    background-color: red;
    width: 200px;
    height: 100px;
        text-align: center;
        float: right;
    }
    </style>
</head>
<body>
    <div class="ps">
    <ul >
        <li class="shell"><a href="#">Home</a></li>
        <li class="shell"><a href="#">Profile</a></li>
        <li class="shell"><a href="#">Board</a></li>
        <li class="shell"><a href="#">Contact</a></li>
    </ul>
    </div>
</body>
</html>