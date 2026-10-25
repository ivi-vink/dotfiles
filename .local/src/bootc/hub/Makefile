# Build the AlmaLinux-based "hub" bootc image and a bootable qcow2.
#
# Run from this directory (or: make -C .local/src/bootc/hub <target>):
#   make		       (default) encrypt secrets.yaml with sops + gpg
#   make build	       build the bootable container image
#   make qcow2	       build output/hub.qcow2 from the container image
#   make virt-install  boot the qcow2 in a local libvirt/KVM VM
#   make portforward   forward localhost:80/443 to the VM's Traefik over SSH
#   make trust-cert    trust the VM's Traefik root certificate on macOS
#   make run           run the image as a container with podman, host network
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

# --- Port forwarding --------------------------------------------------------
# The VM's Traefik listens on its own localhost:80 and localhost:443. ssh
# forwards those to unprivileged ports here; on macOS pf redirects the
# privileged ports 80/443 on loopback to them (see portforward below).
# Without VM_HOST, ask libvirt for the address of the VM created above;
# override it when virsh cannot find the VM, e.g.
#   make portforward VM_HOST=192.168.122.42 VM_USER=root
VM_NAME ?= $(IMAGE_NAME)-bootc
VM_USER ?= ivi
VM_HOST ?= $(shell virsh -q domifaddr $(VM_NAME) 2>/dev/null | awk '$$3 == "ipv4" { sub(/\/.*/, "", $$4); print $$4; exit }')
SSH	 ?= ssh
SSH_DEST ?= $(VM_USER)@$(VM_HOST)
PORT_HTTP  ?= 8080
PORT_HTTPS ?= 8443
PF_ANCHOR  ?= com.apple/local-dev.local.localhost

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
# /etc/traefik/certs/. root.crt is the certificate clients must trust. It
# must be an end-entity certificate (CA:FALSE): browsers reject a CA
# certificate served as the server certificate once it is trusted as a root.
CERT_DIR    ?= rootfs/etc/traefik/certs
CERT_DOMAIN ?= local.localhost
# Where CERT_DIR ends up inside the built image (and thus on the VM): the
# Containerfile installs the rootfs tree at /.
VM_CERT_DIR ?= $(CERT_DIR:rootfs%=%)
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
		-addext "subjectAltName=DNS:$(CERT_DOMAIN),DNS:*.$(CERT_DOMAIN)" \
		-addext "basicConstraints=critical,CA:FALSE" \
		-addext "keyUsage=critical,digitalSignature,keyEncipherment" \
		-addext "extendedKeyUsage=serverAuth"
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

# Run the container image directly with podman and host networking, as an
# alternative to virt-install + portforward: Traefik binds to this host's
# localhost:80/443 and Radicale to localhost:5232, so no SSH forwarding is
# needed. The bootc image starts systemd as PID 1, which podman handles
# automatically. This is a VM image, so its services ship systemd sandboxing
# (PrivateDevices, ProtectKernel*, ...) that expects the capabilities of a
# booted VM; grant them instead of weakening the units. On SELinux hosts the
# container label must be disabled too, or mount namespaces are denied.
# Uses the existing image (no rebuild); Ctrl-C stops it.
RUN_FLAGS   ?=
RUN_CAPS    ?= SYS_ADMIN
RUN_SECOPTS ?= label=disable
run:
	$(PODMAN) run --rm --network host $(addprefix --cap-add ,$(RUN_CAPS)) \
		$(addprefix --security-opt ,$(RUN_SECOPTS)) \
		--name $(IMAGE_NAME) $(RUN_FLAGS) $(IMAGE_NAME):$(IMAGE_TAG)

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

# Forward the VM's localhost:80 and localhost:443 to this machine, so that
# http://localhost and https://localhost reach Traefik. ssh listens on the
# unprivileged PORT_HTTP/PORT_HTTPS; on macOS pf redirects ports 80/443 on lo0
# to those ports, which needs sudo. Runs in the foreground; Ctrl-C stops
# forwarding (the pf rules stay loaded).
portforward:
	@test -n "$(VM_HOST)" || { \
		echo "portforward: no VM address; set VM_HOST=host (or VM_NAME=<domain>)" >&2; \
		exit 1; \
	}
ifeq ($(shell uname -s),Darwin)
	@sudo pfctl -e 2>/dev/null || true
	@printf '%s\n' \
		'rdr pass on lo0 proto tcp from any to any port 80 -> 127.0.0.1 port $(PORT_HTTP)' \
		'rdr pass on lo0 proto tcp from any to any port 443 -> 127.0.0.1 port $(PORT_HTTPS)' | \
		sudo pfctl -a '$(PF_ANCHOR)' -f -
else
	@echo "portforward: not macOS, skipping pf; forwarding on :$(PORT_HTTP) and :$(PORT_HTTPS)" >&2
endif
	@echo "http://localhost  -> $(SSH_DEST):80  (local :$(PORT_HTTP))"
	@echo "https://localhost -> $(SSH_DEST):443 (local :$(PORT_HTTPS))"
	$(SSH) -N -o ExitOnForwardFailure=yes \
		-L $(PORT_HTTP):localhost:80 \
		-L $(PORT_HTTPS):localhost:443 \
		$(SSH_DEST)

# Fetch the VM's Traefik root certificate over SSH and trust it as a root in
# the macOS System keychain (bin/trust-cert does the keychain work), so
# browsers and curl accept https://localhost and https://*.$(CERT_DOMAIN)
# served by portforward above. macOS-only; prompts for sudo. Undo by deleting
# the certificate in Keychain Access.
trust-cert:
	@test -n "$(VM_HOST)" || { \
		echo "trust-cert: no VM address; set VM_HOST=host (or VM_NAME=<domain>)" >&2; \
		exit 1; \
	}
ifeq ($(shell uname -s),Darwin)
	@tmp=$$(mktemp -t traefik-root) && trap 'rm -f "$$tmp"' EXIT; \
	$(SSH) $(SSH_DEST) cat $(CERT_DIR)/root.crt > "$$tmp" && \
	bin/trust-cert "$$tmp"
else
	@echo "trust-cert: not macOS, skipping keychain import" >&2
endif

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

# --- SOPS -------------------------------------------------------------------
# Encrypt secrets.yaml (relative to this hub directory) in place with a PGP
# identity, so only holders of that key can decrypt it (sops wraps the file's
# key with the PGP key):
#   make SOPS_PGP_FP=<fingerprint>
#   make SOPS_PGP_FP=<fingerprint> FILE=path/to/secrets.yaml
# Get the fingerprint with: gpg --list-secret-keys
# https://getsops.io/docs/usage/identities/pgp/
SOPS_PGP_FP ?= 2DC703F3C6A10B29FA5FF66A086EBC0D7040B10B
FILE	    ?= secrets.yaml

.PHONY: secrets
secrets:
	@command -v sops >/dev/null 2>&1 || { \
		echo "secrets: sops is not installed" >&2; \
		exit 1; \
	}
	@test -n "$(SOPS_PGP_FP)" || { \
		echo "secrets: set SOPS_PGP_FP (fingerprint from 'gpg --list-secret-keys')" >&2; \
		exit 1; \
	}
	@test -n "$(FILE)" || { \
		echo "secrets: set FILE (e.g. make SOPS_PGP_FP=<fp> FILE=secrets.yaml)" >&2; \
		exit 1; \
	}
	sops --encrypt --pgp "$(SOPS_PGP_FP)" --in-place "$(FILE)"

clean:
	rm -rf $(OUTPUT_DIR)
