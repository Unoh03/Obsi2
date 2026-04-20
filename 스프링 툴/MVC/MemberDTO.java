package com.example.mvcExample;

public class MemberDTO {
	private String id;
    private String pw;
    private String userName;
    private String postCode;
    private String address;
    private String detailAddress;
    private String mobile;
	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public String getPw() {
		return pw;
	}
	public void setPw(String pw) {
		this.pw = pw;
	}
	public String getUserName() {
		return userName;
	}
	public void setUserName(String userName) {
		this.userName = userName;
	}
	public String getPostCode() {
		return postCode;
	}
	public void setPostCode(String postCode) {
		this.postCode = postCode;
	}
	public String getAddress() {
		return address;
	}
	public void setAddress(String address) {
		this.address = address;
	}
	public String getDetailAddress() {
		return detailAddress;
	}
	public void setDetailAddress(String detailAddress) {
		this.detailAddress = detailAddress;
	}
	public String getMobile() {
		return mobile;
	}
	public void setMobile(String mobile) {
		this.mobile = mobile;
	}
    

    /* 
        setter/getter 생성 단축기 : (이클립스에서) alt + shift + s
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
