Telnet은 구식 잊어라
대신 SSH 씀
# 명령어
 ⚙️ 라우터 기본 보안 설정

> [!info] 명령어 설명 (공부용)
> - `no ip domain-lookup`: 오타를 쳤을 때 라우터가 도메인 주소인 줄 알고 DNS 서버를 찾으며 렉 걸리는 현상(Translating...) 방지
> - `ena sec 123` : 관리자 모드 진입 비밀번호를 123으로 암호화하여 설정
> - `user asd sec 123` : 원격 접속 등에 쓸 로컬 계정(aaa) 생성
> - `logi loc` : 접속 시 방금 만든 로컬 계정 데이터베이스를 사용하겠다고 선언
> - `logg syn` : 명령어 치는 도중에 시스템 로그가 떠서 글자가 쪼개지는 현상 방지

**👇 아래 코드를 복사해서 라우터에 붙여넣으세요 (복붙용)**
```sh
en
conf t
no ip domain-lookup
ena sec 123
user asd sec 123
lin con 0
logi loc
logg syn

```
![[Pasted image 20260306091644.png]]

```bash
enable: 관리 모드
conf t: 전역 설정 모드
```
>[!tip]
>앞에 **do** 를 넣으면 모드 상관 없이 명령어 입력 가능.
단, 안쪽 모드에서 바깥 모드로만 적용 됨. 탭과 ? 못 씀

![[Pasted image 20260306091925.png]]
>[!warning]
>"#"에서 end하면 렉 먹음!

![[강의 자료/CH03_Device configuration v1.3.pdf#page=17]]
```bash
password 금지. secret 권장
비번 입력할떄 원래 안보임 당황 ㄴㄴ

'솔트' 라고하는 $과 $ 사이에 들어가는 문자가 있음.
```
![[Pasted image 20260306094925.png]]

![[Pasted image 20260306092243.png]]
![[Pasted image 20260306092414.png]]
![[Pasted image 20260306095039.png]]

# [[SSH]]

>[!warning]
>telnet 금지!

![[Pasted image 20260306102558.png]]
```bash
crypto key generate rsa # private key 생성
# [512]: size==복잡도. 가능 범위는 <중략>에 적혀있음
# SSH 1.99 : 버젼 1이나 2 사용. 1은 보안 취약점 있음
# line vty의 가짓수는 보통 0~4로 5개
'(config-line)#'transport intput ssh # SSH만 허용
'(config)#' ip ssh version 2 # 버젼 2 만 사용
```
![[Pasted image 20260306104451.png]]

## [[실습 문제 1]]

![[Pasted image 20260306130934.png]]
```bash
1. 못하면 바보
   en #관리모드
   conf t #전역 설정모드
   ena sec 123 #관리모드 비번 설정
   user aaa sec 123 #계정 생성
   lin con 0 #콘솔 접속, line 모드 진입
   logi loc #지금 접속한 계정으로 설정
   logg syn #로그 메시지 동기화
   exec-time 5 #접속 유지시간 5분 설정
   # 반대 라우터에도 동일하게
2. conf t
   int f0/0
   ip ad 1.1.1.2 255.255.255.0
   no sh
   
   int f0/1
   ip ad 12.12.12.1 255.255.255.0
   no sh
   # 반대 라우터 동일(ip 빼고)
3. #여기서 PC1에서 ping 2.2.2.1 하면 라우터1(1.1.1.2)에서 2.2.2.1을 몰라서 모른다고 응답 보냄(desti host unreach)
#PC1 에서 ping 12.12.12.2 하면 리퀘 탐 아웃. 이유는 까먹음
# 아직 1번 네트워크끼리, 2번 네트워크끼리, 라우터끼리만 통신 됨
5. # RSA(비대칭 키) 필요 상황
   conf t
   hostname '맘대로(라우터끼리 다르게)'
   ip domain-name '맘대로(둘이 같게)'
   cry k ge rsa
   2048 # 키 용량 설정. 보통 2048 많이 씀
   lin vty 0 4 
   logi loc
   transport input ssh
   logg syn
   exec-t 5
   exit
   ip ssh v 2
   
   #PC1에서
   ssh -l aaa 1.1.1.2
   #pc2에서
   ssh -l bbb 2.2.2.2
```

```bash
#하나의 네트워크가 있는 것처럼 하며 테스트를 하고싶을 땐 루프백 사용
conf t
int loopback 0
ip add 'ip 하고싶은거'
```

## [[실습 문제 2]]

![[Pasted image 20260306152834.png]]

```bash
# 라우터 기본 설정
en #관리모드
conf t #전역 설정모드
no ip domain-lookup #오타,잘못 입력했을때 도메인 서버에 번역,검색하느라 시간 낭비 안하게 함.
ena sec cisco #설정모드(맨 처음 enable) 들어갈 때 비번 설정
username cisco sec cisco #계정 생성
lin con 0 #콘솔과 연결
logi loc #지금 로그인 한 계정으로 앞으로 로그인 하겠다
exec-t 10 30 #10분 30초 타임아웃
logg syn #로그 동기화
username cisco sec cisco
lin vty 0 4
logi loc
exec-t 5
logg syn
exit #호스트네임 설정 위해 나감
hostname 

#인터페이스 설정
# 192.168.1.X/30의 사용 가능 IP는 192.168.1.X+1과 192.168.1.X+2로 2개
# X는 메인, X+3은 브로드캐스트. 하여 총 4개=2의 (32-30)제곱
# ip를 이진법으로 변환했을 떄, 메인IP의 Host-id가 0으로만 되어있어야한다.
en
conf t
int 포트
ip ad ㅑㅔ
no sh

sh ip route #경로 보여주는 명령어
```
# 라우팅
![[Pasted image 20260309112812.png]]
```bash

```
![[Pasted image 20260309105518.png]]
```bash
다이나믹 라우팅은 복잡할 떄, 스테틱은 단순할 때(특히 경로가 1자일 떄). 둘 중 하나 골라 사용 함.
데이터를 보내려면 상대 인터페이스의 정보를 알아야 함
```
>[!warning]
>스테틱 라우팅은 관리자가 잘 알고 있어야 트래픽이 느려지는 증 장애가 발생하지 않음.

![[Pasted image 20260309113404.png]]
![[Pasted image 20260309113752.png]]
![[Pasted image 20260309114050.png]]
```bash
| (파이프)는 or의 뜻을 가짐

```
![[Pasted image 20260309114401.png]]
```bash
3-2번은 현재는 해당되지 않음. 발전이 됨.
```
![[Pasted image 20260309114728.png]]
```bash
인터페이스 까지만 입력해도 잘 됨
보통은 ad와 in 중 in을 이미 자기꺼이고, 짧아서 더 자주 넣음 
Admin Distance: 우선순위.

```
![[Pasted image 20260309132006.png]]
```cisco
디폴트 라우팅: 테이블에 일치하는거 없으면 이거 씀
```
```bash
copy run start
# run=ram start=저장장치. 램의 정보를 스스디로 옮긴다.
!
cisco
cisco
en
cisco
cop r s
```
![[Pasted image 20260309162037.png]]
```bash

```