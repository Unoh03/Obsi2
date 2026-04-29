# NFS 운영 매뉴얼(4.29.1)

## 목적

이 문서는 Charlie C Zone의 NFS HA 운영 절차를 정리한다.

- NFS1: `192.168.2.5`
- NFS2: `192.168.2.6`
- NFS VIP: `192.168.2.50`
- 공유 디렉터리: `/share_directory`
- WEB mount 위치: `/opt/tomcat/tomcat-10/webapps/upload`

`nfs-ha(4.29.1).sh`는 keepalived VIP 장애조치와 rsync 자동 동기화를 설정한다.  
`web-nfs(4.29.1).sh`는 WEB 서버가 NFS VIP만 mount하도록 설정한다.

## 정상 상태 확인

NFS1/NFS2에서 확인:

```bash
ip a | grep 192.168.2.50
systemctl status nfs-kernel-server --no-pager
systemctl status keepalived --no-pager
systemctl status cron --no-pager
sudo exportfs -v
df -h /share_directory
tail -n 50 /var/log/nfs-ha-sync.log
```

WEB1/WEB2에서 확인:

```bash
findmnt --target /opt/tomcat/tomcat-10/webapps/upload
df -h | grep /opt/tomcat/tomcat-10/webapps/upload
```

정상이라면 WEB mount source는 `192.168.2.50:/share_directory`여야 한다.

## SSH Key 동기화 설정

자동 rsync는 SSH key 로그인이 되어 있어야 동작한다. NFS1과 NFS2 양쪽에서 한 번씩 설정한다.

NFS1에서:

```bash
sudo -u nfs1 ssh-copy-id nfs2@192.168.2.6
sudo -u nfs1 ssh -o BatchMode=yes nfs2@192.168.2.6 "test -d /share_directory -a -w /share_directory"
```

NFS2에서:

```bash
sudo -u nfs2 ssh-copy-id nfs1@192.168.2.5
sudo -u nfs2 ssh -o BatchMode=yes nfs1@192.168.2.5 "test -d /share_directory -a -w /share_directory"
```

비밀번호를 물어보지 않고 명령이 끝나야 자동 동기화가 준비된 것이다.

## 파일 동기화 확인

WEB에서 테스트 파일 생성:

```bash
echo "nfs test from $(hostname) at $(date)" | sudo tee /opt/tomcat/tomcat-10/webapps/upload/test-$(hostname).txt
```

VIP를 가진 NFS에서 즉시 수동 동기화:

```bash
ip a | grep 192.168.2.50
sudo -u nfs1 /usr/local/bin/nfs_ha_sync.sh
```

VIP가 NFS2에 있으면:

```bash
sudo -u nfs2 /usr/local/bin/nfs_ha_sync.sh
```

양쪽 NFS에서 확인:

```bash
ls -la /share_directory
cat /share_directory/test-*.txt
tail -n 50 /var/log/nfs-ha-sync.log
```

## 삭제 동기화 운영

`nfs-ha(4.29.1).sh`는 기본값으로 삭제 동기화를 하지 않는다.

즉, WEB에서 파일을 삭제해도 반대편 NFS에는 같은 파일이 남아 있을 수 있다.

이렇게 하는 이유는 장애 직후 오래된 NFS가 VIP를 가져간 상태에서 자동 rsync가 실행되면, 아직 반대편에만 남아 있던 최신 파일을 삭제할 수 있기 때문이다.

삭제까지 자동으로 미러링해야 한다고 팀에서 결정한 경우에만 양쪽 NFS에서 아래처럼 다시 설정한다.

```bash
SYNC_DELETE_OPT="--delete-delay" bash 'nfs-ha(4.29.1).sh'
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

## 장애조치 확인

현재 VIP 소유자 확인:

```bash
ip a | grep 192.168.2.50
```

VIP를 가진 NFS에서 keepalived 중지:

```bash
sudo systemctl stop keepalived
```

반대편 NFS에서 VIP가 이동했는지 확인:

```bash
ip a | grep 192.168.2.50
systemctl status keepalived --no-pager
```

WEB에서 mount와 파일 접근 확인:

```bash
findmnt --target /opt/tomcat/tomcat-10/webapps/upload
ls -la /opt/tomcat/tomcat-10/webapps/upload
```

## 수동 Failback 절차

`nopreempt`를 사용하므로 NFS1이 복구되어도 VIP를 자동으로 가져오지 않는다. 이것은 정상 동작이다.

수동으로 NFS1에 VIP를 되돌리고 싶으면 먼저 현재 VIP 보유 노드에서 동기화를 확인한다.

```bash
ip a | grep 192.168.2.50
sudo -u nfs2 /usr/local/bin/nfs_ha_sync.sh
tail -n 50 /var/log/nfs-ha-sync.log
```

NFS1/NFS2의 파일이 맞는지 확인:

```bash
ls -la /share_directory
```

그 다음 현재 VIP를 가진 노드의 keepalived를 잠시 중지하거나, 점검 시간에 양쪽 keepalived를 순서대로 재시작한다.

```bash
sudo systemctl restart keepalived
ip a | grep 192.168.2.50
```

방향이 헷갈리면 수동 failback을 하지 않는다.

## Split-Brain 의심 시 대처

양쪽 NFS에서 모두 VIP가 보이면 split-brain이다.

```bash
ip a | grep 192.168.2.50
journalctl -u keepalived -n 80 --no-pager
ping -c 3 192.168.2.5
ping -c 3 192.168.2.6
sudo ufw status verbose
```

대처:

1. WEB 접근을 잠시 멈춘다.
2. 두 NFS 중 최신 파일이 있는 쪽을 정한다.
3. 최신이 아닌 쪽의 keepalived를 중지한다.

```bash
sudo systemctl stop keepalived
```

4. 최신 노드에서 반대편으로 수동 rsync한다.
5. 양쪽 파일이 맞는지 확인한 뒤 keepalived를 다시 시작한다.

Split-brain 상태에서 rsync 방향을 틀리면 파일이 삭제될 수 있다.

## Stale File Handle 또는 Mount 문제

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

umount가 busy면 잡고 있는 프로세스를 확인한다.

```bash
sudo lsof +f -- /opt/tomcat/tomcat-10/webapps/upload
```

## 디스크 부족

NFS 서버에서 확인:

```bash
df -h /share_directory
du -sh /share_directory
```

디스크가 가득 차면 upload, rsync, health check가 모두 실패할 수 있다. 불필요한 테스트 파일부터 삭제한다.

```bash
sudo rm -f /share_directory/test-*.txt
```

## 한계와 주의사항

- 이 구성은 진짜 무손실 HA가 아니다.
- cron 기반 rsync라 장애 직전 파일은 반대편에 없을 수 있다.
- 기본값에서는 삭제 동기화를 하지 않으므로 삭제된 파일이 반대편 NFS에 남을 수 있다.
- split-brain은 스크립트만으로 완전히 막을 수 없다.
- 같은 파일명을 WEB1/WEB2가 동시에 쓰면 충돌할 수 있다.
- 업로드 중 장애가 나면 부분 파일이나 0바이트 파일이 남을 수 있다.
- `SYNC_DELETE_OPT="--delete-delay"`를 켜면 삭제 파일도 미러링되지만, 잘못된 노드가 원본이 되면 반대편 파일을 지울 수 있다.
- `nopreempt` 때문에 NFS2가 VIP를 계속 들고 있어도 장애가 아니다.
