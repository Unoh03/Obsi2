package com.example.mvcExample;

import java.util.ArrayList;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import jakarta.servlet.http.HttpSession;

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

	
	@GetMapping("regist") // 회원 가입 하면 제공
	public String regist() {
		return "member/regist";
	}
	
//	MvcService service = new MvcService();
	@Autowired MvcService service; // MvcService Class를 자동으로 실행해서 관리해
	
	@PostMapping("registProc") // 회원 정보 전달
	public String registProc(MemberDTO member, String confirm, RedirectAttributes ra) {
		String msg = service.registProc(member, confirm);
		ra.addFlashAttribute("msg", msg);
		if(msg.equals("회원 가입 성공")) {
			return "redirect:login";
		}else {
			return "redirect:regist";
		}
	}
	
	
	@GetMapping("login")
	public String login () {
		System.out.println("로그인 화면");
		return "member/login";
	}
	
	@PostMapping("loginProc")
	public String loginProc(MemberDTO member, HttpSession session, RedirectAttributes ra) {
	    // Service가 이제 MemberDTO를 반환 — null이면 실패
	    MemberDTO result = service.loginProc(member);
	    
	    if (result != null) {
	        // 세션 처리는 Controller가 담당
	        session.setAttribute("id", result.getId());
	        session.setAttribute("userName", result.getUserName());
	        System.out.println("로그인 성공: " + result.getId());
	        return "redirect:index"; // 성공 시 메인으로
	    } else {
	        // 실패 메시지를 다음 페이지로 전달
	        ra.addFlashAttribute("msg", "아이디/비밀번호가 일치하지 않습니다.");
	        return "redirect:login"; // 실패 시 로그인 페이지로
	    }
		/*
		 * 아이디/비밀번호를 전달받아 서비스 안에 메서드로 전달
		 * 서비스에서 입력 값 검증 후 디비로 전달
		 * 디비에서 결과를 받아 출력하기.
		 */
	}
	@PostMapping("logout") // logout은 링크 클릭으로 호출되니 Post가 자연스러움. Get은 보안 별로.
	public String logout(HttpSession session) {
		session.invalidate(); // 현재 사용자의 세션 전체 무효화
		return "redirect:index"; // 홈으로 리다이렉트
	}
	@RequestMapping("memberInfo")
	public String memberInfo(Model model) {
		// 클라 요청 받아 DB에 데이터 가져와 화면에 바로 제공
		ArrayList<MemberDTO> members = service.memberinfo();
		model.addAttribute("members", members);
		
		return "member/memberinfo";
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