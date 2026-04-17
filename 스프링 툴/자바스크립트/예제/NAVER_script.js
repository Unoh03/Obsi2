function idCheck() {
let idVal = document.getElementById('id').value;
const idRegex = /^[a-z0-9_-]{5,20}$/;
}
if (!idRegex.test(idVal)) {
	document.getElementById('idmsg').innerHTML = "5~20자의 영문 소문자, 숫자와 특수기호(_), (-)만 사용 가능합니다.";

} else {
	document.getElementById('idmsg').innerHTML = "✅ 적절한 아이디입니다";
}

function pwCheck() {
    let pwVal = document.getElementsByid('pw').value;
    const pwRegex = /^[a-zA-Z0-9`-=~!@#$%^&*()_+\|;:'"]{8,16}$/
    
    if () {
        document.getElementById('pwmsg').innerHTML = "8~16자 영문 대소문자, 숫자, 특수문자를 사용하세요.";
    } else {
        document.getElementById('pwmsg').innerHTML = "✅ 적절한 비밀번호입니다";
	}
}



function pwConfirm() {
	let pwVal = document.getElementById('pw').value;
	let pwCon = document.getElementById('pwCon').value
	if (pwCon != pwVal) {
		document.getElementById('pwConmsg').innerHTML = "비밀번호가 일치하지 않습니다.";
	} else {
		document.getElementById('pwConmsg').innerHTML = "✅비밀번호가 일치합니다.";
	}

}
function nameCheck() {
	let nameVal = document.getElementById('name').value
	const nameRegex = /^[가-힣a-zA-Z]+$/;

	if (!nameRegex.test(nameVal)) {
		document.getElementById('namemsg').innerHTML = "한글과 영문 대소문자를 사용하세요.(특수기호, 공백 사용 불가.)";
	}else{
		document.getElementById('namemsg').innerHTML = "✅";
	}
}
function yCheck() {
	let  = document.getElementById('y').value
	if () {
		document.getElementById('ymsg').innerHTML = "4자리 입력.";
	}else{
		document.getElementById('ymsg').innerHTML = "✅";
	}
}
function dCheck() {
	let  = document.getElementById('m').value
	let  = document.getElementById('d').value
	if () {
		document.getElementById('dmsg').innerHTML = "1~31 입력.";
	}else{
		document.getElementById('dmsg').innerHTML = "✅";
	}
}
function eCheck() {
	let  = document.getElementById('e').value
	if () {
		document.getElementById('emsg').innerHTML = "이메일 양식 틀림.";
	}else{
		document.getElementById('emsg').innerHTML = "✅";
	}
}
function sendVerify() {
	
}
function verifyCheck() {
	let  = document.getElementById('verify').value
	if () {
		document.getElementById('vmsg').innerHTML = "";
	}else{
		document.getElementById('vmsg').innerHTML = "✅";
	}
}

function ALERT() {
	
}