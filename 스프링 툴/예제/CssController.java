package com.example.HtmlExample;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class CssController {
	@RequestMapping("ex01")
	public void ex01() {}
	@RequestMapping("ex02")
	public void ex02() {}
	@RequestMapping("ex03")
	public void ex03() {}
	@RequestMapping("ex04")
	public void ex04() {}
	@RequestMapping("ex05")
	public void ex05() {}
	@RequestMapping("ex06")
	public void ex06() {}
	@RequestMapping("ex07")
	public void ex07() {}
	@RequestMapping("ex08")
	public void ex08() {}
	@RequestMapping("ex09")
	public void ex09() {}
	@RequestMapping("ex10")
	public void ex10() {}
	@RequestMapping("ex11")
	public void ex11() {}
	@RequestMapping("ex12")
	public void ex12() {}
	@RequestMapping("ex13")
	public void ex13() {}
	@RequestMapping("ex14")
	public void ex14() {}
	@RequestMapping("ex15")
	public void ex15() {}
	@RequestMapping("ex16")
	public void ex16() {}
	@RequestMapping("ex17")
	public void ex17() {}
	@RequestMapping("ex18")
	public void ex18() {}
	@RequestMapping("quiz1")
	public void quiz1() {}
	@RequestMapping("quiz2")
	public void quiz2() {}
	@RequestMapping("quiz3")
	public void quiz3() {}
	@RequestMapping("quiz4")
	public void quiz4() {}
	@RequestMapping("quiz5")
	public void quiz5() {}
	@RequestMapping("quiz6")
	public void quiz6() {}
	@PostMapping("quiz7")
	public void quiz7Data
	(
		String id, String pw, String pwConfirm , String name, String y, String m, String d , String g, String country, String num, String verify
	)
	{
		System.out.println("아디: " + id);
		System.out.println("비번: " + pw);
		System.out.println("비번확인: " + pwConfirm);
		System.out.println("이름: " + name);
		System.out.println("년: " + y);
		System.out.println("월: " + m);
		System.out.println("일: " + d);
		System.out.println("성: " + g);
		System.out.println("지역 번호: " + country);
		System.out.println("전화 번호: " + num);
		System.out.println("인증번호 확인: " + verify);
	}
	@GetMapping("quiz7")
	public void quiz7View() {}
}