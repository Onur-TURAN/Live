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