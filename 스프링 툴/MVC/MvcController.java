package com.example.mvcExample;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class MvcController {
	@GetMapping("regist")
	public String regist() {
		return "member/regist";
	}
	
	@PostMapping("registProc")
	public String registProc(MemberDTO member, String confirm) {
		System.out.println("아디: " + member.getId());
		System.out.println("비번: " + member.getPw());
		System.out.println("비번확인: " + confirm);
		System.out.println("이름: " + member.getUserName());
		System.out.println("우편번호: " + member.getPostCode());
		System.out.println("주소: " + member.getAddress());
		System.out.println("상세주소: " + member.getDetailAddress());
		System.out.println("전번: " + member.getMobile());
		return "member/login";
	}


	/*
	 * 매핑 애너테이션
	 
	 * @PostMapping은 웹 클라이언트의 post 메서드의 요청을 받아서 JAVA의 메서드를 호출한다.
	 * post는 HTTP의 Body 영역에 데이터를 담아 전송하는 방식.
	 * 주로 데이터를 담아 전송할 때 사용함. ex) 파일, id와 pw와 같은 정보
	 	@PostMapping("loginProc")
		public String loginProc(BackDTO datas) {}
		
	 * @GetMapping은 웹 클라이언트의 get 메서드의 요청을 받아서 JAVA의 메서드를 호출한다.
	    @GetMapping("login")
		public String login() {
			return "member/login";
		}
		
	 * @RequestMapping은 모든 HTTP메서드의 요청을 받아서 JAVA의 메서드를 동작한다.
	 * 물론 method = RequestMethod.GET 와 같이 작성하면 지정한 HTTP 메서드의 매핑도 가능
	  	@RequestMapping(method = RequestMethod.GET, value="login")
		public String login() {
			return "";
		}
	 */
	/*
	 * 데이터 수신 
	 * 아래의 두 방식으로 클라이언트가 전달한 데이터를
	 * 서버에서 수신 받기 위한 방법이다.
	 * HTML 태그의 name 속성과 동일한 이름의 JAVA 변수를 구성해야함.
	 * 구성하는 방법은 두 가지
	 *  - 변수의 그룹과 같은 방식 
	 *  - 변수 모두 나열하는 방식 
	  
 		@PostMapping("registProc")
		public String registProc(BackDTO datas){
			bs.registProc(datas); 
			return "redirect:login";
		}
		
		@PostMapping("registProc")
		public String registProc(
			String id, String pw, 
			String confirm, String userName,
			String postcode, String address,
			String detailAddress, String mobile){
			bs.registProc(id, pw, confirm, userName,
			postcode, address, detailAddress, mobile); 
			return "redirect:login";
		}
	 */
	
	/*
	 * 서버 응답 방식
	 * redirect : 서버가 클라이언트에게 요청할 경로를 응답
	 * forward : 서버가 서버에게 요청할 경로를 응답
	 * view(jsp) 파일 경로 : 서버가 클라이언트에서 볼 화면의 코드를 제공
	 	@PostMapping("registProc")
		public String registProc(){
			return "redirect:login";
		}
		
		@GetMapping("login")
		public String login() {
			return "member/login";
		}
		
		@PostMapping("registProc")
		public String registProc(){
			return "forward:login";
		}
	 */


}
