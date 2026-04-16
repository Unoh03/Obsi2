<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:import url="/ex27-header"/>
			<article id="article_sub">
				<h1>로그인</h1>
				<form id="f">	

					<fieldset class="fieldset_mem">
						<legend>로그인</legend>
						<div class="row">
							<label>아이디</label> <input type="text" name="id" id="id">
						</div>
						<div class="row">
							<label>패스워드</label> <input type="password" name="pw" id="pw">
						</div>		
					</fieldset>

					<div id="buttons_mem">
						<input type="button" class="submit_mem" value="로그인"
							onclick="member_check()"> <input type="reset"
							class="cancel_mem" value="취소">
					</div>
				</form>
			</article>
		</div>
	<c:import url="/ex27-footer"/>