package com.example.HtmlExample;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class JsController {
	@RequestMapping("ex01")
	public void ex01() {}
    @RequestMapping("ex02")
	public void ex02() {}
	
}
