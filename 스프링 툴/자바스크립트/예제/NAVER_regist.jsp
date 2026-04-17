<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="n" %>
<n:import url="/NAVER_header"/>
<body>
	<form method="post" action="NAVER_regist">
	<table id="content"><!--11행, 3열-->
		<caption>NAVER</caption> <!--맨 위 로고-->
		<tr> <!--1행(아디{플레이스 홀더 위치 조정 어케 함??})-->
    		
			<td colspan="3"><label>
				아이디<br>
    			<input type="text" name="id" onkeyup="idCheck()"></label> <span
				class="id_email">@naver.com</span> <br>
				<span id="idmsg"></span>
			</td>
		</tr>
		<tr> <!--2행(비번{텍스트})-->
			
			<td colspan="3"><label>
				비번<br>
    			<input type="password" name="pw" onkeyup="pwCheck()">
			</label></td>
		</tr>
		<tr> <!--3행(비번 재입력{텍스트. 비번 검토 기능은 못했는데 가능})-->
			
			<td colspan="3"><label>
				비번 재입<br>
    			<input type="password" name="pwConfirm" onkeyup="pwConfirm()">
			</label></td>
		</tr>
		<tr> <!--4행(이름{텍스트})-->
			
			<td colspan="3"><label>
				이름<br>
    			<input type="text" name="name" onkeyup="nameCheck()">
			</label></td>
		</tr>
		<tr id="birth"> <!--5행(생년월일{텍스트[플.홀],셀렉트,텍스트[플.홀]})-->
			
			<td class="year"><label>
			생년월일<br>
    			<input type="text" name="y" placeholder="년(4자)" onkeyup="yCheck()">
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
    			<input type="text" name="d" placeholder="일" onkeyup="dCheck()">
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
    			<input type="text" name="e" onkeyup="eCheck()">
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
			<input type="button" value="인증번호 받기" onclick="sendVerify()">
			</td>
			</tr>
			<tr>
			<td colspan="3">
				<input type="text" name="verify" placeholder="인증번호 입력하세요" onkeyup="verifyCheck()">
			</td>
			
		</tr>
		<tr> <!--11행(써밋버튼)-->
			<td colspan="3">
				<input type="submit" value="가입하기" onclick="ALERT()">
			</td>
		</tr>
	</table>
	</form>
</body>
</html>