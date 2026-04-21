package com.example.mvcExample;

import java.util.ArrayList;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import jakarta.servlet.http.HttpSession;

@Service
public class MvcService {
	@Autowired IMvcMapper mapper;
	
	public String registProc(MemberDTO member, String confirm) {
		String msg = "";
		if(member.getId() == null || member.getId().isEmpty()) {
			msg = "아이디를 입력하세요.";
		}else if(member.getPw() == null || member.getPw().isEmpty()) {
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
	public MemberDTO loginProc(MemberDTO member) {
	    // == "" 대신 isEmpty()로 수정 — null 체크도 함께
	    if (member.getId() == null || member.getId().isEmpty()) {
	        return null; // 실패 시 null 반환
	    }
	    if (member.getPw() == null || member.getPw().isEmpty()) {
	        return null;
	    }
	    
	    // DB에서 해당 id의 회원 정보 조회
	    MemberDTO result = mapper.loginProc(member.getId());
	    
	    // result가 null이면(DB에 없는 id) 또는 비밀번호 불일치면 null 반환
	    if (result != null && result.getPw().equals(member.getPw())) {
	        return result; // 성공 시 DB에서 꺼낸 MemberDTO 반환
	    }
	    return null;
	}
	public ArrayList<MemberDTO> memberinfo() {
		ArrayList<MemberDTO> members = mapper.memberInfo();
		return members;
	}
	public String userInfo(String id, Model model, RedirectAttributes ra, HttpSession session) {
		String sessionId = (String) session.getAttribute("id");
		String msg = "";
		if(sessionId == null || sessionId.isEmpty()) {
			msg = "로긴 먼저";
		}else if(sessionId.equals(id) == false) {
			msg = "염탐 ㄴㄴ";
		}else {
			MemberDTO member = mapper.loginProc(id);
			model.addAttribute("member", member);
			msg = "회원 검색 완료";
		}
		ra.addFlashAttribute("msg",msg);
		return msg;	
	}
	
	public String updateProc(MemberDTO member, String confirm, String id) {
		
	    if(member.getPw() == null || member.getPw().isEmpty())
	        return "비밀번호를 입력하세요.";
	    if(!member.getPw().equals(confirm))
	        return "비밀번호가 일치하지 않습니다.";
	    if(member.getUserName() == null || member.getUserName().isEmpty())
	        return "이름 입력.";
	    if(member.getAddress() == null || member.getAddress().isEmpty())
	        return "주소 입력.";
	    if(member.getDetailAddress() == null || member.getDetailAddress().isEmpty())
	        return "상세주소 입력.";
	    if(member.getMobile() == null || member.getMobile().isEmpty())
	        return "전번 입력.";
	    
	    member.setId(id);
	    mapper.updateProc(member);
	    return "수정 완료";
	}
	
	public String deleteProc(MemberDTO member, String confirm, String id) {
		String msg = "";
	
		if(member.getPw() == null || member.getPw().isEmpty()) {
			msg = "비번 넣어.";
		} 
		if(member.getPw().equals(confirm) == false) {
			msg = "비번 틀림.";
		}
		// 데이터베이스의 비밀번호와 사용자가 입력한 비밀번호가 일치하면 삭제
		String id = (String)session.getAttribute("id");
		MemberDTO member = mapper.loginProc(id);
		if(member.getPw().equals(pw)) {
			mapper.deleteProc(id);
			return "회원 정보 삭제 완료";
		}
		return "비밀번호가 틀렸습니다.";
	}
	public MemberDTO getUserById(String id) {
		// TODO Auto-generated method stub
		return mapper.loginProc(id);
	}
}