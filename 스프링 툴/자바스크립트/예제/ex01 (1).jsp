<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex01</title>
</head>
<body>
<script type="text/javascript">
   var num;        // 변수 값이 없음
   var obj = null;   // 객체 변수 값이 없음
   document.write('100(숫자) : ' + typeof 100 + "<br>");
   document.write('10.5(숫자) : ' + typeof 10.5 + "<br>");
   document.write("\"홍길동\"(문자) : " + typeof "홍길동"+ "<br>");
   document.write("'홍길동'(문자) : " + typeof '홍길동' + "<br>");
   document.write('true(논리형) : '+ typeof true + "<br>");
   document.write('[1,2,3](객체) : '+ typeof [1,2,3] + "<br>");
   document.write('{name:"홍길동"}(객체) : '+ typeof {name:'홍길동', age:25} + "<br>");
   document.write('num(정의 되지 않았음) : '+ typeof num + "<br>");
   document.write('obj=null(객체) : '+ typeof obj + "<br>");
   
   // 클라이언트(웹 브라우저) 개발자 도구(F12) 콘솔 탭에서 확인 가능.
   console.log('hello')
</script>
</body>
</html>





