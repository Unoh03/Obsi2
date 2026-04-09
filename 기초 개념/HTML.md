## 🕸️ [Code Review] Spring Controller와 HTML 기초 아키텍처

### 1. Spring Boot 설정 및 Controller (마법의 `void`)

**[application.properties]**
```properties
spring.application.name=htmlExample
server.port=80

# ViewResolver 세팅: 컨트롤러가 던진 이름 앞뒤에 살을 붙여서 파일 경로를 완성함
spring.mvc.view.prefix=/front/
spring.mvc.view.suffix=.jsp
```

**[HtmlController.java]**
> [!danger] 🚨 아키텍트의 팩트 폭격: "리턴(return) 값이 없는데 화면이 어떻게 뜨지?"
> 어제는 `return "index";` 라고 명시했지만, 오늘은 리턴 타입이 **`void`**다. 
> **스프링의 마법:** 컨트롤러가 `void`를 반환하면, 스프링은 **"아, 리턴값이 없네? 그럼 네가 들어온 요청 주소(`@RequestMapping`)를 그대로 파일 이름으로 쓸게!"** 라고 자동 추론(RequestToViewNameTranslator)한다.
> 즉, `localhost/ex01`로 들어오면 자동으로 `/front/ex01.jsp`를 찾아간다.

```java
package com.example.htmlExample;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller // 스프링 대문지기(DispatcherServlet)에게 이 클래스가 길잡이임을 알림
public class HtmlController {
	
	@RequestMapping("ex06")
	public void ex06() {} // 리턴이 없으므로 요청 주소인 "ex06"이 뷰 이름이 됨 -> /front/ex06.jsp
	
	@RequestMapping("ex05")
	public void ex05() {}
	
	// ... (ex04 ~ ex01 동일)
}
```

---

### 2. HTML 기초 태그 해부 (ex01 ~ ex04)

**[ex01.jsp: 식별자와 줄바꿈]**
```html
<body>
	<!-- <br>은 Line Break. 닫는 태그가 없는 예외적인 녀석이다. -->
	아무 문자열 <br> 작성하면 <br> 화면에 출력 <br>함.
	
	<!-- id는 문서 내 유일한 고유키(PK), class는 그룹명(Security Group) -->
	<div id="div1">division tag 1</div>
	<div class="div2">division tag 2</div>
	<div>division tag 3</div>
</body>
```

**[ex02.jsp: 제목 태그의 한계]**
```html
<body>
	<!-- h1~h6: 숫자가 커질수록 글씨는 작아진다. (SEO 및 검색 엔진이 문서 구조를 파악하는 핵심 태그) -->
	<h1>글씨 크기 제일 크다.</h1>
	<h6>글씨 크기 제일 작다.</h6>

	<!-- 🚨 아키텍트의 팩트 폭격: h7, h8은 웹 표준에 존재하지 않는 쓰레기 태그다. -->
	<!-- 브라우저는 모르는 태그를 만나면 에러를 뱉지 않고, 그냥 일반 텍스트(<span>)처럼 렌더링해버린다. -->
	<h7>글씨 크기 h7 이후부터는 없는 태크</h7>
</body>
```

**[ex03.jsp: 텍스트 포맷팅 (Legacy)]**
```html
<body>
	<!-- 이 태그들은 시각적 효과만 줄 뿐, 현대 웹에서는 CSS로 처리하는 것을 권장한다. -->
	<i>기울임 글꼴 (Italic)</i> <br>
	<b>굵은 글꼴 (Bold)</b> <br>
	<u>밑줄친 글꼴 (Underline)</u> <br>
	<s>취소선 (Strike-through)</s> <br>
</body>
```

**[ex04.jsp: 문단 태그와 악성 페이로드]**
```html
<body>
<!-- <p> (Paragraph) 태그는 하나의 독립된 문단을 만든다. 위아래로 자동으로 여백(Margin)이 생긴다. -->
<p>
주요 내용 및 팁: ...
</p>

<!-- 🚨 [보안 경고] 출처를 알 수 없는 호날두의 자격지심 텍스트 인젝션 발생. -->
<!-- 실무에서 사용자가 이런 장문의 텍스트를 입력할 때, 중간에 <script> 태그가 섞여 있는지 반드시 검증(Sanitizing)해야 한다. -->[Web발신] 너는 나를 존중해야 한다... (생략)
</body>
```

---

### 3. 🚨 치명적 버그가 숨어있는 ex05, ex06

**[ex05.jsp: 피싱(Phishing)의 기초]**
```html
<body>
	<!-- ul (Unordered List): 순서가 없는 점(Bullet) 리스트 -->
	<ul>
		<!-- 🚨 [보안 경고] 전형적인 피싱(Phishing) 공격 벡터다. -->
		<!-- 사용자의 눈에는 '구글'이라고 보이지만, 실제 클릭하면 'naver.com'으로 날아간다. -->
		<!-- 해커들이 가짜 은행 사이트 링크를 걸 때 쓰는 가장 기초적인 수법이다. -->
		<li> <a href="https://www.naver.com"> 구글 </a> </li>
	</ul>
	
	<!-- ol (Ordered List): 1, 2, 3... 순서가 있는 숫자 리스트 -->
	<ol>
		<li> <a href="ex05"> ex05 (상대 경로: 현재 주소 뒤에 ex05를 붙임) </a> </li>
	</ol>
</body>
```

**[ex06.jsp: CSS 덮어쓰기(Cascading)와 구조 붕괴]**
>[!danger] 🚨 아키텍트의 팩트 폭격: "이 코드는 HTML 뼈대가 박살 났고, CSS는 스스로를 파괴하고 있다."

```html
<head>
<meta charset="UTF-8">
<title>ex06</title>
</head> <!-- 🚨 여기서 머리(head)가 닫혔는데... -->

<!-- 🚨 머리가 닫힌 뒤에 또 meta, title, style이 나온다! 완벽한 구조 붕괴(Syntax Error)다. -->
<!-- 브라우저가 억지로 고쳐서 렌더링해주긴 하지만, 실무에선 절대 용납 안 되는 스파게티 코드다. -->
		<meta charset="UTF-8">
		<title>ex06</title>
		<style type="text/css">
			div { text-align: center; }
			
			/* 🚨 CSS의 절대 법칙: Cascading (폭포수) */
			/* 똑같은 .header 클래스에 대해 색상과 높이를 두 번 정의했다. */
			/* 컴퓨터 공학의 진리: "마지막에 읽힌 놈이 승리한다." */
			/* 결과적으로 #F3FF48(노란색)은 무시되고, orange(주황색) 200px이 최종 적용된다. */
			.header { background-color: #F3FF48; height: 100px;}
			.header { background-color: orange; height: 200px;}
			
			#footer { background-color: skyblue; height: 300px;}
		</style>
<body>
	<!-- 권장하는 방법 (Internal CSS 적용) -->
	<div class="header">
		<br>header<br> 사전 / 뉴스 / 증권 / 영화 / 뮤직
	</div>
	
	<!-- 🚨 치명적 버그: class="center" 라고 줬지만, 위쪽 <style> 블록에 .center 에 대한 정의가 아예 없다! -->
	<!-- 결과: 배경색도 없고 높이도 없는 투명한 깡통 div가 출력된다. -->
	<div class="center">
		<br>center<br> 컨텐츠가 들어갈 영역 <br>환영합니다.
	</div>
</body>
```
## 🖼️ [Architecture] 2. `ex07.jsp` 해부: 이미지 태그와 반응형 웹의 기초

> [!danger] 🚨 아키텍트의 팩트 폭격: "이미지 태그는 프론트엔드의 꽃이지만, 해커들에게는 가장 사랑받는 백도어(Backdoor)다."

```html
<body>
	<!-- 1. 절대 크기 (Absolute Sizing) -->
	<img src="icon1.png" width="100px"/>
	
	<h2>이미지 </h2>
	
	<!-- 2. 상대 크기 (Relative Sizing) -->
	<img src="icon2.png" width="25%" />
</body>
```

### 🔍 아키텍처 포인트 1: `px` vs `%` (반응형 웹의 시작)
- **`width="100px"` (절대 크기):** 모니터가 100인치든, 스마트폰 화면이든 무조건 가로 100픽셀의 크기로 고정(Hardcoding)한다.
- **`width="25%"` (상대 크기):** 브라우저 창 크기의 **25%**만큼만 차지하라는 뜻이다. 사용자가 브라우저 창을 줄이면 이미지도 같이 작아진다. 이것이 모바일과 PC를 동시에 지원하는 **'반응형 웹(Responsive Web)'** 아키텍처의 가장 기초적인 원리다.

### 🔍 아키텍처 포인트 2: `src` 속성의 경로 (Path)
- `src="icon1.png"`는 **상대 경로**다. 즉, 이 `ex07.jsp` 파일이 있는 폴더와 **정확히 똑같은 위치**에 `icon1.png` 파일이 있어야만 엑스박스(404)가 뜨지 않는다.
- 나중에 스프링(Spring) 실무로 가면, 이미지는 무조건 `/resources/static/` 같은 정적(Static) 폴더에 몰아넣고 절대 경로(`/images/icon1.png`)로 호출하는 아키텍처를 쓰게 된다.

### 💀 DevSecOps의 시선: `<img>` 태그의 보안 취약점
- **XSS (크로스 사이트 스크립팅):** 만약 저 `src` 경로를 사용자가 직접 입력할 수 있는 게시판이라면? 해커는 `<img src="x" onerror="alert('해킹')">`을 주입하여 악성 스크립트를 실행시킨다.
- **SSRF (서버 측 요청 위조):** 해커가 `src="http://127.0.0.1/admin"` 처럼 서버 내부망을 찌르는 주소를 넣으면, 톰캣 서버가 이미지를 가져오려고 내부망을 스스로 공격하는 대참사가 발생한다.
## 시간표
![[Pasted image 20260409144215.png]]
```html
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>시간표</title>
</head>
<body>
	<table border=1> <!--8행, 9열-->
		<tr> <!--1행-->
			<th colspan="10"><b>2026년 04월 IT 시간표</b></th>
		</tr>
		<tr> <!--2행-->
			<th colspan="2"></th>
			<th><b>401호</b></th>
			<th colspan="2"><b>402호</b></th>
			<th colspan="2"><b>403호</b></th>
			<th colspan="2"><b>404호</b></th>
		</tr>
		<tr> <!--3행-->
			<th colspan="2", rowspan="2"><b>09:00~12:00</b></th>
			<th rowspan="6"><b>공<br>사<br>중</b></th>
			<td colspan="2" rowspan="2">PYTHON 기초</td>
			<td colspan="2" rowspan="4">네트워크 보안<br>실무자 양성</td>
			<td colspan="2" rowspan="2">보충훈련 과정<br>(OS/네트워크)</td>
		</tr>
		<tr> <!--4행-->

		</tr>
		<tr> <!--5행-->
			<th colspan="2", rowspan="2"><b>12:30~15:30</b></th>
			<td colspan="2">JAVA</td>
			<td colspan="2">보충훈련 과정<br>(언어계열)</td>
		</tr>
		<tr> <!--6행-->
			
		</tr>
		<tr> <!--7행-->
			<th colspan="2"><b>15:30~18:30</b></th>
			<td colspan="2">C언어</td>
			<td colspan="2", rowspan="2">가상화 시스템<br>엔지니어 실무자 양성</td>
			<td colspan="2">리눅스</td>
		</tr>
		<tr> <!--8행-->
			<th colspan="2"><b>19:00~22:00</b></th>
			<td colspan="2">PYTHON_WEB</td>
			<td colspan="2">서버</td>
		</tr>
	</table>
</body>
</html>
```
>[! warning] **🚨 버그: 속성(Attribute) 사이의 콤마(`,`) 사용**
>- **강도님의 이전 코드:** `<th colspan="2", rowspan="2">09:00~12:00</th>`
>- **팩트 폭격:** HTML 태그 안에서 속성과 속성 사이에는 **절대 콤마(`,`)를 쓰지 않는다.** 오직 **'띄어쓰기(Space)'**로만 구분해야 한다.
>- 브라우저 엔진이 워낙 똑똑해서 콤마를 무시하고 렌더링해 줬겠지만, 엄격한 파서(Parser)를 만나면 에러를 뱉고 표가 박살 난다.
>- **✅ 패치:** `<th colspan="2" rowspan="2">09:00~12:00</th>` (콤마 삭제!)