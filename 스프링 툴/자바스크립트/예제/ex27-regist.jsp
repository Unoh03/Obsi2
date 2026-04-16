<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex27</title>
<style>
body {
	background-color: #898989;
	margin: 0;
	padding: 0;
}

#wrap {
	width: 950px;
	background: white;
	margin: 0 auto;
}

/* 공통 */
a {
	text-decoration: none;
	color: #333;
}

ul {
	list-style: none;
	padding: 0;
	margin: 0;
}

/* ===== header ===== */
header {
	height: 200px;
	position: relative;
}

#login {
	position: absolute;
	right: 20px;
	top: 10px;
}

#logo {
	padding: 50px 0 0 50px;
}

#logo a {
	color: #f90;
	font-size: 28px;
	font-weight: bold;
}

#header_nav {
	position: absolute;
	right: 50px;
	bottom: 20px;
}

#header_nav ul {
	display: flex;
	gap: 20px;
}

#header_nav a:hover {
	color: #f90;
}

/* ===== 상단 이미지 ===== */
#img_mem {
	background-image: url(/image/sub_back.png);
	height: 180px;
}

/* ===== 전체 레이아웃 ===== */
#content {
	display: flex;
}

/* ===== 좌측 메뉴 ===== */
#nav_sub {
	width: 200px;
	padding: 20px;
}

#nav_sub ul li a {
	display: block;
	padding: 8px;
	border-bottom: 1px dotted #999;
}

#nav_sub ul li a:hover {
	color: #f90;
}

/* ===== 본문 ===== */
#article_sub {
	flex: 1; /* 빈 공간 다 채우기 */
	padding: 20px;
}

#article_sub h1 {
	margin-bottom: 20px;
}

/* ===== fieldset ===== */
.fieldset_mem {
	margin-bottom: 20px;
	padding: 20px;
	border: 1px solid #ddd;
}

.fieldset_mem legend {
	font-size: 18px;
}

/* ===== form row  ===== */
.row {
	display: flex;
	align-items: center; /* 세로 정렬 */
	margin: 10px 0;
}

.row label {
	width: 150px;
	font-weight: bold;
}

.row input {
	width: 220px;
	height: 28px;
	padding: 3px;
	background-color: #D4F4FA;
	border: 1px solid #999;
}

#check_text {
	margin-left: 10px;
	font-size: 14px;
	color: red;
}

/* ===== 버튼 ===== */
#buttons_mem {
	display: flex; 
	justify-content: center; /* 가로 정렬 */
	gap: 20px; /* 대상의 간격 */
	margin: 30px 0;
}

.submit_mem, .cancel_mem {
	width: 250px;
	height: 45px;
	font-size: 16px;
	border: none;
	cursor: pointer;  /* 커서 손모양 */
}

.submit_mem {
	background: linear-gradient(#ffb37a, #ff6a00);
}

.cancel_mem {
	background: linear-gradient(#cfd9df, #91a3b0);
}

/* ===== footer ===== */
footer {
	border-top: 1px solid #ccc;
	margin-top: 30px;
	padding: 20px;
	display: flex;
	justify-content: space-between; /* 양쪽 끝 + 사이 균등 */
	font-size: 12px;
}
</style>
<script>
	function member_check() {
		id = document.getElementById('id').value;
		pw = document.getElementById('pw').value;
		confirm_pw = document.getElementById('confirm_pw').value;
		name = document.getElementById('name').value;

		if (id == "") {
			alert('아이디는 필수 항목입니다.');
		} else if (pw == "") {
			alert('비밀번호는 필수 항목입니다.');
		} else if (confirm_pw == "") {
			alert('비밀번호 확인은 필수 항목입니다.');
		} else if (name == "") {
			alert('이름은 필수 항목입니다.');
		} else {
			document.getElementById('f').action = 'member_check';
			document.getElementById('f').submit();
		}
	}
	function pw_check() {
		pw = document.getElementById('pw');
		confirm_pw = document.getElementById('confirm_pw');
		if (pw.value == confirm_pw.value) {
			document.getElementById('check_text').innerHTML = '일치';
		} else {
			document.getElementById('check_text').innerHTML = '불일치';
			pw.value = "";
			confirm_pw.value = "";
			confirm_pw.focus();
		}
	}
	function login_check() {
		id = document.getElementById('id').value;
		pw = document.getElementById('pw').value;

		if (id == "") {
			alert('아이디는 필수 항목입니다.');
		} else if (pw == "") {
			alert('비밀번호는 필수 항목입니다.');
		} else {
			document.getElementById('f').action = 'login_check';
			document.getElementById('f').method = 'post';
			document.getElementById('f').submit();
		}
	}
</script>
</head>
<body>
	<div id="wrap">
		<header>
			<div id="login">
				<a href="#"> Login </a> <a href="#"> Membership </a>
			</div>
			<div id="logo">
				<h1>
					<a href="#">CARE LAB</a>
				</h1>
			</div>
			<nav id="header_nav">
				<ul>
					<li><a href="#">HOME</a></li>
					<li><a href="#">COMPANY</a></li>
					<li><a href="#">SOLUTIONS</a></li>
					<li><a href="#">CUSTOMER CENTER</a></li>
				</ul>
			</nav>
		</header>
		<div id="img_mem"></div>
		<div id="content">
			<nav id="nav_sub">
				<ul>
					<li><a href="quiz3_register"> 회원 가입 </a></li>
					<li><a href="modify"> 회원 수정 </a></li>
					<li><a href="delete"> 회원 탈퇴 </a></li>
					<li><a href="quiz3_login"> 로그인 </a></li>
					<li><a href="logout"> 로그아웃 </a></li>
				</ul>
			</nav>

			<article id="article_sub">
				<h1>회원 가입</h1>
				<form id="f">

					<fieldset class="fieldset_mem">
						<legend>기본 정보</legend>
						<div class="row">
							<label>아이디</label> <input type="text" name="id" id="id">
						</div>
						<div class="row">
							<label>패스워드</label> <input type="password" name="pw" id="pw">
						</div>
						<div class="row">
							<label>패스워드 확인</label> <input type="password" name="confirm_pw"
								id="confirm_pw" onchange="pw_check()"> <span
								id="check_text"></span>
						</div>
						<div class="row">
							<label>이름</label> <input type="text" name="name" id="name">
						</div>
					</fieldset>

					<fieldset class="fieldset_mem">
						<legend>부가 정보</legend>

						<div class="row">
							<label>이메일</label> <input type="text" name="email" id="email">
						</div>

						<div class="row">
							<label>핸드폰</label> <input type="text" name="mobile" id="mobile">
						</div>

						<div class="row">
							<label>주소</label> <input type="text" name="address" id="address">
						</div>
					</fieldset>

					<div id="buttons_mem">
						<input type="button" class="submit_mem" value="회원 가입"
							onclick="member_check()"> <input type="reset"
							class="cancel_mem" value="취소">
					</div>
				</form>
			</article>
		</div>
		<footer>
			<hr>
			<div id="copy">
				<p>Copyright 2022 kyes Inc. all rights reserved contact mail :
					kyes0222@gmail.com Tel: +82 010-6315-6980</p>
			</div>

			<div id="social">
				<img src="/image/facebook.gif"> <img src="/image/twitter.gif">
			</div>
		</footer>
	</div>
	<!-- wrap end -->
</body>
</html>
