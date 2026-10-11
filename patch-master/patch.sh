#!/bin/bash
set -euo pipefail

# 自动生成：OpenWrt Airoha 补丁部署脚本
# 用法：先安装 feeds，再执行 ../patch-master/patch.sh，或显式传入源码根目录

# 获取脚本所在绝对路径，避免相对路径错误
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT="${1:-$(dirname "$SCRIPT_DIR")}"

if [ ! -d "$PROJECT_ROOT/package" ] || [ ! -d "$PROJECT_ROOT/target/linux" ]; then
    echo "错误：目标目录不是完整的 ImmortalWrt 源码树：$PROJECT_ROOT" >&2
    exit 2
fi
if ! grep -Fqx 'KERNEL_PATCHVER:=6.12' "$PROJECT_ROOT/target/linux/airoha/Makefile"; then
    echo "错误：当前 patch-master 尚未移植到非 6.12 内核。" >&2
    exit 3
fi

echo "正在部署补丁到源码目录：$PROJECT_ROOT"
echo "========================================"

# 复制所有修改/新增文件
mkdir -p "$PROJECT_ROOT/."
cp -a "$SCRIPT_DIR/feeds.conf.default" "$PROJECT_ROOT/feeds.conf.default"
mkdir -p "$PROJECT_ROOT/package/base-files/files/etc/uci-defaults"
cp -a "$SCRIPT_DIR/package/base-files/files/etc/uci-defaults/99_fix-airoha-mac" "$PROJECT_ROOT/package/base-files/files/etc/uci-defaults/99_fix-airoha-mac"
cp -a "$SCRIPT_DIR/package/base-files/files/etc/uci-defaults/99-tailscale-safe-defaults" "$PROJECT_ROOT/package/base-files/files/etc/uci-defaults/99-tailscale-safe-defaults"
mkdir -p "$PROJECT_ROOT/package/base-files/files/etc/init.d"
cp -a "$SCRIPT_DIR/package/base-files/files/etc/init.d/tailscale-safe-guard" "$PROJECT_ROOT/package/base-files/files/etc/init.d/tailscale-safe-guard"
mkdir -p "$PROJECT_ROOT/package/boot/uboot-tools/uboot-envtools/files"
cp -a "$SCRIPT_DIR/package/boot/uboot-tools/uboot-envtools/files/mediatek_filogic" "$PROJECT_ROOT/package/boot/uboot-tools/uboot-envtools/files/mediatek_filogic"
mkdir -p "$PROJECT_ROOT/package/kernel/linux/files"
cp -a "$SCRIPT_DIR/package/kernel/linux/files/sysctl-nf-conntrack.conf" "$PROJECT_ROOT/package/kernel/linux/files/sysctl-nf-conntrack.conf"
mkdir -p "$PROJECT_ROOT/package/kernel/linux/modules"
cp -a "$SCRIPT_DIR/package/kernel/linux/modules/netdevices.mk" "$PROJECT_ROOT/package/kernel/linux/modules/netdevices.mk"
mkdir -p "$PROJECT_ROOT/package"
mkdir -p "$PROJECT_ROOT/package/luci-app-airoha-npu"
cp -a "$SCRIPT_DIR/package/luci-app-airoha-npu/." "$PROJECT_ROOT/package/luci-app-airoha-npu/"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/an7581/base-files/etc/board.d"
cp -a "$SCRIPT_DIR/target/linux/airoha/an7581/base-files/etc/board.d/02_network" "$PROJECT_ROOT/target/linux/airoha/an7581/base-files/etc/board.d/02_network"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/an7581"
cp -a "$SCRIPT_DIR/target/linux/airoha/an7581/config-6.12" "$PROJECT_ROOT/target/linux/airoha/an7581/config-6.12"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/an7581"
cp -a "$SCRIPT_DIR/target/linux/airoha/an7581/target.mk" "$PROJECT_ROOT/target/linux/airoha/an7581/target.mk"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/dts"
cp -a "$SCRIPT_DIR/target/linux/airoha/dts/an7581-bell_xg-040g-md.dts" "$PROJECT_ROOT/target/linux/airoha/dts/an7581-bell_xg-040g-md.dts"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/dts"
cp -a "$SCRIPT_DIR/target/linux/airoha/dts/an7581.dtsi" "$PROJECT_ROOT/target/linux/airoha/dts/an7581.dtsi"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/image"
cp -a "$SCRIPT_DIR/target/linux/airoha/image/an7581.mk" "$PROJECT_ROOT/target/linux/airoha/image/an7581.mk"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/patches-6.12"
cp -a "$SCRIPT_DIR/target/linux/airoha/patches-6.12/039-v6.14-cpufreq-airoha-Add-EN7581-CPUFreq-SMCCC-driver.patch" "$PROJECT_ROOT/target/linux/airoha/patches-6.12/039-v6.14-cpufreq-airoha-Add-EN7581-CPUFreq-SMCCC-driver.patch"
mkdir -p "$PROJECT_ROOT/target/linux/airoha/patches-6.12"
cp -a "$SCRIPT_DIR/target/linux/airoha/patches-6.12/040-v6.14-pmdomain-airoha-Add-Airoha-CPU-PM-Domain-support.patch" "$PROJECT_ROOT/target/linux/airoha/patches-6.12/040-v6.14-pmdomain-airoha-Add-Airoha-CPU-PM-Domain-support.patch"
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
mkdir -p "$PROJECT_ROOT/target/linux/generic/hack-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/hack-6.12/400-mtd-spinand-Support-fmsh.patch" "$PROJECT_ROOT/target/linux/generic/hack-6.12/400-mtd-spinand-Support-fmsh.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/pending-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/pending-6.12/600-mtd-spinand-add-skyhigh-robust-read-workaround.patch" "$PROJECT_ROOT/target/linux/generic/pending-6.12/600-mtd-spinand-add-skyhigh-robust-read-workaround.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/pending-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/pending-6.12/675-01-net-export-__dev_fill_forward_path-and-br_fdb_find_rcu.patch" "$PROJECT_ROOT/target/linux/generic/pending-6.12/675-01-net-export-__dev_fill_forward_path-and-br_fdb_find_rcu.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/pending-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/pending-6.12/675-02-nft_flow_offload-add-bridging-support.patch" "$PROJECT_ROOT/target/linux/generic/pending-6.12/675-02-nft_flow_offload-add-bridging-support.patch"
mkdir -p "$PROJECT_ROOT/target/linux/generic/pending-6.12"
cp -a "$SCRIPT_DIR/target/linux/generic/pending-6.12/675-04-nft_flow_offload-add-vlan-passthrough-support.patch" "$PROJECT_ROOT/target/linux/generic/pending-6.12/675-04-nft_flow_offload-add-vlan-passthrough-support.patch"

TAILSCALE_VIEW="$PROJECT_ROOT/feeds/luci/applications/luci-app-tailscale-community/htdocs/luci-static/resources/view/tailscale.js"
TAILSCALE_SETTINGS="$PROJECT_ROOT/feeds/luci/applications/luci-app-tailscale-community/root/etc/init.d/tailscale-settings"
if [ ! -f "$TAILSCALE_VIEW" ] || [ ! -f "$TAILSCALE_SETTINGS" ]; then
    echo "错误：未找到 master 分支的 Tailscale LuCI 安全应用入口，请先安装 feeds。" >&2
    exit 1
fi
if ! grep -Fq 'ui.changes.apply' "$TAILSCALE_VIEW"; then
    echo "错误：当前 Tailscale LuCI 缺少 Save & Apply 自动回滚保护。" >&2
    exit 1
fi

echo "========================================"
echo "✅ 补丁部署完成！请重新编译源码。注：xg-040g-md.config 未被打包，请手动复制。"
