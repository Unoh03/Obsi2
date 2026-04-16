<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>quiz7</title>
<style>
body {
	background-color: #F6F6F6;
}

#content {
	margin: 0 auto;
	width: 450px;
	table-layout: fixed;
}

td, th {
	width: 100%;
}

th {
	text-align: left;
	padding-left: 10px;
}

caption {
	font-size: 40px;
	color: #1DDB16;
	font-weight: bold;
}

input {
	width: 90%;
	margin: 5px;
	height: 40px
}

.id_email {
	position: relative;
	top: -30px;
	left: 315px;
	color: gray
}

#birth td {
	all: initial;
}

#birth select {
	height: 45px;
	width: 130px;
}

#birth input {
	height: 38px;
	width: 130px;
	margin: 10px 0px 0px 0px;
}

#birth .year {
	margin-left: 5px;
}

#gender select {
	height: 45px;
	width: 410px;
	margin-left: 5px;
}

.choice {
	font-size: 14px;
}

#mobile {
	all: initial;
}

#mobile input, #mobile td {
	width: 300px;
}

#mobile button {
	width: 95px;
	height: 43px;
	background-color: #1DDB16;
	color: white;
	border: 1px gray;
	font-size: 12px;
}

.number {
	width: 410px;
	height: 38px;
	margin-left: 5px;
}

button[type="submit"] {
	width: 410px;
	height: 50px;
	background-color: #1DDB16;
	color: white;
	border: 1px gray;
	margin-left: 5px;
}
</style>
</head>
<body>
	<form method="post" action="quiz7">
	<table id="content"><!--11행, 3열-->
		<caption>NAVER</caption> <!--맨 위 로고-->
		<tr> <!--1행(아디{플레이스 홀더 위치 조정 어케 함??})-->
    		
			<td colspan="3"><label>
				아이디<br>
    			<input type="text" name="id"></label> <span
				class="id_email">@naver.com</span>
			</td>
		</tr>
		<tr> <!--2행(비번{텍스트})-->
			
			<td colspan="3"><label>
				비번<br>
    			<input type="password" name="pw">
			</label></td>
		</tr>
		<tr> <!--3행(비번 재입력{텍스트. 비번 검토 기능은 지금 못함})-->
			
			<td colspan="3"><label>
				비번 재입<br>
    			<input type="password" name="pwConfirm">
			</label></td>
		</tr>
		<tr> <!--4행(이름{텍스트})-->
			
			<td colspan="3"><label>
				이름<br>
    			<input type="text" name="name">
			</label></td>
		</tr>
		<tr id="birth"> <!--5행(생년월일{텍스트[플.홀],셀렉트,텍스트[플.홀]})-->
			
			<td class="year"><label>
			생년월일<br>
    			<input type="text" name="y" placeholder="년(4자)">
			</label><br>
			</td>
			<td><select name="m">
				<option value="1">1</option>
				<option value="2">2</option>
				<option value="3">3</option>
				<option value="4">4</option>
				<option value="5">5</option>
				<option value="6">6</option>
				<option value="7">7</option>
				<option value="8">8</option>
				<option value="9">9</option>
				<option value="10">10</option>
				<option value="11">11</option>
				<option value="12">12</option>
			</select></td>
			<td>
    			<input type="text" name="d" placeholder="일">
		</td>
		</tr>
		<tr  id="gender"> <!--6행(성별{셀렉트})-->
			
			<td colspan="3"><label>
			성별<br>
    			<select name="g">
				<option value="m">남</option>
				<option value="w">여</option>
			</select>
		</label>	
		</td>
			
		</tr>
		<tr> <!--7행(이메일{텍스트})-->
			
			<td colspan="3"><label>
			이메일<span class="choice">(선택)</span><br>
    			<input type="text" name="e">
			</label></td>
			
		</tr>
		<tr> <!--8,9,10행(셀렉트)(텍스트[플.홀], 버튼)(텍스트[플.홀])-->
			
			<td colspan="3" class="number"><label>
			휴대전화<br>
    			<select name="country">
				<option value="+82">대한민국 +82</option>
				<option value="+83">중국 +83</option>
				<option value="+84">일본 +84</option>
				<option value="+85">미국 +85</option>
			</select></label>
			</td>
			</tr>
			<tr id="mobile">
			<td colspan="2">
    			<input type="text" name="num" placeholder="전화번호 입력">
			</td>
			<td>	
			<input type="button" value="인증번호 받기">
			</td>
			</tr>
			<tr>
			<td colspan="3">
				<input type="text" name="verify" placeholder="인증번호 입력하세요">
			</td>
			
		</tr>
		<tr> <!--11행(써밋버튼)-->
			<td colspan="3">
				<input type="submit" value="가입하기">
			</td>
		</tr>
	</table>
	</form>
</body>
</html>