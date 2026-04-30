# NFS 운영 매뉴얼(4.29.1)

이 문서는 Charlie C Zone의 NFS HA 구성을 처음 하는 사람이 순서대로 따라 할 수 있게 정리한 절차서다.

## 1. 전체 구조

- NFS1: `192.168.2.5`
- NFS2: `192.168.2.6`
- NFS VIP: `192.168.2.50`
- NFS 공유 디렉터리: `/share_directory`
- WEB mount 위치: `/opt/tomcat/tomcat-10/webapps/upload`
- 서버 스크립트: `nfs-ha(4.29.1).sh`
- WEB 스크립트: `web-nfs(4.29.1).sh`

NFS 서버는 `keepalived`로 VIP를 옮긴다. WEB 서버는 NFS1/NFS2의 실제 IP가 아니라 VIP인 `192.168.2.50`만 mount한다.

이 버전은 편의 우선 모드다.

- `nfs1` 또는 `nfs2` 계정이 없으면 서버 스크립트가 자동 생성한다.
- NFS export 범위는 `192.168.2.0/24`로 넓게 둔다.
- `/share_directory` 권한은 실습 편의를 위해 `777`로 둔다.
- WEB mount는 NFSv4/TCP를 기본으로 사용한다.
- 자동 rsync는 켜지만, 자동 삭제 동기화는 기본으로 끈다.

>[! danger] 중요: NFS1/NFS2에서 서버 스크립트를 실행한 뒤에는 아래 SSH key 등록을 반드시 한 번 해야 자동 rsync가 동작한다.

```bash
# NFS1에서
sudo -u nfs1 ssh-copy-id nfs2@192.168.2.6

# NFS2에서
sudo -u nfs2 ssh-copy-id nfs1@192.168.2.5
```

## 2. 실행 순서

반드시 이 순서로 실행한다.

준비물:

- NFS1/NFS2/WEB1/WEB2에 각각 접속할 수 있어야 한다.
- 각 서버에서 `sudo`를 사용할 수 있어야 한다.
- `nfs-ha(4.29.1).sh`는 NFS1/NFS2에 있어야 한다.
- `web-nfs(4.29.1).sh`는 WEB1/WEB2에 있어야 한다.

1. NFS1에서 서버 스크립트 실행
2. NFS2에서 서버 스크립트 실행
3. NFS1/NFS2 사이 SSH key 등록
4. WEB1에서 WEB mount 스크립트 실행
5. WEB2에서 WEB mount 스크립트 실행
6. mount와 파일 동기화 확인

## 3. NFS1에서 실행

NFS1 서버에서 실행한다.

```bash
cd '스크립트가 있는 디렉터리'
bash 'nfs-ha(4.29.1).sh'
```

정상적으로 끝나면 다음을 확인한다.

```bash
ip a | grep 192.168.2.50
systemctl status nfs-kernel-server --no-pager
systemctl status keepalived --no-pager
systemctl status cron --no-pager
sudo exportfs -v
df -h /share_directory
```

NFS1이 정상 MASTER이면 `ip a | grep 192.168.2.50`에서 VIP가 보일 수 있다.

## 4. NFS2에서 실행

NFS2 서버에서 실행한다.

```bash
cd '스크립트가 있는 디렉터리'
bash 'nfs-ha(4.29.1).sh'
```

정상적으로 끝나면 다음을 확인한다.

```bash
ip a | grep 192.168.2.50
systemctl status nfs-kernel-server --no-pager
systemctl status keepalived --no-pager
systemctl status cron --no-pager
sudo exportfs -v
df -h /share_directory
```

NFS2는 BACKUP이므로 평상시에는 VIP가 안 보일 수 있다. 이것은 정상이다.

## 5. SSH Key 동기화 설정

서버 스크립트는 `nfs1` 또는 `nfs2` 계정과 SSH key 파일을 만들지만, 상대 서버에 public key를 등록하는 `ssh-copy-id`는 직접 한 번 실행해야 한다.

이 작업을 하지 않으면 NFS mount는 될 수 있지만 자동 rsync 동기화는 동작하지 않는다. `/var/log/nfs-ha-sync.log`에 `skip: SSH key login` 같은 로그가 남을 수 있다.

NFS1에서 실행한다.

```bash
sudo -u nfs1 ssh-copy-id nfs2@192.168.2.6
sudo -u nfs1 ssh -o BatchMode=yes nfs2@192.168.2.6 "test -d /share_directory -a -w /share_directory"
```

NFS2에서 실행한다.

```bash
sudo -u nfs2 ssh-copy-id nfs1@192.168.2.5
sudo -u nfs2 ssh -o BatchMode=yes nfs1@192.168.2.5 "test -d /share_directory -a -w /share_directory"
```

확인 명령에서 비밀번호를 물어보지 않고 바로 끝나야 자동 동기화가 준비된 것이다.

## 6. WEB1/WEB2에서 실행

WEB1과 WEB2 각각에서 실행한다.

```bash
cd '스크립트가 있는 디렉터리'
bash 'web-nfs(4.29.1).sh'
```

이 스크립트는 다음 일을 한다.

- `nfs-common`과 `lsof`를 설치한다.
- `/opt/tomcat/tomcat-10/webapps/upload`를 만든다.
- 기존 local upload 파일이 있으면 `/opt/tomcat/upload-local-backup-날짜`에 백업한다.
- `/etc/fstab`에 `192.168.2.50:/share_directory` mount를 등록한다.
- NFSv4/TCP 옵션으로 직접 mount한다.

WEB에서 정상 확인:

```bash
findmnt --target /opt/tomcat/tomcat-10/webapps/upload
df -h | grep /opt/tomcat/tomcat-10/webapps/upload
mount | grep /opt/tomcat/tomcat-10/webapps/upload
```

정상이라면 mount source가 `192.168.2.50:/share_directory`로 보여야 한다.

## 7. 파일 생성과 동기화 확인

WEB1 또는 WEB2에서 테스트 파일을 만든다.

```bash
echo "nfs test from $(hostname) at $(date)" | sudo tee /opt/tomcat/tomcat-10/webapps/upload/nfs-ha-review-$(hostname)-$(date +%Y%m%d-%H%M%S).txt
```

VIP를 가진 NFS를 확인한다.

```bash
ip a | grep 192.168.2.50
```

VIP가 NFS1에 있으면 NFS1에서 수동 동기화를 실행한다.

```bash
sudo -u nfs1 /usr/local/bin/nfs_ha_sync.sh
```

VIP가 NFS2에 있으면 NFS2에서 수동 동기화를 실행한다.

```bash
sudo -u nfs2 /usr/local/bin/nfs_ha_sync.sh
```

양쪽 NFS에서 파일과 로그를 확인한다.

```bash
ls -la /share_directory
cat /share_directory/nfs-ha-review-*.txt
tail -n 50 /var/log/nfs-ha-sync.log
```

cron도 1분마다 같은 sync script를 실행한다. 수동 sync가 되면 cron sync도 보통 동작한다.

## 8. 삭제 동기화 운영

기본값에서는 삭제 동기화를 하지 않는다.

즉, WEB에서 파일을 삭제해도 반대편 NFS에는 같은 파일이 남아 있을 수 있다. 이 선택은 장애 직후 오래된 NFS가 VIP를 가져갔을 때 정상 파일을 반대편에서 지워버리는 사고를 막기 위한 것이다.

삭제까지 자동으로 미러링해야 한다고 팀에서 결정한 경우에만 NFS1과 NFS2 양쪽에서 아래처럼 sync script 설정만 바꾼다.

이 명령은 `nfs-ha(4.29.1).sh` 전체를 다시 실행하지 않는다. 이미 만들어진 `/usr/local/bin/nfs_ha_sync.sh` 안의 `DELETE_OPT=` 한 줄만 바꾼다.
```
켜기
```
```bash
sudo cp -a /usr/local/bin/nfs_ha_sync.sh "/usr/local/bin/nfs_ha_sync.sh.bak-$(date +%Y%m%d-%H%M%S)"
sudo sed -i 's/^DELETE_OPT=.*/DELETE_OPT="--delete-delay"/' /usr/local/bin/nfs_ha_sync.sh
grep '^DELETE_OPT=' /usr/local/bin/nfs_ha_sync.sh
```

삭제 동기화를 다시 끄려면 NFS1과 NFS2 양쪽에서 아래처럼 실행한다.
```
끄기
```
```bash
sudo cp -a /usr/local/bin/nfs_ha_sync.sh "/usr/local/bin/nfs_ha_sync.sh.bak-$(date +%Y%m%d-%H%M%S)"
sudo sed -i 's/^DELETE_OPT=.*/DELETE_OPT=""/' /usr/local/bin/nfs_ha_sync.sh
grep '^DELETE_OPT=' /usr/local/bin/nfs_ha_sync.sh
```

삭제 동기화를 켜기 전에는 현재 VIP를 가진 NFS가 최신 원본인지 먼저 확인한다.

```bash
ip a | grep 192.168.2.50
ls -la /share_directory
tail -n 50 /var/log/nfs-ha-sync.log
```

방향이 헷갈리거나 장애 직후라면 삭제 동기화를 켜지 않는다.

반대편에 남은 파일을 꼭 지워야 하면 파일명을 직접 확인한 뒤 수동으로 삭제한다.

```bash
ssh nfs2@192.168.2.6 "ls -la /share_directory"
ssh nfs2@192.168.2.6 "rm -f /share_directory/삭제할파일명"
```

NFS1에서 삭제할 때는 주소를 `192.168.2.5`로 바꾼다.

## 9. 장애조치 확인

현재 VIP 소유자를 확인한다.

```bash
ip a | grep 192.168.2.50
```

VIP를 가진 NFS에서 keepalived를 중지한다.

```bash
sudo systemctl stop keepalived
```

반대편 NFS에서 VIP가 이동했는지 확인한다.

```bash
ip a | grep 192.168.2.50
systemctl status keepalived --no-pager
```

WEB에서 mount와 파일 접근을 확인한다.

```bash
findmnt --target /opt/tomcat/tomcat-10/webapps/upload
ls -la /opt/tomcat/tomcat-10/webapps/upload
```

테스트가 끝나면 중지했던 keepalived를 다시 시작한다.

```bash
sudo systemctl start keepalived
```

`nopreempt`를 사용하므로 원래 NFS1이 복구되어도 VIP를 자동으로 다시 가져오지 않을 수 있다. 이것은 정상 동작이다.

## 10. 수동 Failback

NFS1로 VIP를 되돌리고 싶으면 먼저 현재 VIP를 가진 노드가 최신 원본인지 확인한다.

```bash
ip a | grep 192.168.2.50
ls -la /share_directory
tail -n 50 /var/log/nfs-ha-sync.log
```

필요하면 현재 VIP 노드에서 수동 sync를 실행한다.

VIP가 NFS1에 있으면 NFS1에서 실행한다.

```bash
sudo -u nfs1 /usr/local/bin/nfs_ha_sync.sh
```

VIP가 NFS2에 있으면 NFS2에서 실행한다.

```bash
sudo -u nfs2 /usr/local/bin/nfs_ha_sync.sh
```

VIP가 없는 쪽에서 실행하면 sync script는 조용히 종료한다.

방향이 헷갈리면 failback을 하지 않는다.

## 11. Split-Brain 의심 시 대처

양쪽 NFS에서 모두 VIP가 보이면 split-brain이다.

```bash
ip a | grep 192.168.2.50
journalctl -u keepalived -n 80 --no-pager
ping -c 3 192.168.2.5
ping -c 3 192.168.2.6
sudo ufw status verbose
```

대처 순서:

1. WEB 접근을 잠시 멈춘다.
2. 두 NFS 중 최신 파일이 있는 쪽을 정한다.
3. 최신이 아닌 쪽의 keepalived를 중지한다.

```bash
sudo systemctl stop keepalived
```

4. 최신 노드에서 반대편으로 수동 rsync한다.
5. 양쪽 파일이 맞는지 확인한 뒤 keepalived를 다시 시작한다.

Split-brain 상태에서 rsync 방향을 틀리면 파일이 삭제될 수 있다.

## 12. Mount 문제 처리

WEB에서 `Stale file handle`, upload 접근 멈춤, 종료 지연이 보이면 먼저 상태를 확인한다.

```bash
findmnt --target /opt/tomcat/tomcat-10/webapps/upload
mount | grep /opt/tomcat/tomcat-10/webapps/upload
df -h | grep /opt/tomcat/tomcat-10/webapps/upload
```

안전한 remount:

```bash
sudo systemctl stop tomcat
sudo umount /opt/tomcat/tomcat-10/webapps/upload
sudo mount /opt/tomcat/tomcat-10/webapps/upload
sudo systemctl start tomcat
```

`umount`가 busy면 잡고 있는 프로세스를 확인한다.

```bash
sudo lsof +f -- /opt/tomcat/tomcat-10/webapps/upload
```

## 13. 디스크 부족

NFS 서버에서 확인한다.

```bash
df -h /share_directory
du -sh /share_directory
```

디스크가 가득 차면 upload, rsync, health check가 모두 실패할 수 있다. 테스트 파일만 삭제한다.

```bash
sudo rm -f /share_directory/nfs-ha-review-*.txt
```

## 14. 자주 보는 문제

### WEB mount 실패

NFS 서버에서 확인:

```bash
systemctl status nfs-kernel-server --no-pager
sudo exportfs -v
sudo ufw status verbose
```

WEB 서버에서 확인:

```bash
ping -c 3 192.168.2.50
findmnt --target /opt/tomcat/tomcat-10/webapps/upload
```

### 자동 rsync 실패

로그를 확인한다.

```bash
tail -n 50 /var/log/nfs-ha-sync.log
```

`skip: SSH key login`이 보이면 SSH key 등록을 다시 한다.

NFS1에서 실행:

```bash
sudo -u nfs1 ssh-copy-id nfs2@192.168.2.6
```

NFS2에서 실행:

```bash
sudo -u nfs2 ssh-copy-id nfs1@192.168.2.5
```

### VIP가 안 붙음

keepalived 로그를 확인한다.

```bash
journalctl -u keepalived -n 80 --no-pager
sudo ufw status verbose
```

## 15. 한계와 주의사항

- 이 구성은 진짜 무손실 HA가 아니다.
- cron 기반 rsync라 장애 직전 파일은 반대편에 없을 수 있다.
- 기본값에서는 삭제 동기화를 하지 않으므로 삭제된 파일이 반대편 NFS에 남을 수 있다.
- split-brain은 스크립트만으로 완전히 막을 수 없다.
- 같은 파일명을 WEB1/WEB2가 동시에 쓰면 충돌할 수 있다.
- 업로드 중 장애가 나면 부분 파일이나 0바이트 파일이 남을 수 있다.
- `/usr/local/bin/nfs_ha_sync.sh`에서 `DELETE_OPT="--delete-delay"`를 켜면 삭제 파일도 미러링되지만, 잘못된 노드가 원본이 되면 반대편 파일을 지울 수 있다.
- `nopreempt` 때문에 NFS2가 VIP를 계속 들고 있어도 장애가 아니다.
