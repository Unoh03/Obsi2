package com.example.mvcExample;

public class MemberDTO {
	private String id;
    private String pw;
    private String username;
    private String postcode;
    private String address;
    private String detailaddress;
    private String mobile;
    

    /* 
        setter/getter 생성 단축기 : (이클립스에서) alt + shift + s -> Generate Getters And Setters
        setter : 변수에 값을 입력하는 기능을 가진 매서드
        getter : 변수에 값을 출력하는 기능을 가진 매서드
    */

	/*CREATE TABLE member(
			id varchar(20), pw varchar(200), username varchar(99),
			postcode varchar(5), address varchar(1000), detailaddress varchar(100),
			mobile varchar(15), PRIMARY KEY(id)
			) DEFAULT CHARSET=UTF8;
			*/
}
