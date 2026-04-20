package com.example.mvcExample;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface IMvcMapper {
	public int registProc(MemberDTO member) ;

	public MemberDTO loginProc(String id);
}
