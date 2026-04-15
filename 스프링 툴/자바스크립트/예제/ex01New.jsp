<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Modern JS Refactoring</title>
</head>
<body>
    <!-- 🌟 1. 자바스크립트가 데이터를 꽂아 넣을 '빈 방(Target)'을 미리 만들어 둔다. -->
    <div id="outputBox"></div>

<script>
    // 🌟 2. var 대신 let 사용 (안전한 메모리 할당)
    let num; 
    let obj = null; 

    // 🌟 3. 강도님의 직감 적중: 백틱(`)으로 처음부터 끝까지 감싸버린다!
    // 엔터(줄바꿈)가 그대로 먹히기 때문에 코드가 미친 듯이 깔끔해진다.
    // 변수나 연산 결과는 \${ } 안에 꽂아 넣기만 하면 끝이다.
    const resultHtml = `
        100(숫자) : \${typeof 100} <br>
        10.5(숫자) : \${typeof 10.5} <br>
        "장운호"(문자) : \${typeof "장운호"} <br>
        '장운호'(문자) : \${typeof '장운호'} <br>
        true(논리형) : \${typeof true} <br>[1,2,3](객체) : \${typeof [1,2,3]} <br>
        {name:"장운호"}(객체) : \${typeof {name:'장운호', age:25}} <br>
        num(정의 되지 않았음) : \${typeof num} <br>
        obj=null(객체) : \${typeof obj} <br>
    `;

    // 🌟 4. document.write() 폐기 처분 및 모던 DOM 제어
    // 아까 만들어둔 '빈 방(outputBox)'을 찾아서, 그 안(innerHTML)에 백틱으로 만든 덩어리를 쑤셔 넣는다.
    document.getElementById('outputBox').innerHTML = resultHtml;

    // 콘솔 출력 (세미콜론 빼먹지 마라!)
    console.log('hello');
</script>
</body>
</html>