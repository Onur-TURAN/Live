#!/usr/bin/env bash
# Onceden takili USB disklerden kullanici secimi; Linux + systemd/udev, Bash >= 4.
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
declare -a CANDIDATES=() CANDIDATE_IDS=()

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

# Mount/swap/holder kullanan diskler (live USB dahil) aday olamaz.
build_candidates() {
    local disk ident size
    CANDIDATES=(); CANDIDATE_IDS=()
    while read -r disk; do
        [[ $(lsblk -dnro TRAN "$disk") == usb ]] || continue
        size=$(blockdev --getsize64 "$disk") || continue
        [[ "$size" =~ ^[0-9]+$ ]] && (( size > 0 )) || continue
        if ! (unused "$disk") >/dev/null 2>&1; then
            say "Secim disi (mount/swap/aktif kullanim): $disk"
            continue
        fi
        ident=$(identity "$disk") || continue
        CANDIDATES+=("$disk"); CANDIDATE_IDS+=("$ident")
    done < <(inventory)
    (( ${#CANDIDATES[@]} >= 2 )) || die "En az iki takili, mount edilmemis USB disk gerekli. lsblk ile baglantilari kontrol edin."
}
read_choice() { read -r CHOICE </dev/tty; }
select_disk() {
    local role=$1 exclude=${2:-} i index
    say "$role diskini BOYUT, MODEL ve SERI bilgilerine gore secin:"
    for i in "${!CANDIDATES[@]}"; do
        [[ "${CANDIDATES[$i]}" == "$exclude" ]] && continue
        printf '\n[%s]\n' "$((i+1))"
        lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN,RO "${CANDIDATES[$i]}"
    done
    while :; do
        say "$role icin listedeki numarayi girin (iptal: q):"
        read_choice || die "Secim okunamadi."
        [[ "$CHOICE" != q ]] || die "Kullanici iptal etti."
        if [[ ! "$CHOICE" =~ ^[1-9][0-9]{0,3}$ ]]; then say "Gecersiz numara."; continue; fi
        index=$((10#$CHOICE - 1))
        if (( index >= ${#CANDIDATES[@]} )); then say "Listede bu numara yok."; continue; fi
        SELECTED=${CANDIDATES[$index]}
        [[ "$SELECTED" != "$exclude" ]] || { say "Kaynak ve hedef ayni olamaz."; continue; }
        SELECTED_ID=${CANDIDATE_IDS[$index]}
        same_disk "$SELECTED" "$SELECTED_ID"
        unused "$SELECTED"
        return
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
    say "Uygulanan USB koruma kurali ve udisks2 maskesi otomatik kaldirilmaz."
    say "Yerel log: $LOG"
    if [[ -n "$CASEDIR" ]]; then
        say "Hedefteki vaka klasoru: $CASEDIR"
        say "Disk baglantisi kopmadiysa hedef bagli birakilir. Guvenli cikarma: sudo umount $MOUNT"
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
            printf 'Kullanim: sudo bash disk-imaj.sh [--format-target]\nForensic modda acin; iki USB diski takin, mount etmeden scripti baslatin.\nListeden once KAYNAK sonra HEDEF numarasini secin.\n--format-target: secilen HEDEFIN TAMAMINI siler; SIL /dev/... onayi ister.\n'
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
    say "Onceden takili disklerden secim yapilacak. Diskleri cikarmayin; kaynak bolumlerini mount etmeyin."
    say "Script baslamadan onceki erisimler bu script tarafindan korunamaz; forensic mod/write blocker gereklidir."
    lsblk -b -o NAME,SIZE,MODEL,SERIAL,TRAN,RO,FSTYPE,MOUNTPOINTS

    # Kural sonraki USB add olaylarini kapsar; mevcut kaynak asagida kilitlenir.
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

    mountpoint -q "$MOUNT" && die "$MOUNT zaten bagli. Aktif islem yoksa once sudo umount $MOUNT uygulayin; sonra tekrar baslatin."
    build_candidates
    select_disk KAYNAK
    SOURCE=$SELECTED
    SIDENT=$SELECTED_ID
    readonly_disk "$SOURCE"
    check_source
    say "KAYNAK (RO): $SOURCE; kimlik: $SIDENT"
    udevadm info --query=property --name="$SOURCE"
    select_disk HEDEF "$SOURCE"
    TARGET=$SELECTED
    TIDENT=$SELECTED_ID
    check_source
    say "HEDEF: $TARGET; kimlik: $TIDENT"
    udevadm info --query=property --name="$TARGET"
    say "Secim ozeti: KAYNAK $SOURCE -> HEDEF $TARGET icinde disk.img"
    lsblk -d -o NAME,SIZE,MODEL,SERIAL,RO "$SOURCE" "$TARGET"
    say "Bu diskin HEDEF oldugunu model/seri ile kontrol edin. Devam icin HEDEF yazin:"
    read -r answer </dev/tty
    [[ "$answer" == HEDEF ]] || die "Hedef secimi iptal edildi."
    same_disk "$TARGET" "$TIDENT"
    unused "$TARGET"
    check_source
    bytes=$(blockdev --getsize64 "$SOURCE")
    (( bytes < $(blockdev --getsize64 "$TARGET") )) || die "Hedef disk kaynak imajini ve dosya sistemini barindiracak kadar buyuk olmali."

    if (( FORMAT )); then
        say "DIKKAT: $TARGET diskindeki TUM bolumler/veriler silinecek. Onay icin SIL $TARGET yazin:"
        read -r answer </dev/tty
        [[ "$answer" == "SIL $TARGET" ]] || die "Format iptal edildi."
        same_disk "$TARGET" "$TIDENT"
        unused "$TARGET"
        check_source
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

    [[ "$SOURCE" != "$TARGET" ]] || die "Kaynak ve hedef ayni."
    check_source
    same_disk "$TARGET" "$TIDENT"
    bytes=$(blockdev --getsize64 "$SOURCE")
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
