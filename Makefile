include config.mk

.local/src/bootc/arch/build:
	podman build -f $(shell dirname $(@))/Containerfile -t "${IMAGE_NAME}:${IMAGE_TAG}" .

bootable.img:
	fallocate -l 100G "./bootable.img"

to-disk: bootable.img .local/src/bootc/arch/build
	IMAGE_NAME=${IMAGE_NAME} IMAGE_TAG=${IMAGE_TAG} .local/bin/podman-bootc install to-disk --allow-missing-verity --composefs-backend --via-loopback /data/bootable.img --filesystem ${FILESYSTEM} --wipe --bootloader systemd

to-filesystem: .local/src/bootc/arch/build
	IMAGE_NAME=${IMAGE_NAME} IMAGE_TAG=${IMAGE_TAG} .local/bin/podman-bootc install to-filesystem --composefs-backend --bootloader systemd -- /data/host

virt-install:
	sudo virt-install \
		--name arch-bootc \
		--cpu host \
		--vcpus 6 \
		--memory 7920 \
		--import --disk ./bootable.img \
		--boot uefi \
		--noreboot \
		--noautoconsole \
		--os-variant archlinux \
		--network network=default
