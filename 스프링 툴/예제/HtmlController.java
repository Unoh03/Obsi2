package com.example.HtmlExample;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class HtmlController {
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

	@RequestMapping("quiz1") 
	public void quiz1() {}

	@RequestMapping("quiz2") 
	public void quiz2() {}

	@RequestMapping("ex10") 
	public void ex10() {}
	@RequestMapping("ex11") 
	public void ex11(
		String id,
		String pw,
		String hobby,
		String injung
	) {
		System.out.println("아디: " + id);
		System.out.println("비번: " + pw);
		System.out.println("사전지식: " + hobby);
		System.out.println("개인정보 동의: " + injung);
	}
	
	
	@PostMapping("ex12")
	public void ex12Data
	(
	String data, String country
	)
	{
		System.out.println("게시글: " + data);
		System.out.println("국가: " + country);
	}
	@GetMapping("ex12")
	public void ex12View() {}

	@PostMapping("WTF")
	public void WTFData
	(
	String M, String name, String id, String pw, String G, String H, String word
	)
	{
		System.out.println("전공: " + M);
		System.out.println("이름: " + name);
		System.out.println("아디: " + id);
		System.out.println("비번: " + pw);
		System.out.println("성: " + G);
		System.out.println("취미: " + H);
		System.out.println("말: " + word);
	}
	@GetMapping("WTF")
	public void WTFView() {}
}