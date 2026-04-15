<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ex15</title>
	<script type="text/javascript">
		function change(imgObj){
			console.log(imgObj);
			console.log(imgObj.src);

			if (imgObj.src == 'http://localhost/ok.png'){
				imgObj.src='delete.png';
			}else{
				imgObj.src='ok.png';
			}
		}
	</script>
</head>
<body>
	<!--이미지를 클릭하면 delete.png로 변경하기-->
	<img src="ok.png" id="imgObj" onclick="change(this)">
</body>
</html>