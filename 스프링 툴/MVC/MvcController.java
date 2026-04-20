package com.example.mvcExample;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class MvcController {
	@RequestMapping("/")
	public String root() {
		return "index";
	}
	@RequestMapping("index")
	public void index() {}
	@RequestMapping("header")
	public String header() {
		return "default/header";
	}
	@RequestMapping("main")
	public String main() {
		return "default/main";
	}
	@RequestMapping("footer")
	public String footer() {
		return "default/footer";
	}
	
	@GetMapping("delete")
	public String delete() {
		return "member/delete";
	}
	@GetMapping("memberinfo")
	public String memberinfo() {
		return "member/memberinfo";
	}
	@GetMapping("userinfo")
	public String userinfo() {
		return "member/userinfo";
	}
	
	@RequestMapping("login")
	public String login () {
		System.out.println("로그인 화면");
		return "member/login";
	}
	@GetMapping("regist")
	public String regist() {
		return "member/regist";
	}
	@Autowired MvcService service;
	
	@PostMapping("registProc")
	public String registProc(MemberDTO member, String confirm) {
		service.registProc(member, confirm);
		//return "forward:login"; 화면과 URL이 다름
		return "redirect:login"; //화면과 URL이 일치	
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
