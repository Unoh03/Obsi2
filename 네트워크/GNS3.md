# 시스코 복붙
![[Pasted image 20260318093929.png]]
## **-1. 1번 네트웍에서 스위치랑 PC 사이 선 왜 빨개?????**
```sh
???????????????????????????????????
레전드 버그 터짐. 강사님 실험 결과 서버는 잘 돼서 PC 부수고 서버 대신 사용. 이름은 PC로 수정.
```
## **0. DNS 서버 설정** 
```sh
!서버 클릭 → 서비스 → 타입 냅두고 이름, 주소 입력 후 add
!위 방법 따라 DNS 서버에 네이버, 구글의 정보 입력

!ipconfig 설정
[네이버 서버]
!IP: 172.16.0.1
!섭넷: 255.255.255.0
!디폴 게이트: 172.16.0.254

[구글 서버]
!IP: 3.3.3.3
!섭넷: 255.255.255.248
!디폴 게이트: 3.3.3.6
```
## **0-1. DNS 서버 설정** 
```sh
2번 네트웤의 DNS 서버를 버리고, 네이버나 구글의 서버에 모든 DNS 서비스 정보를 넣고, PC의 DNS 서버를 그쪽으로 지정해도 됨

이 방법이 최초에 한 방법.
```
## **1. 인터페이스 추가**
```sh
[R1]
conf t
int f0/0
ip add 192.168.1.254 255.255.255.0
no sh
int f0/1
ip add 12.12.12.1 255.255.255.0
no sh

[R2]
conf t
int f0/1
ip add 12.12.12.2 255.255.255.0
no sh
int f1/0
ip add 23.23.23.1 255.255.255.0
no sh
int f0/0
ip add 192.168.2.1 255.255.255.0
no sh

[R3]
conf t
int f1/0
ip add 23.23.23.3 255.255.255.0
no sh
int f0/1
ip add 34.34.34.3 255.255.255.0
no sh
int f0/0
ip add 192.168.3.1 255.255.255.0
no sh

[R4]
conf t
int f0/1
ip add 34.34.34.4 255.255.255.0
no sh
int f0/0
ip add 192.168.4.1 255.255.255.0
no sh

```
## **2. DHCP 설정하기**
```sh
[R1]
conf t
ip dhcp pool pc
net 192.168.0.0 255.255.255.0
def 192.168.0.254
dns 11.11.11.11
exit
ip dhcp excluded-address 192.168.0.254

[R2]
conf t
ip dhcp pool se
net 2.2.2.0 255.255.255.240
def 2.2.2.14
dns 11.11.11.11
exit
ip dhcp excluded-address 2.2.2.14

```
## **3. 루트 뚫기**
```sh
[R1]
!ne 192.168.0.0 은 보안 상 광고되면 안됨. 하지 않음
conf t
router r
version 2
no au
net 12.12.12.0

[R2]
conf t
router r
version 2
no au
net 12.12.12.0
net 23.23.23.0
net 2.2.2.0

[R3]
conf t
router r
version 2
no au
net 23.23.23.0
net 34.34.34.0
net 3.3.3.0

[R4]
!ne 172.16.0.0 은 보안 상 광고되면 안됨. 하지 않음
!NAT 땜시 뤂백 뚫
conf t
int loopback 0
ip add 11.11.11.11 255.255.255.0
no sh
exit
router r
version 2
no au
net 34.34.34.0
net 11.11.11.0

```
## **4. NAT 설정**
```sh
!문제의 4번째 줄 덕분에 R1, 4만 하면 됨

[R1]
!g0/1 포트의 IP 를 외부 ip로 쓰라 함 + PC 2개 = NAT-PAT 사용. 근데 pool 대신 포트를 넣은.
conf t
access-list 1 permit 192.168.0.0 0.0.0.255
ip nat inside source list 1 int f0/1 overload
int f0/0
ip nat inside
int f0/1
ip nat outside

[R4]
!하나니깐 걍 스테틱 ㄱㄱ
conf t
ip nat inside source static 172.16.0.1 11.11.11.11
int f0/0
ip nat inside
int f0/1
ip nat outside
```


```bash
sudo tee /etc/netplan/50-* > /dev/null << EOF

network:

  version: 2

  ethernets:

    ens33:

      dhcp4: false

      addresses:

        - 192.168.1.1/24

      routes:

        - to: default

          via: 192.168.1.254

      nameservers:

        addresses:

          - 192.168.2.1

EOF
```