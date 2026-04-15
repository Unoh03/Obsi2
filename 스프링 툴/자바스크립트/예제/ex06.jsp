<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex06</title>
</head>
<body>
	<script>
		
		
		
		/* if(100){
			result = "간당간당 합니다.";
		}
		if(-100){
			result = "미성년자 입니다"
		} 
		if(0){
			result = "성인 입니다.";
		} */
		// 0 == false
		// 0이 아닌 수는 모두 true
		var age = 9;
 		if (age == 19) {
			result = "간당간당 합니다.";
		} else if (age > 19) {
			result = "성인 입니다.";
		} else {
			result = "미성년자 입니다"
		}
	
		document.write("당신은 " + result + "<p/>");
	</script>
</body>
</html>