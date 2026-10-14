# Build the AlmaLinux-based "hub" bootc image and a bootable qcow2.
#
# Run from this directory (or: make -C .local/src/bootc/hub <target>):
#   make build	       build the bootable container image
#   make qcow2	       build output/hub.qcow2 from the container image
#   make virt-install  boot the qcow2 in a local libvirt/KVM VM
#   make install-exo   install the Exoscale CLI (exo)
#   make sos-upload    upload the qcow2 to Exoscale Object Storage, public
#   make sos-public    (re)apply a public-read ACL to the uploaded object
#   make clean	       remove build output
#
# Override any variable on the command line, e.g.
#   make PODMAN='sudo podman' qcow2
#   make SOS_BUCKET=my-bucket SOS_ZONE=de-fra-1 sos-upload

# --- Image ------------------------------------------------------------------
IMAGE_NAME ?= hub
IMAGE_TAG  ?= latest
# Fully-qualified ref image-builder uses to find the image in local storage.
IMAGE_REF  ?= localhost/$(IMAGE_NAME):$(IMAGE_TAG)

# Container build platform and the disk image's target architecture.
# image-builder uses osbuild arch names: x86_64, aarch64, s390x, ...
PLATFORM ?= linux/amd64
ARCH	 ?= x86_64

# --- Container runtime ------------------------------------------------------
PODMAN		   ?= podman
CONTAINERS_STORAGE ?= /var/lib/containers/storage

# --- image-builder ----------------------------------------------------------
# The osbuild image-builder container (bootc-image-builder's successor).
# ghcr.io/osbuild/image-builder-cli is an alias for the same image.
IMAGE_BUILDER ?= ghcr.io/osbuild/image-builder:latest
OUTPUT_DIR    ?= output

# bin/image-builder reads these from the environment (variables defined in a
# Makefile are not exported to recipes otherwise).
export PODMAN CONTAINERS_STORAGE OUTPUT_DIR IMAGE_BUILDER

# --- VM ---------------------------------------------------------------------
OS_VARIANT ?= almalinux9

# --- Exoscale CLI / Object Storage (SOS) ------------------------------------
# https://community.exoscale.com/tools/command-line-interface/
# Configure credentials once with: exo config
EXO ?= exo
# Bucket names are globally unique across the whole Exoscale platform.
SOS_BUCKET ?= $(IMAGE_NAME)-bootc
SOS_ZONE   ?= ch-gva-2
# Object key under the bucket.
SOS_OBJECT ?= $(IMAGE_NAME).qcow2
# Public URL the object is reachable at once its ACL is public-read.
SOS_URL	   ?= https://sos-$(SOS_ZONE).exo.io/$(SOS_BUCKET)/$(SOS_OBJECT)

# --- Traefik -----------------------------------------------------------------
# Self-signed wildcard certificate that Traefik serves as its default
# certificate (see rootfs/etc/traefik/config/tls.yaml). It is generated into
# the image build context, which the Containerfile installs at
# /etc/traefik/certs/. root.crt is the certificate clients must trust.
CERT_DIR    ?= rootfs/etc/traefik/certs
CERT_DOMAIN ?= local.localhost
# Validity in days. Long-lived is fine for a self-signed certificate trusted
# locally; macOS only enforces its 398-day limit on certificates issued by a
# CA in the system trust store.
CERT_DAYS   ?= 3650

# Generate root.crt and its key once. The stamp keeps later builds from
# regenerating (and thus invalidating) a certificate clients already trust;
# remove output/self-signed-cert after changing the variables above.
$(CERT_DIR):
	mkdir -p $@
	openssl req -x509 -newkey rsa:4096 -sha256 -nodes \
		-keyout $(CERT_DIR)/root.key \
		-out $(CERT_DIR)/root.crt \
		-days $(CERT_DAYS) \
		-subj "/CN=$(CERT_DOMAIN)" \
		-addext "subjectAltName=DNS:$(CERT_DOMAIN),DNS:*.$(CERT_DOMAIN)"
	chmod 600 $(CERT_DIR)/root.key

# Build the bootable container image everything else is derived from.
build: $(CERT_DIR)
	$(PODMAN) build --platform $(PLATFORM) -f Containerfile -t $(IMAGE_NAME):$(IMAGE_TAG) .

output/blueprint.toml:
	bin/blueprint > output/blueprint.toml

# Turn the container image into a bootable qcow2.
# image-builder reads its config (arch, root fs, partition layout) from the
# container itself, so no extra flags are needed beyond --bootc-ref.
qcow2: build output/blueprint.toml
	mkdir -p $(OUTPUT_DIR)
	bin/image-builder \
		build \
			--blueprint /output/blueprint.toml \
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

# Install the official Exoscale CLI. On apt/dnf-based distributions the
# installer sets up a package repository and needs root (sudo/doas); see the
# link above for other distributions and manual installation.
install-exo:
	command -v exo || curl -fsSL https://raw.githubusercontent.com/exoscale/cli/master/install-latest.sh | sh

# Create the bucket if it does not exist, upload the qcow2 and make it
# publicly readable in one step. Uses the existing output qcow2 (no rebuild).
sos-upload:
	$(EXO) storage list | grep -q '$(SOS_BUCKET)' || \
		$(EXO) storage mb sos://$(SOS_BUCKET) --zone $(SOS_ZONE)
	$(EXO) storage upload --acl public-read \
		$(OUTPUT_DIR)/$(IMAGE_NAME).qcow2 \
		sos://$(SOS_BUCKET)/$(SOS_OBJECT)
	@echo "Public URL: $(SOS_URL)"

# (Re)apply a public-read ACL to an already-uploaded object.
sos-public:
	$(EXO) storage setacl sos://$(SOS_BUCKET)/$(SOS_OBJECT) public-read

# (Re)apply a private-read ACL to an already-uploaded object.
sos-private:
	$(EXO) storage setacl sos://$(SOS_BUCKET)/$(SOS_OBJECT) private

clean:
	rm -rf $(OUTPUT_DIR)
