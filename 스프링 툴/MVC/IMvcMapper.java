package com.example.mvcExample;

import java.util.ArrayList;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface IMvcMapper {
	public int registProc(MemberDTO member) ;

	public MemberDTO loginProc(String id);
	
	public ArrayList<MemberDTO> memberInfo();
}