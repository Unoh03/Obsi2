<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>quiz4</title>
<style>
* {
	box-sizing: border-box;
}

div#wrap {
	width: 500px;
	height: 500px;
	margin: 0 auto;
}
header {
	border: 1px solid pink; border-bottom: none; 
	height: 20%; text-align: center;
}
nav {
	float: left; width: 30%; height: 40%;
	border: 1px solid gold;	border-bottom: none;
}
section {
	height: 20%; width:70%;
	border: 1px solid red;
	border-bottom: none;
	float: left;

}

footer {
	clear: both;
	border-style: solid;
	height: 5%;
	border: 1px solid skyblue;
	text-align: center;
}

</style></head>
<body>
<div id="wrap">
	<header><h1>제 목</h1></header>
	<nav>
		<span>목차(nav)</span>
		<ul>
			<li><a href="#">Google</a></li>
			<li><a href="#">Apple</a></li>
			<li><a href="#">W3C</a></li> 
		</ul>
	</nav>
	<section>
		<span>section 1</span>
		<p>float 속성은 시맨틱 문서 구조에 유용하게 사용할 수 있습니다</p>
	</section>
	<section>
		<span>section 2</span>
		<p>float 속성은 시맨틱 문서 구조에 유용하게 사용할 수 있습니다.</p>
	</section>
	<footer><span> 마지막 글 </span></footer>
</div>
</body>
</html>