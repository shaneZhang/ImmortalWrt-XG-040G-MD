#!/bin/bash
set -euo pipefail

# 自动生成：OpenWrt Airoha 补丁部署脚本
# 用法：先安装 feeds，再执行 ../patch-25.12/patch.sh，或显式传入源码根目录

# 获取脚本所在绝对路径，避免相对路径错误
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT="${1:-$(dirname "$SCRIPT_DIR")}"

if [ ! -d "$PROJECT_ROOT/package" ] || [ ! -d "$PROJECT_ROOT/target/linux" ]; then
    echo "错误：目标目录不是完整的 ImmortalWrt 源码树：$PROJECT_ROOT" >&2
    exit 2
fi
if ! grep -Fqx 'KERNEL_PATCHVER:=6.12' "$PROJECT_ROOT/target/linux/airoha/Makefile"; then
    echo "错误：patch-25.12 仅支持 Linux 6.12 源码树。" >&2
    exit 3
fi

echo "正在部署补丁到源码目录：$PROJECT_ROOT"
echo "========================================"

# Ninja 1.13.2 的原始 configure.py 不支持 --no-rebuild。官方源码补丁未生效时，
# 该参数会让 host ninja 在配置阶段直接退出；移除它只会多执行一次自举重编译。
NINJA_MAKEFILE="$PROJECT_ROOT/tools/ninja/Makefile"
NINJA_BUILD_FIX="$SCRIPT_DIR/patches/openwrt/001-tools-ninja-drop-no-rebuild.patch"
if [ -f "$NINJA_MAKEFILE" ] && \
   grep -Fqx 'PKG_VERSION:=1.13.2' "$NINJA_MAKEFILE" && \
   grep -Fq -- '--no-rebuild' "$NINJA_MAKEFILE"; then
    patch --batch --forward -p1 -d "$PROJECT_ROOT" < "$NINJA_BUILD_FIX"
fi
if [ -f "$NINJA_MAKEFILE" ] && \
   grep -Fqx 'PKG_VERSION:=1.13.2' "$NINJA_MAKEFILE" && \
   grep -Fq -- '--no-rebuild' "$NINJA_MAKEFILE"; then
    echo "错误：Ninja 1.13.2 构建兼容补丁未生效。" >&2
    exit 1
fi

LIBTOOL_MAKEFILE="$PROJECT_ROOT/tools/libtool/Makefile"
LIBTOOL_BUILD_FIX="$SCRIPT_DIR/patches/openwrt/002-tools-libtool-preserve-configured-makefile.patch"
if [ -f "$LIBTOOL_MAKEFILE" ] && \
   grep -Fqx 'PKG_VERSION:=2.5.4' "$LIBTOOL_MAKEFILE" && \
   sed -n '/^define Host\/Configure$/,/^endef$/p' "$LIBTOOL_MAKEFILE" | \
       grep -Fq '$(call Host/Uninstall)'; then
    patch --batch --forward -p1 -d "$PROJECT_ROOT" < "$LIBTOOL_BUILD_FIX"
fi
if [ -f "$LIBTOOL_MAKEFILE" ] && \
   grep -Fqx 'PKG_VERSION:=2.5.4' "$LIBTOOL_MAKEFILE" && \
   sed -n '/^define Host\/Configure$/,/^endef$/p' "$LIBTOOL_MAKEFILE" | \
       grep -Fq '$(call Host/Uninstall)'; then
    echo "错误：libtool 2.5.4 构建兼容补丁未生效。" >&2
    exit 1
fi

# OpenWrt 的 SHELL 可能是带参数的 "/usr/bin/env bash"。libtool 2.5.4 会在
# 生成规则中把 CONFIG_SHELL 单引号包裹，导致它被当成一个不存在的可执行路径。
LIBTOOL_SHELL_FIX="$SCRIPT_DIR/patches/openwrt/003-tools-libtool-use-single-path-config-shell.patch"
if [ -f "$LIBTOOL_MAKEFILE" ] && \
   grep -Fqx 'PKG_VERSION:=2.5.4' "$LIBTOOL_MAKEFILE" && \
   ! grep -Fq 'CONFIG_SHELL="/bin/bash"' "$LIBTOOL_MAKEFILE"; then
    patch --batch --forward -p1 -d "$PROJECT_ROOT" < "$LIBTOOL_SHELL_FIX"
fi
if [ -f "$LIBTOOL_MAKEFILE" ] && \
   grep -Fqx 'PKG_VERSION:=2.5.4' "$LIBTOOL_MAKEFILE" && \
   ! grep -Fq 'CONFIG_SHELL="/bin/bash"' "$LIBTOOL_MAKEFILE"; then
    echo "错误：libtool 2.5.4 CONFIG_SHELL 兼容补丁未生效。" >&2
    exit 1
fi

DOSFSTOOLS_MAKEFILE="$PROJECT_ROOT/tools/dosfstools/Makefile"
DOSFSTOOLS_BUILD_FIX="$SCRIPT_DIR/patches/openwrt/005-tools-dosfstools-skip-missing-m4-dir.patch"
if [ -f "$DOSFSTOOLS_MAKEFILE" ] && \
   grep -Fqx 'PKG_VERSION:=4.2' "$DOSFSTOOLS_MAKEFILE" && \
   ! grep -Fqx 'HOST_MACRO_PATHS:=' "$DOSFSTOOLS_MAKEFILE"; then
    patch --batch --forward -p1 -d "$PROJECT_ROOT" < "$DOSFSTOOLS_BUILD_FIX"
fi
if [ -f "$DOSFSTOOLS_MAKEFILE" ] && \
   grep -Fqx 'PKG_VERSION:=4.2' "$DOSFSTOOLS_MAKEFILE" && \
   ! grep -Fqx 'HOST_MACRO_PATHS:=' "$DOSFSTOOLS_MAKEFILE"; then
    echo "错误：dosfstools 4.2 autoreconf 兼容补丁未生效。" >&2
    exit 1
fi

GOLANG_PACKAGE_MK="$PROJECT_ROOT/feeds/packages/lang/golang/golang-package.mk"
GOLANG_BUILD_FIX="$SCRIPT_DIR/patches/openwrt/004-golang-disable-vcs-stamping.patch"
if [ ! -f "$GOLANG_PACKAGE_MK" ]; then
    echo "错误：未找到 golang-package.mk，请先安装 feeds。" >&2
    exit 1
fi
if ! grep -Fqx $'\tGOFLAGS=-buildvcs=false \\' "$GOLANG_PACKAGE_MK"; then
    patch --batch --forward -p1 -d "$PROJECT_ROOT/feeds/packages" < "$GOLANG_BUILD_FIX"
fi
if ! grep -Fqx $'\tGOFLAGS=-buildvcs=false \\' "$GOLANG_PACKAGE_MK"; then
    echo "错误：Go 1.26 VCS stamping 兼容补丁未生效。" >&2
    exit 1
fi

# 1. 删除废弃的旧文件
rm -f "$PROJECT_ROOT/target/linux/airoha/patches-6.12/910-02-v7.0-net-airoha-npu-Add-the-capability-to-read-firmware-n.patch"

# 2. 复制所有修改/新增文件
cp -a "$SCRIPT_DIR/feeds.conf.default" "$PROJECT_ROOT/feeds.conf.default"
mkdir -p "$PROJECT_ROOT/package/boot/uboot-tools/uboot-envtools/files"
cp -a "$SCRIPT_DIR/package/boot/uboot-tools/uboot-envtools/files/mediatek_filogic" "$PROJECT_ROOT/package/boot/uboot-tools/uboot-envtools/files/mediatek_filogic"
mkdir -p "$PROJECT_ROOT/package/kernel/linux/files"
cp -a "$SCRIPT_DIR/package/kernel/linux/files/sysctl-nf-conntrack.conf" "$PROJECT_ROOT/package/kernel/linux/files/sysctl-nf-conntrack.conf"
mkdir -p "$PROJECT_ROOT/package/kernel/linux/modules"
cp -a "$SCRIPT_DIR/package/kernel/linux/modules/netdevices.mk" "$PROJECT_ROOT/package/kernel/linux/modules/netdevices.mk"
mkdir -p "$PROJECT_ROOT/package/base-files/files/etc/uci-defaults"
cp -a "$SCRIPT_DIR/package/base-files/files/etc/uci-defaults/99-tailscale-safe-defaults" "$PROJECT_ROOT/package/base-files/files/etc/uci-defaults/99-tailscale-safe-defaults"
mkdir -p "$PROJECT_ROOT/package/base-files/files/etc/init.d"
cp -a "$SCRIPT_DIR/package/base-files/files/etc/init.d/tailscale-safe-guard" "$PROJECT_ROOT/package/base-files/files/etc/init.d/tailscale-safe-guard"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/an7581/base-files/etc/board.d"
cp -a "$SCRIPT_DIR/target/linux/airoha/an7581/base-files/etc/board.d/02_network" "$PROJECT_ROOT/target/linux/airoha/an7581/base-files/etc/board.d/02_network"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/an7581"
cp -a "$SCRIPT_DIR/target/linux/airoha/an7581/config-6.12" "$PROJECT_ROOT/target/linux/airoha/an7581/config-6.12"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/an7581"
cp -a "$SCRIPT_DIR/target/linux/airoha/an7581/target.mk" "$PROJECT_ROOT/target/linux/airoha/an7581/target.mk"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/dts"
cp -a "$SCRIPT_DIR/target/linux/airoha/dts/an7581.dtsi" "$PROJECT_ROOT/target/linux/airoha/dts/an7581.dtsi"
cp -a "$SCRIPT_DIR/target/linux/airoha/dts/an7581-npu-mt7996.dtsi" "$PROJECT_ROOT/target/linux/airoha/dts/an7581-npu-mt7996.dtsi"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/image"
cp -a "$SCRIPT_DIR/target/linux/airoha/image/an7581.mk" "$PROJECT_ROOT/target/linux/airoha/image/an7581.mk"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/patches-6.12"
cp -a "$SCRIPT_DIR/target/linux/airoha/patches-6.12/039-v6.14-cpufreq-airoha-Add-EN7581-CPUFreq-SMCCC-driver.patch" "$PROJECT_ROOT/target/linux/airoha/patches-6.12/039-v6.14-cpufreq-airoha-Add-EN7581-CPUFreq-SMCCC-driver.patch"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/patches-6.12"
cp -a "$SCRIPT_DIR/target/linux/airoha/patches-6.12/040-v6.14-pmdomain-airoha-Add-Airoha-CPU-PM-Domain-support.patch" "$PROJECT_ROOT/target/linux/airoha/patches-6.12/040-v6.14-pmdomain-airoha-Add-Airoha-CPU-PM-Domain-support.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/hack-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/hack-6.12/400-mtd-spinand-Support-fmsh.patch" "$PROJECT_ROOT/target/linux/generic/hack-6.12/400-mtd-spinand-Support-fmsh.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/pending-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/pending-6.12/487-mtd-spinand-Add-support-for-Etron-EM73D044VCx.patch" "$PROJECT_ROOT/target/linux/generic/pending-6.12/487-mtd-spinand-Add-support-for-Etron-EM73D044VCx.patch"
mkdir -p "$PROJECT_ROOT/package/base-files/files/etc/uci-defaults"
cp -a "$SCRIPT_DIR/package/base-files/files/etc/uci-defaults/99_fix-airoha-mac" "$PROJECT_ROOT/package/base-files/files/etc/uci-defaults/99_fix-airoha-mac"
mkdir -p "$PROJECT_ROOT/package"
mkdir -p "$PROJECT_ROOT/package/luci-app-airoha-npu"
cp -a "$SCRIPT_DIR/package/luci-app-airoha-npu/." "$PROJECT_ROOT/package/luci-app-airoha-npu/"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/dts"
cp -a "$SCRIPT_DIR/target/linux/airoha/dts/an7581-bell_xg-040g-md.dts" "$PROJECT_ROOT/target/linux/airoha/dts/an7581-bell_xg-040g-md.dts"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/patches-6.12"
cp -a "$SCRIPT_DIR/target/linux/airoha/patches-6.12/117-03-airoha_npu_eagle_add_ser.patch" "$PROJECT_ROOT/target/linux/airoha/patches-6.12/117-03-airoha_npu_eagle_add_ser.patch"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/patches-6.12"
cp -a "$SCRIPT_DIR/target/linux/airoha/patches-6.12/620-net-pcs-airoha-fix-USXGMII-rate-adaptation-on-speed.patch" "$PROJECT_ROOT/target/linux/airoha/patches-6.12/620-net-pcs-airoha-fix-USXGMII-rate-adaptation-on-speed.patch"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/patches-6.12"
cp -a "$SCRIPT_DIR/target/linux/airoha/patches-6.12/621-net-pcs-airoha-AN7581-add-global-digital-reset-for.patch" "$PROJECT_ROOT/target/linux/airoha/patches-6.12/621-net-pcs-airoha-AN7581-add-global-digital-reset-for.patch"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/patches-6.12"
cp -a "$SCRIPT_DIR/target/linux/airoha/patches-6.12/910-02-usb-pcie.patch" "$PROJECT_ROOT/target/linux/airoha/patches-6.12/910-02-usb-pcie.patch"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/patches-6.12"
cp -a "$SCRIPT_DIR/target/linux/airoha/patches-6.12/999-dsa-01-add-mt7531-netlink-support.patch" "$PROJECT_ROOT/target/linux/airoha/patches-6.12/999-dsa-01-add-mt7531-netlink-support.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/backport-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/backport-6.12/430-v6.14-mtd-spinand-Introduce-a-way-to-avoid-raw-access.patch" "$PROJECT_ROOT/target/linux/generic/backport-6.12/430-v6.14-mtd-spinand-Introduce-a-way-to-avoid-raw-access.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/backport-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/backport-6.12/431-v6.14-mtd-spinand-Add-support-for-SkyHigh-S35ML-3-family.patch" "$PROJECT_ROOT/target/linux/generic/backport-6.12/431-v6.14-mtd-spinand-Add-support-for-SkyHigh-S35ML-3-family.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/pending-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/pending-6.12/600-mtd-spinand-add-skyhigh-robust-read-workaround.patch" "$PROJECT_ROOT/target/linux/generic/pending-6.12/600-mtd-spinand-add-skyhigh-robust-read-workaround.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/pending-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/pending-6.12/675-01-net-export-__dev_fill_forward_path-and-br_fdb_find_rcu.patch" "$PROJECT_ROOT/target/linux/generic/pending-6.12/675-01-net-export-__dev_fill_forward_path-and-br_fdb_find_rcu.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/pending-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/pending-6.12/675-02-nft_flow_offload-add-bridging-support.patch" "$PROJECT_ROOT/target/linux/generic/pending-6.12/675-02-nft_flow_offload-add-bridging-support.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/pending-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/pending-6.12/675-04-nft_flow_offload-add-vlan-passthrough-support.patch" "$PROJECT_ROOT/target/linux/generic/pending-6.12/675-04-nft_flow_offload-add-vlan-passthrough-support.patch"

TAILSCALE_RPC="$PROJECT_ROOT/feeds/luci/applications/luci-app-tailscale-community/root/usr/share/rpcd/ucode/tailscale.uc"
TAILSCALE_PATCH="$SCRIPT_DIR/patches/luci/001-tailscale-safe-settings.patch"
if [ ! -f "$TAILSCALE_RPC" ]; then
    echo "错误：未找到 openwrt-25.12 分支的 Tailscale LuCI RPC，请先安装 feeds。" >&2
    exit 1
fi
if ! grep -Fq 'Accept Routes is disabled on this firmware' "$TAILSCALE_RPC"; then
    patch --batch --forward -p1 -d "$PROJECT_ROOT/feeds/luci" < "$TAILSCALE_PATCH"
fi
if ! grep -Fq 'Only nftables firewall mode is supported on this firmware' "$TAILSCALE_RPC" || \
   ! grep -Fq 'Accept Routes is disabled on this firmware' "$TAILSCALE_RPC"; then
    echo "错误：Tailscale 25.12 安全校验补丁未生效。" >&2
    exit 1
fi

echo "========================================"
echo "✅ 补丁部署完成！请重新编译源码。"
