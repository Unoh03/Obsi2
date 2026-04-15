<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>Table Layout Example</title>
  <style>
    /* 공통 스타일 */
    table {
      border-spacing: 5px;
      width: 100%;
      margin-bottom: 20px;
    }
    th, td {
      border: 1px solid #ccc;
      text-align: left;
      padding: 8px;
    }
    th {
      background-color: #f4f4f4;
    }

    /* auto 레이아웃 */
    .auto-table {
      table-layout: auto;
      caption-side: bottom;
    }

    /* fixed 레이아웃 */
    .fixed-table {
      table-layout: fixed;
      empty-cells: hide;
    }

  </style>
</head>
<body>
  
  <table class="auto-table">
  	<caption>테이블의 제목</caption>
    <thead>
      <tr>
        <th>Column 1</th>
        <th>Column 2</th>
        <th>Column 3</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>짧은 내용</td>
        <td>
        	이 열은 긴 내용이 포함되어 있습니다. 아주 긴 내용이 들어가게 됩니다.
        	이 열은 긴 내용이 포함되어 있습니다. 아주 긴 내용이 들어가게 됩니다.
        	이 열은 긴 내용이 포함되어 있습니다. 아주 긴 내용이 들어가게 됩니다.
        	이 열은 긴 내용이 포함되어 있습니다. 아주 긴 내용이 들어가게 됩니다.
        </td>
        <td>중간 길이의 내용</td>
      </tr>
      <tr>
        <td>짧은 내용</td>
        <td>긴 내용</td>
        <td>중간 길이의 내용</td>
      </tr>
    </tbody>
  </table>


  <table class="fixed-table">
  	<caption>빈 열이 존재하는 경우</caption>
    <thead>
      <tr>
        <th>Column 1</th>
        <th>Column 2</th>
        <th>Column 3</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>짧은 내용</td>
        <td>
        이 열은 긴 내용이 포함되어 있습니다. 아주 긴 내용이 들어가게 됩니다.
        이 열은 긴 내용이 포함되어 있습니다. 아주 긴 내용이 들어가게 됩니다.
        이 열은 긴 내용이 포함되어 있습니다. 아주 긴 내용이 들어가게 됩니다.
        이 열은 긴 내용이 포함되어 있습니다. 아주 긴 내용이 들어가게 됩니다.
        </td>
        <td>중간 길이의 내용</td>
      </tr>
      <tr>
        <td></td>
        <td>긴 내용</td>
        <td></td>
      </tr>
    </tbody>
  </table>
</body>
</html>



