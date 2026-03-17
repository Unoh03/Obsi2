https://naver.me/xJcUWCvo
>[!info] 개인 규칙
>**1. 코드는 관리 모드(최초 상태에서 enable)'#'에서 입력하는 것을 전제로 둔다.
>2. IP 혼동을 막기 위해, 호스트 ID는 장비의 번호와 일치 | 연관지어 짓는다.
>   예) 3번 라우터: 23.23.23.<mark style="background: #FFF3A3A6;">3</mark>, 192.168.3.3 | R3과 연결된 PC3: 192.168.3.<mark style="background: #FFF3A3A6;">4</mark> (겹치니 +1)**
# 🧬 라우터의 유전자 지도: `show running-config` 완벽 해부
> [!info] sh r | sec '원하는거' 하면 검색해서 그 부분이 포함 된 거만 출력한다

> [!info] `show run`의 읽기 규칙 (Top-Down)
> 라우터의 설정 파일은 아무렇게나 섞여 있는 것이 아니다. 
> **[기본/보안 설정] ➡️ [인터페이스(포트) 설정] ➡️[라우팅(길 찾기) 설정] ➡️ [ACL/기타 설정] ➡️[접속 포트(Line) 설정]** 이라는 아주 엄격하고 논리적인 순서로 출력된다.

## 💻 `show run` 실전 예시 및 해설

```sh
Router# show run
Building configuration...

# 1.[시스템 기본 정보] 라우터의 OS 버전과 이름
Current configuration : 1234 bytes
version 15.1
no service pad
service timestamps debug datetime msec
service timestamps log datetime msec
# 평문 비밀번호들을 암호화해 주는 기능 (보안)
service password-encryption
# 라우터의 이름
hostname R1

# 2. [보안 및 전역 설정] 계정과 114 전화번호부
# 오타 쳤을 때 DNS 서버 찾는 렉 방지 (강도님이 뼈저리게 겪은 그것!)
no ip domain-lookup
# 관리자 모드(enable) 진입용 암호화된 비밀번호
enable secret 5 $1$mERr$hx5rVt7rPNoS4wqbXKX7m0
# 원격 접속(SSH 등)에 사용할 로컬 계정과 비밀번호
username admin secret 5 $1$mERr$hx5rVt7rPNoS4wqbXKX7m0

# 3. [인터페이스 설정] 라우터의 팔다리 (포트)
# 첫 번째 기가비트 포트 설정 시작
interface GigabitEthernet0/0
 # 포트에 부여된 IP 주소와 서브넷 마스크
 ip address 192.168.1.1 255.255.255.0
 # (내일 배울 NAT 예습) 이 포트는 사내망(Inside)이다!
 ip nat inside
 # 포트가 켜져 있음 (shutdown 글자가 없으면 켜진 것)
 duplex auto
 speed auto
# 두 번째 기가비트 포트 설정 시작
interface GigabitEthernet0/1
 ip address 12.12.12.1 255.255.255.0
 ! (내일 배울 NAT 예습) 이 포트는 외부 인터넷(Outside)이다!
 ip nat outside

! 4.[동적 라우팅 설정] 라우터의 자동 내비게이션
! RIP 라우팅 프로토콜이 돌아가고 있음
router rip
 ! 버전 2 사용
 version 2
 ! 내 몸에 붙은 네트워크를 이웃에게 소문냄
 network 12.0.0.0
 network 192.168.1.0
 ! 내 맘대로 서브넷 뭉뚱그리는 멍청한 짓 금지
 no auto-summary

! 5. [정적 라우팅 설정] 관리자가 수동으로 뚫어준 길
! 모르는 주소는 전부 12.12.12.2로 던져라 (디폴트 라우팅)
ip route 0.0.0.0 0.0.0.0 12.12.12.2

! 6. [ACL 방화벽 설정] 클럽 문지기 명단
! 192.168.1.100 PC만 허용하고 나머지는 암묵적 거부(Implicit Deny)로 다 죽임
access-list 1 permit 192.168.1.100

! 7. [Line 접속 설정] 라우터에 접속하는 통로 제어
! 콘솔 케이블(하늘색 선) 직접 연결 설정
line con 0
 ! 명령어 치다 로그 떠서 글자 쪼개지는 것 방지
 logging synchronous
 ! 로컬 계정(username) 데이터베이스로 로그인 검사
 login local
! 원격 접속(Telnet, SSH) 가상 포트 5개(0~4) 설정
line vty 0 4
 ! 로컬 계정으로 로그인 검사
 login local
 ! 오직 SSH 접속만 허용 (Telnet 차단)
 transport input ssh

! 설정 파일의 끝을 알리는 마커
end
```
# ⚙️ 라우터 기본 셋업
```
### 💻 시스코 셋업 마법사 (Configuration Dialog)
```bash
--- System Configuration Dialog ---
Continue with configuration dialog? [yes/no]: no
```
> [!info+] 무조건 `no`를 치는 이유
> NVRAM이 비어있을 때 뜨는 초보자용 설정 마법사. 중간에 오타를 수정할 수 없고 과정이 답답하므로, 실무자는 무조건 `no`를 치고 CLI(`conf t`)로 수동 설정한다.

> [!info]- 명령어 설명 (공부용)
> - `no ip domain-lookup`: 오타를 쳤을 때 라우터가 도메인 주소인 줄 알고 DNS 서버를 찾으며 렉 걸리는 현상(Translating...) 방지
> - `ena sec 123` : 관리자 모드 진입 비밀번호를 123으로 암호화하여 설정
> - `user asd sec 123` : 원격 접속 등에 쓸 로컬 계정(aaa) 생성
> - `logi loc` : 접속 시 방금 만든 로컬 계정 데이터베이스를 사용하겠다고 선언
> - `logg syn` : 명령어 치는 도중에 시스템 로그가 떠서 글자가 쪼개지는 현상 방지
> - `exec-t`: 타임아웃
> - `ter h s` : 기록 저장량 수정

**기본**
```sh
en
terminal history size 256
conf t
no ip domain-lookup
lin co 0
logg syn
exec-t 30
do cop r s

exi

```
**보안 추가**
```sh
en
terminal history size 256
conf t
no ip domain-lookup
ena sec 123
user asd sec 123
lin co 0
logi loc
logg syn
do cop r s

exi

```
**초기화** (만일 리로드 후 저장 여부 물어보면 반드시 'no' 선택)
```sh
erase startup-config

reload
```
# 명령어
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
'(config-line)#'transport input ssh # SSH만 허용
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
ip ad "ip"
no sh

sh ip route #경로 보여주는 명령어
```
# 라우팅
## 라우팅, 스테틱, 디폴트
### 기초 설명 및 명령어
![[Pasted image 20260309112812.png]]
```bash
밑의 3개는 다이나믹 라우팅 프로토콜에선 자동 가능.
```
![[Pasted image 20260309105518.png]]
```bash
다이나믹 라우팅은 복잡할 떄, 스테틱은 단순할 때(특히 경로가 1자일 떄). 둘 중 하나 골라 사용 함.
데이터를 보내려면 상대 인터페이스의 정보를 알아야 함
```
>[!warning]
>스테틱 라우팅은 관리자가 잘 알고 있어야 트래픽이 느려지는 등 장애가 발생하지 않음.

![[Pasted image 20260309113404.png]]
![[Pasted image 20260309113752.png]]
![[Pasted image 20260309114050.png]]
>[!tip]
>| (파이프)는 or의 뜻을 가짐

![[Pasted image 20260309114401.png]]
```bash
3-2번은 현재는 해당되지 않음. 발전이 됨.
```
![[Pasted image 20260309114728.png]]
```sh
인터페이스 까지만 입력해도 잘 됨. dist,pmnt는 필수 X
보통은 ad와 in 중 in을 이미 자기꺼이고, 짧아서 더 자주 넣음 
Admin Distance: 우선순위.
```
![[Pasted image 20260309132006.png]]
```sh
디폴트 라우팅: 테이블에 일치하는거 없으면 이거 씀
no ip route "ip" #루트 삭제
```
### 🛑 디폴트 라우팅(Default Routing)의 절대 원칙

> [!success] 💡 핵심 명언 (뇌에 새길 것)
> **"디폴트 라우팅(`0.0.0.0 0.0.0.0`)은 무조건 끝 단(Stub Router)에만 쓴다!"**

> [!question] 왜 중간 라우터(Transit)에는 쓰면 안 될까?
> 1. **기계적 치명상 (Routing Loop):** 서로 마주 보는 라우터에 디폴트를 주면 패킷이 무한 핑퐁을 치며 네트워크가 뻗는다.
> 2. **확장성(Scalability) 제로:** 새로운 라우터나 망이 추가될 때, 기존 디폴트 경로와 충돌하여 트래픽이 엉뚱한 곳으로 블랙홀처럼 빨려 들어간다.
> 3. **유지보수(Maintenance) 지옥:** 라우팅 테이블에 명시적인 목적지 IP가 안 적혀 있어서, 장애 발생 시 트래픽의 흐름을 추적하기가 불가능에 가깝다. (인수인계 시 욕먹기 딱 좋음)

> [!tip] 실무 엔지니어의 마인드셋
> 귀찮다고 코어(Core)나 분배(Distribution) 계층에 디폴트를 남발하지 마라. 귀찮으면 **동적 라우팅(OSPF)**을 올리는 것이 정답이지, 꼼수 정적 라우팅을 쓰는 것은 시한폭탄을 심는 것과 같다.

### 🛣️ 정적 라우팅(Static Route) 설정 규칙: IP vs 인터페이스

> [!warning] 이더넷(FastEthernet/Gigabit) 구간의 함정
> 이더넷은 태생이 '다중 접속(Multi-Access)' 환경이다. 물리적으로 1:1로 연결되어 있어도, 라우터는 스위치처럼 여러 대가 연결된 광장으로 인식한다.

| 연결 방식 | 라우팅 설정 방법 | 이유 (ARP 동작 방식) |
| :--- | :--- | :--- |
| **이더넷 (f0/0, g0/0)** | 무조건 **Next-Hop IP** 사용 | 출구만 지정하면 최종 목적지 IP를 찾으려고 허공에 소리침(ARP 실패). 정확히 다음 라우터의 IP를 불러서 넘겨줘야 함. |
| **시리얼 (s0/0/0)** | **출구 인터페이스** 사용 가능 | 1:1 전용선(Point-to-Point)이므로, 문밖으로 던지면 무조건 반대편 라우터가 받게 되어 있음. |

**💻 올바른 명령어 예시 (이더넷 환경)**
```bash
! ❌ 잘못된 방식 (통신 안 됨)
ip route 172.11.0.0 255.255.255.0 f0/0

! ⭕ 올바른 방식 (다음 라우터의 IP를 정확히 지목)
ip route 172.11.0.0 255.255.255.0 192.168.1.1
```
### 🏓 라우팅 테이블의 계급과 TTL (Time To Live)

> [!info] 라우터의 절대 계급 (Administrative Distance)
> 라우터는 절대 찍기(50/50)를 하지 않는다. 무조건 계급이 높은 경로를 우선한다.
> 1. **Connected (직접 연결):** 0순위. 내 몸에 꽂힌 선.
> 2. **Static (정적 라우팅):** 1순위. 관리자가 적어준 길.
> 3. **Default (`0.0.0.0`):** 꼴찌. 아는 길이 하나도 없을 때만 쓰는 최후의 보루.

> [!warning] 🚨 장애 발생 시 라우팅 루프 시나리오
> 4. R1과 PC2의 연결이 끊어지면, R1의 라우팅 테이블에서 PC2 대역(Connected)이 삭제됨.
> 5. 누군가 PC2로 핑을 쏘면, R1은 모르는 주소이므로 디폴트 라우트를 타고 R2로 던짐.
> 6. R2는 정적 라우팅 설정에 따라 "PC2는 R1 쪽에 있다"며 다시 R1으로 던짐.
> 7. **결과:** R1과 R2 사이에서 무한 핑퐁(Routing Loop) 발생!

> [!check] TTL (생존 시간)의 방어
> 다행히 패킷이 영원히 돌지는 않는다. IP 헤더에는 `TTL`이라는 수명 값이 있어서, 라우터를 거칠 때마다 1씩 감소한다. 0이 되면 패킷은 자동 폐기된다. (`TTL expired in transit` 에러 발생)

## 다이나믹
![[Pasted image 20260312105206.png]]
- AS 번호는 회사에서 지정

### RIPv2
![[Pasted image 20260312131745.png]]
![[Pasted image 20260312131803.png]]
- 네트워크 선택은 직렬된 네트워크만 해주면 됨.
![[Pasted image 20260312131832.png]]
![[Pasted image 20260312132418.png]]
#### 🗺️ 동적 라우팅 트러블슈팅 2대장 명령어 비교

> [!abstract] 핵심 비유 (택배 회사)
> - `show ip route` = **"최종 완성된 배달 지도 (결과물)"**
> - `show ip protocols` = **"택배 회사의 내부 운영 규칙 (과정/설정)"**
##### 1. `show ip route` (결과 확인용)
라우터의 뇌 속에 최종적으로 저장된 **'내비게이션 지도'**를 보여준다.
- **언제 쓰나?** "그래서 지금 192.168.4.0으로 가는 길이 뚫렸어, 안 뚫렸어?"를 확인할 때.
- **무엇을 보나?** 
  - 맨 앞에 `R` (RIP으로 알아온 길), `C` (직접 연결된 길), `S` (수동으로 뚫은 길) 마크 확인.
  - 목적지 IP와 Next-Hop IP가 정확한지 확인.

##### 2. `show ip protocols` (원인 분석용) 🌟 실무자들의 무기
라우터가 현재 **'어떤 규칙'**으로 다른 라우터와 대화(라우팅 프로토콜)하고 있는지 보여준다.
- **언제 쓰나?** "아니, RIP을 켰는데 왜 `show ip route`에 길이 안 올라오지? 내가 설정 뭘 빼먹었지?" 하고 **에러 원인을 찾을 때.**
- **무엇을 보나? (RIP 트러블슈팅 3대장)**
  1. **Routing Protocol is "rip":** RIP이 정상적으로 켜져 있는가?
  2. **Default version control:** 내가 `version 2`로 제대로 바꿨는가? (버전 1과 2는 서로 대화가 안 됨!)
  3. **Routing for Networks:** 내가 `network` 명령어로 **'우리 동네 주소'를 정확히 광고(선언)**하고 있는가?
![[Pasted image 20260312132441.png]]
#### 🚨 [장애 보고서] RIP과 Default Route 혼용 시 발생하는 대참사

> [!danger] 💀 증상: "갈 수는 있는데, 돌아올 수가 없다! (One-way Ticket)"
> - **상황:** 양 끝단 라우터(R1, R4)에는 디폴트 라우팅(`0.0.0.0`)을 걸고, 중간 라우터(R2, R3)에는 RIP을 돌림.
> - **결과:** PC에서 서버로 핑을 쏘면 목적지까지는 가는데, **서버가 PC로 답장을 보낼 때 중간 라우터(R3)에서 패킷이 드랍(Drop)됨.**

##### 🕵️‍♂️ 원인 분석: 왜 중간 라우터에서 죽었을까?
1. **출발 (PC ➡️ 서버):** R1은 디폴트 라우팅이 있으니 "모르면 무조건 R2로 던져!" 하고 패킷을 보냄. R2, R3는 RIP으로 길을 아니 서버까지 잘 도착함.
2. **답장 (서버 ➡️ PC):** 서버가 답장을 R4 ➡️ R3로 보냄.
3. **사망 (R3의 기억상실):** R3가 라우팅 테이블을 까봄. **"어? 나한테 핑 쏜 PC(172.16.1.0)로 가는 길이 없네?"** ➡️ 쓰레기통으로 직행.
4. **핵심 이유:** R1이 RIP을 통해 **"우리 동네에 172.16.1.0 있어!"**라고 R2, R3에게 소문(Update)을 내주지 않았기 때문에, 코어 망(R2, R3)은 PC 대역의 존재 자체를 모르는 까막눈이 되어버림.

---

##### 🛠️ 실무 해결책: 혼용하려면 이렇게 해라!

실무에서는 끝단(Stub) 라우터의 자원을 아끼기 위해 디폴트 라우팅을 적극적으로 쓴다. 단, 코어 망(RIP/OSPF)과 혼용할 때는 **반드시 '돌아오는 길'을 만들어줘야 한다.**

**✅ 방법 1: 순수 RIP으로 통일하기
가장 깔끔한 방법. 과거에 설정했던 디폴트 라우팅(망령)을 `no ip route 0.0.0.0 0.0.0.0`으로 싹 다 지워버리고, 모든 라우터가 공평하게 RIP으로 지도를 교환하게 만든다.

**✅ 방법 2: 디폴트 라우팅을 RIP에 강제 주입하기 (Redistribute)**
실무 고인물들의 스킬. R1은 디폴트 라우팅을 쓰되, R2/R3에게 **"야, 인터넷 가려면 나한테 다 던져!"**라고 디폴트 경로를 RIP 소문에 섞어서 퍼뜨리는 마법의 명령어다.
```bash
! R1 (끝단 라우터) 설정
conf t
! 1. 일단 외부로 나가는 디폴트 라우팅을 뚫는다.
ip route 0.0.0.0 0.0.0.0 12.12.12.2

! 2. RIP 설정에 들어가서
router rip
version 2
no auto-summary
! 3. 내 PC 대역(172.16.1.0)을 RIP으로 광고해서 돌아오는 길을 알려주고,
network 172.16.1.0
! 4. 🌟 내가 가진 디폴트 라우팅 경로를 RIP 이웃들에게 강제로 뿌려버린다!
default-information originate
```

**✅ 방법 3: 코어 라우터에 정적 라우팅(Static) 추가하기**
R1이 RIP을 안 쓴다면, R2가 R1의 PC 대역으로 가는 길을 수동으로 알게 해줘야 한다.
```bash
! R2 (중간 라우터) 설정
conf t
! "172.16.1.0 (PC 대역)으로 가려면 R1(12.12.12.1)으로 던져라!" 라고 수동으로 길을 파줌
ip route 172.16.1.0 255.255.255.0 12.12.12.1
```
### DHCP
![[Pasted image 20260311144433.png]]
- DHCP+라우터=공유기
- Win+R -> ncpa.cpl -> 속성 -> IPv4 속성에서 자동으로 IP 주소 받기 하면 DHCP 사용하는거임
- PC가 다른 네트워크에 접속 했을 때 랜덤으로 IP 줌.
- 무조건 랜덤은 아니고 1열의 저거로 설정 가능. 대신 일일히 관리 해야 됨.
- 릴레이 에이전트, IP 헬퍼로 설정
- 강의장이 이거 씀
- **Discover:** PC가 브로드캐스트
- **Offer:** 서버가 IP 제안. 서버 수 만큼 제안함
- **Request:** PC가 offer 하나 골라서 브로드캐스트로 요청
- **Ack:** Ack
![[Pasted image 20260311145420.png]]
- DHCP 대역 이름
- 설정 할 넷의 ip, 섭넷
- 디폴트 게이트웨이로 쓰는 라우터 IP
- DNS 서버의 IP (통신 되는거면 암거나 해도 됨)
- 나가
- 고정 IP 대역
>[!failure] PC의 IP가 169.254.XX.XX로 되면 DHPC가 이상한거임. 검사 필요.
## 라우팅 문제
>[!warning] Cisco의 서버에서 제공하는 DHCP는 너무 허접해서 라우터에 DHCP 할거임.
### 문제 1
![[Pasted image 20260309163620.png]]
```bash
각 PC의 디폴 게이트웨이는 라우터로 설정
1번, 4번 라우터는 각각 2번, 3번과 루트.
2번, 3번은 양방향으로 루트.
양측의 PC가 서로 통신이 된다고 PC가 중간의 라우터와 통신 할 순 없음
단. 디폴트 라우팅 설정 해주면 가능
```
### 문제 2: Hub & Spoke 정적 라우팅 구성
![[Pasted image 20260310131846.png]]
> [!info] 토폴로지 분석 > 중앙 라우터(Hub)를 거쳐야만 다른 대역으로 갈 수 있는 구조.
> R11-R12, R13-R14 간에는 직접 연결된 백도어(Backdoor) 링크가 존재함.
#### 1. 모든 통신을 중앙(Hub)으로 몰아주기 (Default Route)
```sh
[중앙] - 각 지사(Spoke)의 루프백 대역으로 가는 길을 정확히 지정
en
conf t
ip route 172.11.0.0 255.255.255.0 192.168.1.2
ip route 172.12.0.0 255.255.255.0 192.168.1.6
ip route 172.13.0.0 255.255.255.0 192.168.1.10
ip route 172.14.0.0 255.255.255.0 192.168.1.14


[R11]
en
conf t
ip route 0.0.0.0 0.0.0.0 192.168.1.1

[R12]
en
conf t
ip route 0.0.0.0 0.0.0.0 192.168.1.5

[R13]
en
conf t
ip route 0.0.0.0 0.0.0.0 192.168.1.9

[R14]
en
conf t
ip route 0.0.0.0 0.0.0.0 192.168.1.13
```
#### **2. 직접 연결된 이웃은 직접, 나머지는 중앙으로**
```sh
[중앙] - 각 지사(Spoke)의 루프백 대역으로 가는 길을 정확히 지정
en
conf t
ip route 172.11.0.0 255.255.255.0 192.168.1.2
ip route 172.12.0.0 255.255.255.0 192.168.1.6
ip route 172.13.0.0 255.255.255.0 192.168.1.10
ip route 172.14.0.0 255.255.255.0 192.168.1.14


[R11]
en
conf t
!중앙 루프백
ip route 10.10.10.0 255.255.255.0 192.168.1.1
!이웃 루프백 (백도어 활용)
ip route 172.12.0.0 255.255.255.0 192.168.1.18
!나머지 중앙 경유
ip route 172.13.0.0 255.255.255.0 192.168.1.1
ip route 172.14.0.0 255.255.255.0 192.168.1.1

[R12]
en
conf t
ip route 0.0.0.0 0.0.0.0 192.168.1.5

[R13]
en
conf t
ip route 0.0.0.0 0.0.0.0 192.168.1.9

[R14]
en
conf t
ip route 0.0.0.0 0.0.0.0 192.168.1.13
```


```sh
[중앙]
en
conf t
ip route 172.11.0.0 255.255.255.0 192.168.1.2
ip route 172.12.0.0 255.255.255.0 192.168.1.6
ip route 172.13.0.0 255.255.255.0 192.168.1.10
ip route 172.14.0.0 255.255.255.0 192.168.1.14

[R11]
en
conf t
!직접
ip route 10.10.10.0 255.255.255.0 192.168.1.1
ip route 172.12.0.0 255.255.255.0 192.168.1.18
!중앙 경유
ip route 172.13.0.0 255.255.255.0 192.168.1.1
ip route 172.14.0.0 255.255.255.0 192.168.1.1
!반송 경로 인식
ip route 192.168.1.8 255.255.255.252 192.168.1.1
ip route 192.168.1.12 255.255.255.252 192.168.1.1

[R12]
en
conf t
!직접
ip route 10.10.10.0 255.255.255.0 192.168.1.5
ip route 172.11.0.0 255.255.255.0 192.168.1.17
!중앙 경유
ip route 172.13.0.0 255.255.255.0 192.168.1.5
ip route 172.14.0.0 255.255.255.0 192.168.1.5
!반송 경로 인식
ip route 192.168.1.8 255.255.255.252 192.168.1.5
ip route 192.168.1.12 255.255.255.252 192.168.1.5

[R13]
en
conf t
!직접
ip route 10.10.10.0 255.255.255.0 192.168.1.9
ip route 172.14.0.0 255.255.255.0 192.168.1.22
!중앙 경유
ip route 172.11.0.0 255.255.255.0 192.168.1.9
ip route 172.12.0.0 255.255.255.0 192.168.1.9
!(약식 ping의 경우) 반송 경로 인식
ip route 192.168.1.0 255.255.255.252 192.168.1.9
ip route 192.168.1.4 255.255.255.252 192.168.1.9

[R14]
en
conf t
!직접
ip route 10.10.10.0 255.255.255.0 192.168.1.12
ip route 172.13.0.0 255.255.255.0 192.168.1.21
!중앙 경유
ip route 172.11.0.0 255.255.255.0 192.168.1.12
ip route 172.12.0.0 255.255.255.0 192.168.1.12
!(약식 ping의 경우) 반송 경로 인식
ip route 192.168.1.0 255.255.255.252 192.168.1.12
ip route 192.168.1.4 255.255.255.252 192.168.1.12
```
>[!warning] 🚨 Ping 테스트 시 주의사항 (출발지 IP의 함정)  
라우터에서 그냥 ping 172.13.0.1을 치면, 출발지 IP가 내 루프백(172.11.0.1)이 아니라 **패킷이 나가는 물리적 인터페이스(192.168.1.2)**로 찍힌다.  
상대방 라우터에 192.168.1.0/30 대역으로 돌아오는 라우팅이 없다면 패킷은 반송되지 못하고 Drop(Request timed out) 된다.

>[!tip] 💡 해결책: 확장 핑 (Extended Ping)  
위와 같은 문제를 막기 위해, 실무에서는 라우터 간 통신 테스트 시 반드시 출발지 IP를 루프백으로 고정해서 쏜다.  
**사용법:** 관리 모드(#)에서 ping만 치고 엔터를 누른 뒤, Source address or interface: 항목에 내 루프백 IP를 적어준다.
### 문제 3
![[Pasted image 20260310143317.png]]
#### 1. 포트 뚫기
```sh
[R1]
en
conf t
in g0/0
ip ad 192.168.1.1 255.255.255.0
! 메인 IP?(0)와 브로드캐스트 IP?(255)를 제외하곤 마음대로 정할수 있는 끝자리는 1번 라우터라 1로 정함. 이하 모든 IP는 해당 규칙에 따라 결정됨.
no sh
ex
in g0/1
ip ad 12.12.12.1 255.255.255.0
no sh
ex

[R2]
en
conf t
in g0/1
ip ad 12.12.12.2 255.255.255.0
no sh
ex
in g0/0
ip ad 23.23.23.2 255.255.255.0
no sh
ex
in lo 0
ip ad 192.168.2.1 255.255.255.0
no sh
ex

[R3]
en
conf t
in g0/0
ip ad 23.23.23.3 255.255.255.0
no sh
ex
in g0/1
ip ad 34.34.34.3 255.255.255.0
no sh
ex
in lo 0
ip ad 192.168.3.1 255.255.255.0
no sh
ex

[R4]
en
conf t
in g0/1
ip ad 34.34.34.4 255.255.255.0
no sh
ex
in g0/0
ip ad 192.168.4.4 255.255.255.0
no sh
ex

```
#### 2. 루트 뚫기
```sh
[R1] - 계급 덕에 디폴트만 지정해주면 ㅇㅋ
ip route 0.0.0.0 0.0.0.0 12.12.12.2

[R2] - 목적,출발지에 따라 전송,반송 해주기 위해 스테틱. 직렬된 네트웤 빼고 전부.
ip route 192.168.1.0 255.255.255.0 12.12.12.1
ip route 192.168.4.0 255.255.255.0 23.23.23.3
ip route 192.168.3.0 255.255.255.0 23.23.23.3
ip route 34.34.34.0 255.255.255.0 23.23.23.3

[R3] - 목적,출발지에 따라 전송,반송 해주기 위해 스테틱. 직렬된 네트웤 빼고 전부.
ip route 192.168.1.0 255.255.255.0 23.23.23.2
ip route 192.168.4.0 255.255.255.0 34.34.34.4
ip route 192.168.2.0 255.255.255.0 23.23.23.2
ip route 12.12.12.0 255.255.255.0 23.23.23.2

[R4] - 계급 덕에 디폴트만 지정해주면 ㅇㅋ
ip route 0.0.0.0 0.0.0.0 34.34.34.3
```
>[!warning] 🚨**라우터에서 핑 칠 땐 확장 핑 사용 잊지 말기!**
>라우터에서 그냥 핑을 쏘면 출발지 IP가 나가는 포트의 IP로 찍힌다. 반드시 ping 엔터 후 Source IP를 루프백으로 지정해서 쏠 것!
### 문제 3-1
![[Pasted image 20260311101600.png|697]]
#### 1. 신입 포트 뚫기 (인터페이스 추가)
##### R5
- 스위치와 연결
```sh
conf t
in g0/0
ip ad 192.168 5.5 255.255.255.0
no sh
아오씨 왤케 많아 집 가서 해
```
##### R6
```sh

```
##### R7
```sh

```
#### 2. 신입 루트 뚫기
##### R5
```sh

```
##### R6
```sh

```
##### R7
```sh

```
#### 3. 기존 라우터 루트 수정 및 추가
##### R1 - 끝 단. 건들거 없음
##### R2 - 신규 루트 추가
```sh

```
##### R3 - 신규 루트 추가
```sh

```

##### R4 - 신규 루트 추가, <mark style="background: #FF0000;">디폴트 제거</mark>
>[!warning] 기존에 있는 디폴트 지워야 함. 라우터 증설하며 끝 단이 아니게 됨.
```sh

```
### 문제 1-1
![[Pasted image 20260312101308.png]]
```sh
[R0,3]
conf t
ip dhcp pool "이름"
network "여기 네트웤" "네트웤 서브넷"
default-router "자기 자신(라우터) IP"
dns-server "DNS 서버의 IP"
exi
ip dhcp excluded-address "제외할 IP 시작" "제외할 IP 끝" (라우터 IP만 지우면 돼서 끝은 안 적고 라우터 IP만 지우면 됨.)
```
### 문제 1-2
#### 1. 기존 라우터 루트 다 지우기
>[!tip] 가장 빠르게 기존 루트 지우는 법!
>1. **sh r**
>2. **ip classless** 밑에 적힌 애들을 **컨트롤+인서트**
>3. 메모장 같은 곳에 붙혀넣은 뒤 앞에 싹 다 **no** 적고 정리 후 **컨+인**
>4. 라우터 콘솔에 **쉬프트+인서트** 하면 끝남!
#### 2. RIPv2 설정
```sh
[R0]
conf t
ro r
v 2
no a
ne 192.168.1.0
ne 12.12.12.0

[R1]
conf t
ro r
v 2
no a
ne 12.12.12.0
ne 23.23.23.0

[R2]
conf t
ro r
v 2
no a
ne 23.23.23.0
ne 34.34.34.0

[R3]
conf t
ro r
v 2
no a
ne 34.34.34.0
ne 192.168.2.0
```
# ACL
**Access
Control
List**
## 🎯 ACL 설계의 절대 원칙

> [!danger] 🚨 좁은 대역(Host) 먼저, 넓은 대역(Any)은 나중에!
> 라우터는 ACL 명단을 위에서부터 아래로 순서대로 읽는다.|
> 패킷이 특정 줄의 조건과 **일치(Match)하는 순간, 즉시 허용/차단 조치를 취하고 아래쪽 명단은 무시해 버린다.**

> [!info] 💡 올바른 순서 배치법 (사장님 살리기 프로젝트)
> - **목표:** 사장님(1.1.1.1)은 허용, 나머지 직원 대역(1.1.1.0/24)은 차단, 그 외 외부 인터넷은 모두 허용.
```bash
! 1순위 (가장 좁음): 사장님 PC 딱 1대만 먼저 구출 (Permit)
access-list 1 permit host 1.1.1.1

! 2순위 (중간 범위): 나머지 직원 대역 254대 싹 다 차단 (Deny)
access-list 1 deny 1.1.1.0 0.0.0.255

! 3순위 (가장 넓음): 그 외 세상 모든 IP는 허용 (Permit Any)
access-list 1 permit any
```
>[!success] 🏁 마무리는 항상 Any  
ACL의 맨 마지막 줄은 무조건 permit any 또는 deny any로 명시적으로 닫아주는 습관을 들여라.
>
>- **permit any:** 특정 IP만 차단하고 나머지를 살려야 할 때 필수! (안 쓰면 다 죽음)
  >  
>- **deny any:** 특정 IP만 허용하고 나머지를 막을 때 필수! (로그 카운트를 눈으로 확인하기 위해)

![[Pasted image 20260313092006.png]]

![[Pasted image 20260313092723.png]]
![[Pasted image 20260313100336.png]]
![[Pasted image 20260313100402.png]]
![[Pasted image 20260313100415.png]]
![[Pasted image 20260313100432.png]]
![[Pasted image 20260313100501.png]]
## 🎭 ACL의 변검술: 와일드카드 마스크 (Wildcard Mask)

> [!question] 왜 ACL은 서브넷 마스크를 안 쓰고 뒤집어서 쓸까?
> 서브넷 마스크는 '네트워크의 크기'를 자르는 용도지만, 와일드카드 마스크는 특정 IP 패턴을 핀셋처럼 집어내는 **'검색 필터(몽타주)'** 용도이기 때문이다.

>[!info] 와일드카드 마스크의 절대 규칙 (0과 1의 의미)
> - **`0` (Must Match):** "이 부분은 IP 주소와 **정확히 일치**해야 한다! (검사해!)"
> - **`1` (Don't Care):** "이 부분은 숫자가 뭐든 **상관없다!** (무시해!)"

### 💡 실무 1초 계산법 (뺄셈 공식)
`255.255.255.255` - `[서브넷 마스크]` = `[와일드카드 마스크]`
- 예) `/24 (255.255.255.0)` ➡️ **`0.0.0.255`**
- 예) `/30 (255.255.255.252)` ➡️ **`0.0.0.3`**

### 💻 ACL 설정 맛보기 (복붙용)
```bash
! 전역 설정 모드
conf t
! 192.168.1.0/24 대역의 모든 PC가 들어오는 것을 허용(permit)하는 규칙
! (앞의 192.168.1은 정확히 검사하고, 마지막 자리는 무시해라!)
access-list 10 permit 192.168.1.0 0.0.0.255
```
> [!tip] 🚨 와일드카드 마스크의 특수 키워드 2가지
> 매번 `0.0.0.0`이나 `255.255.255.255`를 치기 귀찮은 엔지니어들을 위한 단축어!
> 1. **`host`:** 딱 1대의 PC만 콕 집을 때 (`0.0.0.0`과 동일)
>    - `access-list 10 permit 192.168.1.100 0.0.0.0` ➡️ `access-list 10 permit host 192.168.1.100`
> 2. **`any`:** 세상 모든 IP를 다 지칭할 때 (`255.255.255.255`와 동일)
>    - `access-list 10 deny 0.0.0.0 255.255.255.255` ➡️ `access-list 10 deny any`
## 🛡️ 네트워크 보안의 계층적 방어 (Defense in Depth)

> [!question] 해커가 서버실에 몰래 들어와서 랜선을 꽂으면 ACL이 막아줄까?
> **정답: 못 막는다!** ACL은 IP 주소(신분증)를 검사하므로, 해커가 기존 장비의 IP를 똑같이 베껴 쓰는 'IP Spoofing(위조)'을 시전하면 속수무책으로 뚫린다.

> [!danger] 🚨 계층별 보안의 역할 분담
> 보안은 하나의 기술로 막는 것이 아니라, L2(스위치)와 L3(라우터)에서 이중 삼중으로 막아야 한다. 이때 쓰는게 [[스위치]]의 [[스위치#2. 👮 포트 보안 (Port Security) "MAC 주소 문지기"|포트 보안]]이다.

| 보안 기술             | 작동 계층       | 검사 대상 (비유)          | 해커의 우회 방법           | 방어 목적                            |
| :---------------- | :---------- | :------------------ | :------------------ | :------------------------------- |
| **Port Security** | L2 (스위치)    | **MAC 주소 (지문)**     | MAC 주소까지 위조해야 함     | **물리적 침입 방어** (낯선 기기 연결 시 포트 차단) |
| **ACL**           | L3/L4 (라우터) | **IP / Port (신분증)** | IP 주소 위조 (Spoofing) | **논리적 침입 방어** (허용되지 않은 트래픽 필터링)  |
## ALC 명령어
>[!danger] 보안 명령어는 순서가 극히 중요함! 늘 좁은 대역 먼저 할 것!

>[!danger] 🎯 ACL의 절대 위치 공식 
>**"Standard ACL은 무조건 도착지(dest.)와 가장 가까운 라우터의 포트에, 나가는 방향(Out)으로 걸어라!"**
이유) 재수 없으면 중간에 애꿎은 놈이 차단 됨.
>
**"Extended ACL은 무조건 출발지(Source)와 가장 가까운 라우터의 포트에, 들어오는 방향(in)으로 걸어라!"**
이유) 어차피 차단 될 게 출발지와 목적지 사이 모든 장비의 자원을 낭비하게 됨.

![[Pasted image 20260313102650.png]]
![[Pasted image 20260313102715.png]]
ac "1~99 중 하나 고르기" "p|d" '받거나 쳐낼 IP' [[CISCO#🎭 ACL의 변검술 와일드카드 마스크 (Wildcard Mask)|와일드 카드]] 
![[Pasted image 20260313102743.png]]
>[!failure] deny any 안하면 show access-lists 로 기록을 볼 때 막은 기록이 안남음.

>[!tip]  permit any는 반대로 필수!

![[Pasted image 20260313102807.png]]
### 💻 Extended ACL 실전 문법 (옵션 활용)
**0. Numbered ACL (번호형) 공식**
```bash
! 전역 설정 모드 (conf t)
access-list'100~199]''permit|deny' '프로토콜' '출발지IP''출발지Wild' '도착지IP' '도착지Wild' ['eq 포트'] ['established'] ['log']
```
> [!danger] 🚨 프로토콜 작성 시 절대 주의사항 (포트 번호 매칭)
> - **`ip`:** 모든 통신(TCP, UDP, ICMP 등 싹 다 포함)을 통제할 때 쓴다. **(뒤에 `eq 80` 같은 포트 번호 절대 사용 불가! IP는 3계층이라 4계층인 포트는 모름!)**
> - **`tcp` / `udp`:** 웹(80), FTP(21), DNS(53) 등 특정 서비스를 콕 집어 통제할 때 쓴다. **(반드시 뒤에 `eq 포트번호`가 따라와야 함!)**
> - **`icmp`:** 오직 Ping 통신만 통제할 때 쓴다.

**1. 특정 포트(서비스)만 콕 집어서 차단/허용하기 (`eq`)**
```bash
! 전역 설정 모드 conf t
! 192.168.1.0 대역의 PC들이 외부(any)로 웹서핑(HTTP, 포트 80) 하는 것만 허용해라!
! (tcp 프로토콜 지정 -> 출발지 -> 목적지 -> eq 포트번호)
access-list 100 permit tcp 192.168.1.0 0.0.0.255 any eq 80
```
**2. 내부에서 시작된 연결의 응답만 허용하기 (established)**
```sh
! 외부(any)에서 내부(192.168.1.0)로 들어오는 트래픽 중, 
! 내부 PC가 먼저 요청했던 연결(established)에 대한 답장만 허용해라!
access-list 100 permit tcp any 192.168.1.0 0.0.0.255 established
```
**3. 해커 접속 시도 실시간 기록하기 (log)**
```sh
! 1.1.1.1 해커가 우리 서버(2.2.2.2)로 들어오면 차단하고, 화면에 로그(log)를 띄워라!
access-list 100 deny ip host 1.1.1.1 host 2.2.2.2 log
```
>[!warning] 🚨 실무 주의사항  
log 옵션을 너무 광범위한 규칙(예: deny ip any any log)에 걸어두면, 라우터 CPU가 로그 메시지를 찍어내느라 100%를 치고 장비가 뻗어버릴 수 있다. (디도스 공격에 취약해짐) 반드시 특정 타겟에만 걸어야 한다.

![[Pasted image 20260313102924.png]]
### 💻 Named ACL (이름형) 공식 (🌟실무 권장)
```bash
! 1. ACL 전용 편집 모드로 진입 (이름 지정)
ip access-list extended[ACL이름]
! 2. 편집 모드 안에서는 access-list 단어 없이 바로 permit/deny로 시작!
 [permit|deny] [프로토콜] [출발지IP][출발지Wild] [도착지IP] [도착지Wild] [eq 포트] [established] [log]
```

![[Pasted image 20260313102943.png]]
![[Pasted image 20260313103003.png]]

## 문제 1
![[Pasted image 20260313153838.png]]
### 인터 추가
```sh
[R1]
conf t
in g0/0
ip ad 172.16.1.1 255.255.255.0
no sh
ex
in g0/1
ip ad 12.12.12.1 255.255.255.0
no sh
end

[R2]
conf t
in g0/0
ip ad 12.12.12.2 255.255.255.0
no sh
ex
in g0/1
ip ad 23.23.23.2 255.255.255.0
no sh
ex
in g0/2
ip ad 172.16.2.2 255.255.255.0
no sh
end

[R3]
conf t
in g0/0
ip ad 23.23.23.3 255.255.255.0
no sh
ex
in g0/1
ip ad 34.34.34.3 255.255.255.0
no sh
end

[R4]
conf t
in g0/0
ip ad 34.34.34.4 255.255.255.0
no sh
ex
in g0/1
ip ad 172.16.3.4 255.255.255.0
no sh
ex
in g0/2
ip ad 10.10.4.4 255.255.255.0
no sh
end

```
### DHCP 추가 (PC ipconfig 설정)
```sh
[R1]
conf t
ip dh p 1
ne 172.16.1.0 255.255.255.0
de 172.16.1.1
dn 10.10.4.100
ex
ip dh ex 172.16.1.1

[R2]
conf t
ip dh p 2
ne 172.16.2.0 255.255.255.0
de 172.16.2.2
dn 10.10.4.100
ex
ip dh ex 172.16.2.2

[R4]
conf t
ip dhcp pool 3
network 172.16.3.0 255.255.255.0
default-router 172.16.3.4
dns-server 10.10.4.100
exi
ip dhcp excluded-address 172.16.3.4
ip dhcp pool 4
network 10.10.4.0 255.255.255.0
default-router 10.10.4.4
dns-server 10.10.4.100
exi
ip dhcp excluded-address 10.10.4.4
ip dhcp excluded-address 10.10.4.100

```
### RIPv2 추가 (라우팅 설정)
```sh
[R1]
conf t
ro r
v 2
no a
ne 172.16.1.0
ne 12.12.12.0

[R2]
conf t
ro r
v 2
no a
ne 12.12.12.0
ne 23.23.23.0
ne 172.16.2.0

[R3]
conf t
ro r
v 2
no a
ne 23.23.23.0
ne 34.34.34.0

[R4]
conf t
ro r
v 2
no a
ne 34.34.34.0
ne 172.16.3.0
ne 10.10.4.0

```
### ALC 추가 (보안 설정)
```sh
[R1]
conf t
ac 1 p 172.16.3.0 0.0.0.255
ac 1 d a
in g0/0
ip ac 1 o

[R2]
conf t
ac 2 d 172.16.1.0 0.0.0.255
ac 2 p a
in g0/2
ip ac 2 o

[R4]
conf t
ac 3 p 172.16.1.0 0.0.0.255
ac 3 p 172.16.2.0 0.0.0.255
ac 3 d a
ac 4 d 172.16.1.0 0.0.0.255
ac 4 d 172.16.2.0 0.0.0.255
ac 4 p a
in g0/1
ip ac 3 o
ex
in g0/2
ip ac 4 o
```
## 문제 2
![[Pasted image 20260316131812.png]]
```sh
access-list '100~199''permit|deny' '프로토콜' '출발지IP''출발지Wild' '도착지IP' '도착지Wild' ['eq 포트'] ['established'] ['log']
```

- **하나로 퉁 칠 때**
```sh
[Busan]
conf t
ac 101 d tcp host 192.168.4.2 host 192.168.3.2 eq 80 log
ac 101 p tcp host 192.168.1.2 host 192.168.3.2 eq 80 log
ac 101 d ip host 192.168.1.2 host 192.168.3.2
ac 101 p ip a a
in g0/1
ip ac 101 o
```

>[!danger] 🎯 [[CISCO#ALC 명령어|Extended ACL의 절대 위치 공식]]
**"Extended ACL은 무조건 출발지(Source)와 가장 가까운 라우터의 포트에, 들어오는 방향(in)으로 걸어라!"**
이유) 어차피 차단 될 게 출발지와 목적지 사이 모든 장비의 자원을 낭비하게 됨.

- **통신 장비 아낄 때**
```sh
[Busan]
conf t
ac 101 d tcp host 192.168.4.2 host 192.168.3.2 eq 80
ac 101 p ip a a
in g0/2
ip ac 101 i

[Seoul]
conf t
ac 102 p tcp host 192.168.1.2 host 192.168.3.2 eq 80
ac 102 d ip host 192.168.1.2 host 192.168.3.2
ac 102 p ip a a
in g0/1
ip ac 102 i
```
## 문제 3
![[Pasted image 20260316145840.png]]
>[!warning] **WEB** 서버다! 프로토콜 똑바로 해라!
```sh
[Router]
conf t
ac 101 p tcp host 192.168.240.3 host 172.22.242.23 eq 80
ac 101 d tcp a host 172.22.242.23 eq 80
ac 101 p ip a a
in f0/0
ip ac 101 i
```
>[!tip] 엑세스 리스트 적용은 F0/1이 낫다!
>여기선 괜찮지만, 실제라면 외부망(빨간 선의 라우터)에서 오는 공격을 막으려면, **F0/1**에 있어야 외부망도 거른다.
# NAT
## 사설 IP 범위
- 10.x.x.x
- 172.16.x.x ~ 172.31.x.x
- 192.168.x.x
## 설명 및 명령어
![[Pasted image 20260317094109.png]]
![[Pasted image 20260317111125.png]]
![[Pasted image 20260317111402.png]]
![[Pasted image 20260317101208.png]]
![[Pasted image 20260317111213.png]]
![[Pasted image 20260317111239.png]]
![[Pasted image 20260317111255.png]]
![[Pasted image 20260317111339.png]]

## 문제 
### 문제1
![[Pasted image 20260317133447.png]]
- **1.**
```sh
[Router1]
conf t
ac 1 p 192.168.20.0 0.0.0.255
ip nat inside source list 1 int g0/1 overload
in g0/0
ip nat inside
in g0/1
ip nat outside
```
- **2.**
-   >[!failure] 스테틱 NAT은 중첩 없다!
```sh
[Router0]
conf t
ip nat inside source static 192.168.10.100 12.12.12.1
in g0/0
ip nat inside
in g0/1
ip nat outside
```
- **TMI**
```sh
[R0]
ac 1 p 192.168.10.0 0.0.0.255
ip nat inside source list 1 in g0/1 overload
!ip nat inside랑 outside는 스테틱 NAT 하면서 했으니깐 안해도 됨. (아마.)

[R1]
ip nat inside source static 192.168.20.100 12.12.12.6
!R0과 마찬가지로 NAT-PAT 할 때 포트에 적용은 이미 끝남.

[R2]
ac 1 p 192.168.30.0 0.0.0.255
ip nat inside source list 1 in g0/1 overload 
ip nat inside source list 1 in g0/0 overload
in g0/2
ip nat inside 
in g0/0
ip nat outside 
in g0/1
ip nat outside 
ex
ip nat in source static 192.168.30.100 12.12.12.2
```
### 2
![[Pasted image 20260317163610.png]]
- **1.**
```sh
[R0]
en
terminal history size 256
conf t
no ip domain-lookup
lin co 0
logg syn
exec-t 30
do cop r s



[R1]
en
terminal history size 256
conf t
no ip domain-lookup
lin co 0
logg syn
exec-t 30
do cop r s

```
- **2.**
```sh
[R0]
in g0/0
ip ad 192.168.100.254 255.255.255.0
no sh
in g0/1
ip ad 80.0.0.1 255.255.255.252
no sh

[R1]
in g0/0
ip ad 10.0.0.254 255.255.255.0
no sh
in g0/1
ip ad 80.0.0.2 255.255.255.252
no sh

```
- **3.**
```sh
[R0]
ro r
v 2
no a
ne 192.168.100.0
ne 80.0.0.0
!pool 루트 뚫기
ne 112.221.198.144
ex
!RIP를 쓸 땐 직렬된 애들만 입력한다->pool은 가상이다->pool 그냥 넣으면 RIP 광고 안된다->루프백으로 속인다?
in lo 0
ip ad 112.221.198.145 255.255.255.240

[R1]
ro r
v 2
no a
ne 10.0.0.0
ne 80.0.0.0
ne 112.221.198.160
ex
in lo 0
ip ad 112.221.198.161 255.255.255.240
```
- **4.**
```sh
[R0]
ip nat pool tlqkf 112.221.198.145 112.221.198.158 netmask 255.255.255.240
ac 1 p 192.168.100.0 0.0.0.255
ip nat inside source list 1 pool tlqkf overload
in g0/0
ip nat inside
in g0/1
ip nat outside
```
- **5.**
```sh
[R1]
ip nat inside source static 10.0.0.1 112.221.198.161
ip nat inside source static 10.0.0.2 112.221.198.162
in g0/0
ip nat inside
in g0/1
ip nat outside
```