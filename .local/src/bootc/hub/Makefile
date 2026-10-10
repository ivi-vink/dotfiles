# Build the AlmaLinux-based "hub" bootc image and a bootable qcow2.
#
# Run from this directory (or: make -C .local/src/bootc/hub <target>):
#   make build         build the bootable container image
#   make qcow2         build output/hub.qcow2 from the container image
#   make virt-install  boot the qcow2 in a local libvirt/KVM VM
#   make clean         remove build output
#
# Override any variable on the command line, e.g.
#   make PODMAN='sudo podman' qcow2

# --- Image ------------------------------------------------------------------
IMAGE_NAME ?= hub
IMAGE_TAG  ?= latest
# Fully-qualified ref image-builder uses to find the image in local storage.
IMAGE_REF  ?= localhost/$(IMAGE_NAME):$(IMAGE_TAG)

# Container build platform and the disk image's target architecture.
# image-builder uses osbuild arch names: x86_64, aarch64, s390x, ...
PLATFORM ?= linux/amd64
ARCH     ?= x86_64

# --- Container runtime ------------------------------------------------------
PODMAN             ?= podman
CONTAINERS_STORAGE ?= /var/lib/containers/storage

# --- image-builder ----------------------------------------------------------
# The osbuild image-builder container (bootc-image-builder's successor).
# ghcr.io/osbuild/image-builder-cli is an alias for the same image.
IMAGE_BUILDER ?= ghcr.io/osbuild/image-builder:latest
OUTPUT_DIR    ?= output

# --- VM ---------------------------------------------------------------------
OS_VARIANT ?= almalinux9

.PHONY: build qcow2 virt-install clean

# Build the bootable container image everything else is derived from.
build:
	$(PODMAN) build --platform $(PLATFORM) -f Containerfile -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Turn the container image into a bootable qcow2.
# image-builder reads its config (arch, root fs, partition layout) from the
# container itself, so no extra flags are needed beyond --bootc-ref.
qcow2: build
	mkdir -p $(OUTPUT_DIR)
	$(PODMAN) run --rm --privileged --pull=newer \
		--security-opt label=type:unconfined_t \
		--volume $(CONTAINERS_STORAGE):/var/lib/containers/storage \
		--volume $(CURDIR)/$(OUTPUT_DIR):/output \
		$(IMAGE_BUILDER) \
		build \
			--bootc-ref $(IMAGE_REF) \
			--arch $(ARCH) \
			--output-dir /output \
			--output-name $(IMAGE_NAME) \
			qcow2

# Boot the built qcow2 in a local libvirt/KVM VM.
virt-install: qcow2
	sudo virt-install \
		--name $(IMAGE_NAME)-bootc \
		--cpu host \
		--vcpus 6 \
		--memory 7920 \
		--import --disk $(OUTPUT_DIR)/$(IMAGE_NAME).qcow2 \
		--boot uefi \
		--noreboot \
		--noautoconsole \
		--os-variant $(OS_VARIANT) \
		--network network=default

clean:
	rm -rf $(OUTPUT_DIR)
