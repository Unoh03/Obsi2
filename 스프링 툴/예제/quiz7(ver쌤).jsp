<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>


<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>naver</title>

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
	<table id="content">
		<caption>NAVER</caption>
		<!-- 아이디 영역 -->
		<tr>
			<th>아이디</th>
		</tr>
		<tr>
			<td colspan="3"><input maxlength="15" type="text"> <span
				class="id_email">@naver.com</span></td>
		</tr>
		<tr>
			<td></td>
		</tr>

		<!--  비밀번호 영역 -->
		<tr>
			<th>비밀번호</th>
		</tr>
		<tr>
			<td colspan="3"><input type="password"></td>
		</tr>
		<tr>
			<td><br></td>
		</tr>



		<!--  이름 영역 -->
		<tr>
			<th>이름</th>
		</tr>
		<tr>
			<td colspan="3"><input type="text"></td>
		</tr>
		<tr>
			<td><br></td>
		</tr>

		<!--  생년월일 영역 -->
		<tr>
			<th>생년월일</th>
		</tr>

		<tr id="birth">
			<td class="year"><input type="text" placeholder="년(4자)">
			</td>
			<td><select>
					<option value="" selected="selected">월</option>
					<option value="01">1월</option>
					<option value="02">2월</option>
					<option value="03">3월</option>
					<option value="04">4월</option>
					<option value="05">5월</option>
					<option value="06">6월</option>
					<option value="07">7월</option>
					<option value="08">8월</option>
					<option value="09">9월</option>
					<option value="10">10월</option>
					<option value="11">11월</option>
					<option value="12">12월</option>
			</select></td>
			<td> <input type="text" placeholder="일"></td>
		</tr>

		<tr>
			<td><br></td>
		</tr>

		<!--  성별 영역 -->
		<tr>
			<th>성별</th>
		</tr>
		<tr id="gender">
			<td colspan="3"><select>
					<option value="" selected="selected">성별</option>
					<option value="남자">남자</option>
					<option value="여자">여자</option>
					<option value="선택안함">선택안함</option>
			</select></td>
		</tr>
		<tr>
			<td><br></td>
		</tr>

		<!--  본인 확인 이메일 영역 -->
		<tr>
			<th>본인 확인 이메일<span class="choice">(선택)</span></th>
		</tr>
		<tr>
			<td colspan="3"><input type="text"></td>
		</tr>
		<tr>
			<td><br></td>
		</tr>

		<!--  휴대전화 영역 -->
		<tr>
			<th>휴대전화</th>
		</tr>
		<tr>
			<td><select class="number">
					<option value="82" selected="selected">대한민국 +82</option>
					<option value="83">중국 +83</option>
					<option value="84">일본 +84</option>
					<option value="85">미국 +85</option>
			</select></td>
		</tr>

		<tr id="mobile">
			<td colspan="2"><input type="text" placeholder="전화번호 입력"></td>
			<td colspan="1"><button type="button">인증번호 받기</button></td>
		</tr>
		<tr>
			<td colspan="3"><input type="text" placeholder="인증번호 입력하세요"></td>
		</tr>
		<tr>
			<td><br></td>
		</tr>
		<tr>
			<td><button type="submit">가입하기</button></td>
		</tr>
	</table>
</body>
</html>
