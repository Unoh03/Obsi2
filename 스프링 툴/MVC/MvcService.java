package com.example.mvcExample;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class MvcService {
	@Autowired IMvcMapper mapper;
	
	public String registProc(MemberDTO member, String confirm) {
		String msg = "";
		if(member.getId() == "") {
			msg = "아이디를 입력하세요.";
		}else if(member.getPw() == "" ) {
			msg = "비밀번호를 입력하세요.";
		}else if(member.getPw().equals(confirm) == false) {
			msg = "입력한 비밀번호를 일치하여 입력하세요.";
		} else {
			int result = mapper.registProc(member);
			System.out.println("결과: " + result);
			msg = "회원 가입 성공"; 
		}
		return msg;
		
		// 데이터 검증, 암호화, 복호화, 보안에 관련된 검증, 외부 서버와 통신(카카오, 구글, 네이버 로그인) 
//		System.out.println("비밀번호: " + member.getPw());
//		System.out.println("비번확인: " + confirm);
//		System.out.println("아이디: " + member.getId());
//		System.out.println("이름: " + member.getUserName());
//		System.out.println("우편번호: " + member.getPostCode());
//		System.out.println("주소: " + member.getAddress());
//		System.out.println("상세주소: " + member.getDetailAddress());
//		System.out.println("전화번호: " + member.getMobile());
	}

	public String loginProc(MemberDTO member) {
		MemberDTO result;
		String msg;
		if(member.getId() == "") {
			msg = "아이디를 입력하세요.";
		}else if(member.getPw() == "" ) {
			msg = "비밀번호를 입력하세요.";
		}else {
			result = mapper.loginProc(member.getId());
			if(result != null && result.getPw().equals(member.getPw()) == true) {
				System.out.println("아이디: " + result.getId());
				System.out.println("비밀번호: " + result.getPw());
				System.out.println("이름: " + result.getUserName());
				System.out.println("우편번호: " + result.getPostCode());
				System.out.println("주소: " + result.getAddress());
				System.out.println("상세주소: " + result.getDetailAddress());
				System.out.println("전화번호: " + result.getMobile());
				msg = "로그인 성공";
			}else {
				msg = "아이디/비밀번호가 일치하지 않는다.";
			}
		}
		return msg;
	}
}












