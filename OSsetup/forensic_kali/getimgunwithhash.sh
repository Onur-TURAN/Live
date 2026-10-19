#!/usr/bin/env bash
# USB hedef -> USB kaynak; Linux + systemd/udev, Bash >= 4.
# Gercek delil icin donanimsal write blocker kullanin.
# Kaynak mount edilmez. Tum disk, hedef dosya sisteminde RAW .img olur.
set -Eeuo pipefail
export LC_ALL=C
umask 077

LOG=/home/biyik/log/scriptresult.txt
RULE=/run/udev/rules.d/99-biyik-imaging.rules
MOUNT=/mnt/biyik-hedef
TARGET= SOURCE= CASEDIR= TIDENT= SIDENT=
FORMAT=0

say() { printf '[%s] %s\n' "$(date -Is)" "$*"; }
die() { say "HATA: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "Eksik komut: $1"; }

inventory() { lsblk -dnrpo NAME,TYPE | awk '$2 == "disk" {print $1}'; }
identity() {
    local dev=$1 name=${1##*/}
    [[ -b "$dev" && -r "/sys/class/block/$name/diskseq" ]] || return 1
    printf '%s:%s:%s\n' "$(readlink -f "/sys/class/block/$name")" \
        "$(cat "/sys/class/block/$name/diskseq")" "$(blockdev --getsize64 "$dev")"
}
same_disk() {
    local current
    current=$(identity "$1") || die "Disk ayrildi: $1"
    [[ "$current" == "$2" ]] || die "Disk kimligi degisti: $1. Yeniden takilan diskte devam edilmez."
}
nodes() { lsblk -nrpo NAME "$1"; }
unused() {
    local disk=$1 node type mm swaps
    swaps=$(swapon --show --noheadings --raw --output NAME)
    while read -r node type; do
        [[ "$type" == disk || "$type" == part ]] || die "$disk uzerinde aktif RAID/LVM/mapper bulundu."
        mm=$(lsblk -dnro MAJ:MIN "$node")
        # Kernel mount tablosu UUID/aygit yolu alias'larindan bagimsiz kontrol edilir.
        if awk -v mm="$mm" '$3 == mm {found=1} END {exit !found}' /proc/self/mountinfo; then
            die "$node zaten mount edilmis. Ozellikle kaynak icin koruma garantisi verilemez; duruldu."
        fi
        if grep -Fxq "$node" <<< "$swaps"; then die "$node aktif swap; duruldu."; fi
        if compgen -G "/sys/class/block/${node##*/}/holders/*" >/dev/null; then
            die "$node baska bir blok aygitinca kullaniliyor."
        fi
    done < <(lsblk -nrpo NAME,TYPE "$disk")
}
readonly_disk() {
    local node
    # Once tum diski, sonra her bolumu kilitle.
    blockdev --setro "$1"
    while read -r node; do blockdev --setro "$node"; done < <(nodes "$1")
    while read -r node; do
        [[ $(blockdev --getro "$node") == 1 ]] || die "RO uygulanamadi: $node"
    done < <(nodes "$1")
}
check_source() {
    local node
    same_disk "$SOURCE" "$SIDENT"
    unused "$SOURCE"
    while read -r node; do
        [[ $(blockdev --getro "$node") == 1 ]] || die "Kaynak RO korumasi kalkmis: $node"
    done < <(nodes "$SOURCE")
}

# BASELINE, daha once var olan tum fiziksel diskleri icerir.
# Birden fazla yeni disk / USB disi aygit gorulurse tahmin yapilmaz.
wait_disk() {
    local prompt=$1 disk
    local -a added=()
    say "$prompt"
    while :; do
        added=()
        while read -r disk; do
            [[ -n "${BASELINE[$disk]+yes}" ]] || added+=("$disk")
        done < <(inventory)
        if (( ${#added[@]} > 1 )); then die "Birden fazla yeni disk var. Tek tek takin."; fi
        if (( ${#added[@]} == 1 )); then
            udevadm settle --timeout=30 || die "udev islemleri tamamlanamadi."
            sleep 2
            # USB coklu LUN ve gec gelen aygitlari yeniden kontrol et.
            added=()
            while read -r disk; do
                [[ -n "${BASELINE[$disk]+yes}" ]] || added+=("$disk")
            done < <(inventory)
            (( ${#added[@]} == 1 )) || die "Yeni aygit sayisi degisti."
            NEW_DISK=${added[0]}
            [[ $(lsblk -dnro TRAN "$NEW_DISK") == usb ]] || die "Yalniz USB disk destekleniyor: $NEW_DISK"
            unused "$NEW_DISK"
            readonly_disk "$NEW_DISK"
            BASELINE["$NEW_DISK"]=1
            lsblk -b -o NAME,SIZE,MODEL,SERIAL,TRAN,RO,FSTYPE,MOUNTPOINTS "$NEW_DISK"
            udevadm info --query=property --name="$NEW_DISK"
            return
        fi
        sleep 1
    done
}

hash_file() {
    # sha256sum hata verirse bos/kismi bir hash kabul edilmez.
    local result
    result=$(sha256sum -- "$1") || die "SHA-256 okunamadi: $1"
    HASH=${result%% *}
    [[ "$HASH" =~ ^[0-9a-f]{64}$ ]] || die "Gecersiz SHA-256: $1"
}

finish() {
    local rc=$?
    trap - EXIT ERR INT TERM
    set +e
    say "Script cikis kodu: $rc"
    say "Kaynak salt okunur birakildi; USB koruma kurali ve udisks2 maskesi yeniden baslatmaya kadar kalir."
    say "Yerel log: $LOG"
    if [[ -n "$CASEDIR" ]]; then
        say "Hedefteki vaka klasoru: $CASEDIR"
        say "Hedef bagli kalir. Guvenli cikarma: sudo umount $MOUNT"
    fi
    # Tee'nin tum ciktiyi diske yazmasini bekle; sonra logun tam kopyasini al.
    exec 1>&3 2>&4
    wait "$TEE_PID"
    if [[ -n "$CASEDIR" ]] && mountpoint -q "$MOUNT"; then
        if [[ "$(identity "$TARGET")" == "$TIDENT" ]]; then
            if ! cp -- "$LOG" "$CASEDIR/scriptresult.txt"; then
                printf 'HATA: Log hedefe kopyalanamadi.\n' | tee -a "$LOG" >&2
                rc=1
            fi
            sync -f "$MOUNT" || rc=1
        else
            printf 'HATA: Hedef ayrildi/degisti; log sadece yerel konumda.\n' | tee -a "$LOG" >&2
            rc=1
        fi
    fi
    exit "$rc"
}

main() {
    case "${1:-}" in
        '') ;;
        --format-target) FORMAT=1 ;;
        --help|-h)
            printf 'Kullanim: sudo bash disk-imaj.sh [--format-target]\nIki USB diski de baslangicta cikarin. Once buyuk hedef, istenince kucuk kaynak.\n--format-target: ilk diskin TAMAMINI silip GPT/ext4 hazirlar; ekranda SIL /dev/... onayi ister.\n'
            return ;;
        *) die "Bilinmeyen secenek: $1" ;;
    esac
    (( $# <= 1 )) || die "Fazla arguman."
    (( EUID == 0 )) || die "sudo bash disk-imaj.sh ile calistirin."
    [[ -d /run/systemd/system ]] || die "systemd tabanli Linux live ortam gerekli."
    local cmd disk node fs answer bytes free himage targetpart opts
    local -a parts=()
    for cmd in lsblk blockdev udevadm systemctl sha256sum dc3dd mount umount \
        mountpoint findmnt swapon awk grep tee flock df stat sync cp readlink; do need "$cmd"; done
    if (( FORMAT )); then for cmd in parted partprobe wipefs mkfs.ext4; do need "$cmd"; done; fi
    exec 9>/run/biyik-imaging.lock
    flock -n 9 || die "Baska bir script zaten calisiyor."
    mkdir -p /home/biyik/log
    [[ ! -L "$LOG" ]] || die "Log yolu sembolik bag olamaz."
    touch "$LOG"
    exec 3>&1 4>&2
    exec > >(tee -a "$LOG") 2>&1
    TEE_PID=$!
    trap finish EXIT
    trap 'say "HATA: Satir $LINENO, komut: $BASH_COMMAND"' ERR
    trap 'exit 130' INT
    trap 'exit 143' TERM
    say "===== YENI OTURUM ====="
    uname -a
    dc3dd --version
    say "Yazilimsal koruma, donanimsal write blocker yerine gecmez."
    say "Iki test diskini de CIKARIN. Live USB yerinde kalsin. Hazir olunca Enter."
    read -r answer </dev/tty
    declare -gA BASELINE=()
    while read -r disk; do BASELINE["$disk"]=1; done < <(inventory)
    lsblk -b -o NAME,SIZE,MODEL,SERIAL,TRAN,RO,FSTYPE,MOUNTPOINTS

    # Kural DISK TAKILMADAN ONCE kurulur. USB bolumleri de eslesir.
    # RUN erken kernel/udev erisimlerine karsi donanimsal bir engel degildir.
    mkdir -p /run/udev/rules.d
    local blockdev_path
    blockdev_path=$(command -v blockdev)
    cat > "$RULE" <<EOF
# biyik disk-imaj: reboot removes this runtime rule
SUBSYSTEM=="block", SUBSYSTEMS=="usb", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_AUTO}="0"
ACTION=="add", SUBSYSTEM=="block", SUBSYSTEMS=="usb", RUN+="$blockdev_path --setro /dev/%k"
EOF
    udevadm control --reload-rules
    systemctl mask --runtime --now udisks2.service
    if systemctl is-active --quiet udisks2.service; then die "udisks2 durdurulamadi."; fi
    udevadm settle --timeout=30
    say "USB RO kurali yuklendi; udisks2 kapatildi."

    wait_disk "SIMDI yalniz 1 TB HEDEF diski takin."
    TARGET=$NEW_DISK
    TIDENT=$(identity "$TARGET")
    say "HEDEF: $TARGET; kimlik: $TIDENT"
    say "Bu diskin HEDEF oldugunu model/seri ile kontrol edin. Devam icin HEDEF yazin:"
    read -r answer </dev/tty
    [[ "$answer" == HEDEF ]] || die "Hedef secimi iptal edildi."
    same_disk "$TARGET" "$TIDENT"
    unused "$TARGET"

    if (( FORMAT )); then
        say "DIKKAT: $TARGET diskindeki TUM bolumler/veriler silinecek. Onay icin SIL $TARGET yazin:"
        read -r answer </dev/tty
        [[ "$answer" == "SIL $TARGET" ]] || die "Format iptal edildi."
        same_disk "$TARGET" "$TIDENT"
        unused "$TARGET"
        while read -r node; do blockdev --setrw "$node"; done < <(nodes "$TARGET")
        wipefs --all "$TARGET"
        parted --script "$TARGET" mklabel gpt mkpart primary ext4 1MiB 100%
        partprobe "$TARGET"
        udevadm settle --timeout=30
    fi
    while read -r node; do
        fs=$(lsblk -dnro FSTYPE "$node")
        if (( FORMAT )) || [[ "$fs" =~ ^(ext4|ntfs|exfat)$ ]]; then parts+=("$node"); fi
    done < <(lsblk -nrpo NAME,TYPE "$TARGET" | awk '$2 == "part" {print $1}')
    # Bolum tablosuz, dogrudan disk uzerindeki dosya sistemi de desteklenir.
    if (( ! FORMAT && ${#parts[@]} == 0 )); then
        fs=$(lsblk -dnro FSTYPE "$TARGET")
        if [[ "$fs" =~ ^(ext4|ntfs|exfat)$ ]]; then parts+=("$TARGET"); fi
    fi
    (( ${#parts[@]} == 1 )) || die "Hedefte tek bir ext4/NTFS/exFAT veri alani gerekli. Bos disk icin --format-target kullanin."
    targetpart=${parts[0]}
    same_disk "$TARGET" "$TIDENT"
    unused "$TARGET"
    blockdev --setrw "$TARGET"
    blockdev --setrw "$targetpart"
    if (( FORMAT )); then mkfs.ext4 -F -L BIYIK_IMAGE "$targetpart"; fi
    mkdir -p "$MOUNT"
    mountpoint -q "$MOUNT" && die "$MOUNT zaten kullanimda."
    fs=$(lsblk -dnro FSTYPE "$targetpart")
    if [[ "$fs" == ntfs ]]; then
        need ntfs-3g
        mount -t ntfs-3g -o rw,norecover,nodev,nosuid,noexec "$targetpart" "$MOUNT"
    else
        mount -t "$fs" -o rw,nodev,nosuid,noexec "$targetpart" "$MOUNT"
    fi
    opts=$(findmnt -nro OPTIONS --target "$MOUNT")
    [[ ",$opts," == *,rw,* ]] || die "Hedef RW mount edilemedi."
    CASEDIR=$(mktemp -d "$MOUNT/case-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")
    say "Hedef RW baglandi: $targetpart -> $MOUNT"

    wait_disk "SIMDI 300 GB KAYNAK diski takin. Hedefi cikarmayin."
    SOURCE=$NEW_DISK
    SIDENT=$(identity "$SOURCE")
    say "KAYNAK: $SOURCE; kimlik: $SIDENT"
    [[ "$SOURCE" != "$TARGET" ]] || die "Kaynak ve hedef ayni."
    check_source
    same_disk "$TARGET" "$TIDENT"
    bytes=$(blockdev --getsize64 "$SOURCE")
    (( bytes < $(blockdev --getsize64 "$TARGET") )) || die "Bu senaryoda kaynak hedef diskten kucuk olmali; sira hatasi olabilir."
    free=$(df -B1 --output=avail "$MOUNT" | awk 'NR==2 {print $1}')
    (( free >= bytes + 1073741824 )) || die "Hedefte kaynak boyutu + 1 GiB bos alan gerekli."
    say "Kaynak MOUNT EDILMEDI; disk ve tum bolumleri RO. Kaynak boyutu: $bytes bayt."
    say "On/son kaynak hash taramasi YOK. Dogrudan imaj alinacak; SHA-256 kopyalama sirasinda hesaplanacak."
    check_source
    same_disk "$TARGET" "$TIDENT"
    say "dc3dd ile tum disk imaji aliniyor..."
    # rec=off: bozuk sektorleri sessizce sifirlamak yerine dur.
    dc3dd "if=$SOURCE" "hof=$CASEDIR/disk.img" hash=sha256 rec=off \
        "log=$CASEDIR/dc3dd.log"
    sync -f "$CASEDIR/disk.img"
    [[ $(stat -c %s "$CASEDIR/disk.img") == "$bytes" ]] || die "Imaj boyutu kaynakla uyusmuyor."
    check_source
    same_disk "$TARGET" "$TIDENT"
    say "Imaj SHA-256 bagimsiz hesaplaniyor..."
    hash_file "$CASEDIR/disk.img"; himage=$HASH
    say "IMAGE_SHA256=$himage"
    check_source
    same_disk "$TARGET" "$TIDENT"
    printf '%s  disk.img\n' "$himage" > "$CASEDIR/SHA256SUMS"
    say "SONUC: BASARILI. dc3dd imaj alma/dogrulama tamamlandi; imaj SHA-256 kaydedildi."
    say "Kaynak oncesi/sonrasi hash karsilastirmasi YAPILMADI; kaynagin zaman icinde degismedigi bu yontemle kanitlanmaz."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
