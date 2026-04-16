<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex17 - 모던 JS 교정본</title>
<style>
    /* CSS는 style 태그나 외부 파일로 빼는 것이 정석입니다. */
    #h1_id {
        cursor: pointer; /* 클릭할 수 있다는 걸 사용자에게 알려줌 */
        transition: color 0.3s ease; /* 색상 변경 시 부드러운 애니메이션 효과 */
    }
</style>
</head>
<body>
    <!-- HTML은 순수하게 뼈대와 ID만 남깁니다. 인라인 이벤트(onclick 등) 싹 제거! -->
    <h1 id="h1_id">Click on this text!</h1>

    <!-- JS는 body의 맨 끝(요소들이 다 그려진 후)에 위치하는 것이 좋습니다. -->
    <script>
        // 1. DOM 요소 가져오기 (const 사용, 정확한 ID 매칭)
        const targetH1 = document.getElementById("h1_id");

        // 2. 클릭(click) 이벤트 리스너 등록
        targetH1.addEventListener("click", function() {
            // innerHTML 대신 textContent 사용
            targetH1.textContent = "change TEXT!";
            targetH1.style.color = "lightblue";
        });

        // 3. 마우스 오버(mouseover) 이벤트 리스너 등록
        targetH1.addEventListener("mouseover", function() {
            targetH1.textContent = "Click on this text!";
            targetH1.style.color = "black";
        });
    </script>
</body>
</html>