function idCheck() {
	var id = document.getElementById("id").value;
	var msg = document.getElementById('id_msg');
	msg.innerHTML = " ";
	
	if (id == "") {
		msg.innerHTML = "필수 정보입니다.";
		return;
	}

	var isId = /^[a-z0-9][a-z0-9_-]{4,19}$/;
	if ( (isId.test(id)) == false ) {
		msg.innerHTML = "5~20자의 영문 소문자, 숫자와 특수기호(_),(-)만 사용 가능합니다.";
		return;
	}

}
function pwCheck() {
	var pw = document.getElementById("pw").value;
	var msg1 = document.getElementById('pw_msg1');
	var msg2 = document.getElementById('pw_msg2');

	if (pw == "") {
		msg1.innerHTML = "사용불가";
		msg2.innerHTML = "필수 정보입니다.";
		return;
	}

	var isPW = /^[A-Za-z0-9`\-=\\\[\];',\./~!@#\$%\^&\*\(\)_\+|\{\}:"<>\?]{8,16}$/;
	if (!isPW.test(pw)) {
		msg1.innerHTML = "사용불가";
		msg2.innerHTML = "8~16자 영문 대 소문자, 숫자, 특수문자를 사용하세요.";
		return;
	}

	msg1.style.color = "green";
	msg1.style.display = "block";
	msg1.style.left = "380px";
	msg1.innerHTML = "안전";
	msg2.innerHTML = "";
}

function confirmCheck() {
	var pw = document.getElementById("pw").value;
	var confirmPw = document.getElementById("confirmPw").value;
	var msg = document.getElementById('co_msg');
	msg.style.color = "red";
	msg.style.fontSize = "11px";
	msg.style.position = "relative";
	msg.style.left = "10px";
	if (confirmPw == "") {
		msg.innerHTML = "필수 정보입니다.";
		return;
	}

	if (pw != confirmPw) {
		msg.innerHTML = "비밀번호가 일치하지 않습니다.";
		return;
	}
	msg.innerHTML = "";
}

function nameCheck() {
	var name = document.getElementById("name").value;
	var msg = document.getElementById('name_msg');
	msg.style.color = "red";
	msg.style.fontSize = "11px";
	msg.style.position = "relative";
	msg.style.left = "10px";
	if (name == "") {
		msg.innerHTML = "필수 정보입니다.";
		return;
	}

	var nonchar = /[^가-힣a-zA-Z0-9]/gi;
	if (nonchar.test(name)) {
		msg.innerHTML = "한글과 영문 대 소문자를 사용하세요. (특수기호, 공백 사용 불가)";
		return;
	}
	msg.innerHTML = "";
}

function birth() {
	var year = document.getElementById("year").value;
	var month = document.getElementById("month").value;
	var day = document.getElementById("day").value;

	var birth_msg = document.getElementById('birth_msg');
	birth_msg.style.color = "red";
	birth_msg.style.fontSize = "11px";
	birth_msg.style.position = "relative";
	birth_msg.style.left = "10px";
	birth_msg.innerHTML = "";

	if (year == "" && month == "" && day == "") {
		birth_msg.innerHTML = "태어난 년도 4자리를 정확하게 입력하세요.";
		return;
	}

	if (year == "") {
		birth_msg.innerHTML = "태어난 년도 4자리를 정확하게 입력하세요.";
		return;
	}

	if (year.length != 4) {
		birth_msg.innerHTML = "태어난 년도 4자리를 정확하게 입력하세요.";
		return;
	}
	if (day.length == 1) {
		day = "0" + day;
	}
	if (month.length == 1) {
		month = "0" + month;
	}

	if (month == "") {
		birth_msg.innerHTML = "태어난 월을 선택하세요.";
		return;
	}
	if (day == "") {
		birth_msg.innerHTML = "태어난 일(날짜) 2자리를 정확하게 입력하세요.";
		return;
	}

	if (day.length != 2) {
		birth_msg.innerHTML = "태어난 일(날짜) 2자리를 정확하게 입력하세요.";
		return;
	}

	birthday = year + month + day;
	if (birthday.length != 8) {
		birth_msg.innerHTML = "생년월일을 다시 확인해주세요.";
		return;
	}

	if (month < 1 || month > 12) {
		birth_msg.innerHTML = "생년월일을 다시 확인해주세요.";
		return;
	}

	var maxDaysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
	var maxDay = maxDaysInMonth[month - 1];
	if (month == 2 && (year % 4 == 0 && year % 100 != 0 || year % 400 == 0)) {
		maxDay = 29;
	}

	if (day <= 0 || day > maxDay) {
		birth_msg.innerHTML = "생년월일을 다시 확인해주세요.";
		return;
	}
	birth_msg.innerHTML = "";

	var age = calcAge(birthday);
	if (age < 0) {
		birth_msg.innerHTML = "미래에서 오셨군요. ^^";
		return;
	} else if (age >= 100) {
		birth_msg.innerHTML = "정말이세요?";
		return;
	} else if (age < 14) {
		birth_msg.innerHTML = "만 14세 미만의 어린이는 보호자 동의가 필요합니다.";
		return;
	}
}

function calcAge(birth) {
	var date = new Date();
	var year = date.getFullYear();
	var month = (date.getMonth() + 1);
	var day = date.getDate();
	if (month < 10)
		month = '0' + month;
	if (day < 10)
		day = '0' + day;
	var monthDay = month + '' + day;

	birth = birth.replace('-', '').replace('-', '');
	var birthdayy = birth.substr(0, 4);
	var birthdaymd = birth.substr(4, 4);

	var age = monthDay < birthdaymd ? year - birthdayy - 1 : year - birthdayy;
	return age;
}

