SHELL := /usr/bin/env bash

VM_RUNNER     := ./result/bin/run-nixos-test-vm

VM_HOST       := 127.0.0.1
VM_SSH_PORT   := 2222
VM_USER       := fernando

VM_PID        := .vm.pid
VM_LOG        := .vm.log



.PHONY: \
	build \
	rebuild \
	vm-console \
	vm-up \
	vm-down \
	vm-restart \
	vm-status \
	vm-log \
	ssh \
	clean \
	help


## Build the NixOS VM
build:
	nix-build \
		--option extra-experimental-features 'nix-command flakes' \
		./system.nix \
		-A config.system.build.vm \
		-o result

## Force a fresh evaluation/build
rebuild:
	rm -f result
	$(MAKE) build


## Run the VM interactively using the current terminal as serial console
vm-console: build
	QEMU_OPTS='-nographic -serial mon:stdio' \
	QEMU_KERNEL_PARAMS='console=ttyS0' \
	$(VM_RUNNER)


## Start the VM in background
vm-up: build
	@if [ -f "$(VM_PID)" ] && kill -0 "$$(cat $(VM_PID))" 2>/dev/null; then \
		echo "VM is already running (PID $$(cat $(VM_PID)))"; \
		exit 1; \
	fi
	@rm -f $(VM_PID)
	@echo "Starting NixOS VM..."
	@nohup env \
		QEMU_OPTS='-nographic' \
		QEMU_KERNEL_PARAMS='console=ttyS0' \
		$(VM_RUNNER) \
		> $(VM_LOG) 2>&1 & \
	echo $$! > $(VM_PID)
	@sleep 1
	@if ! kill -0 "$$(cat $(VM_PID))" 2>/dev/null; then \
		echo "VM failed to start; inspect $(VM_LOG)" >&2; \
		rm -f $(VM_PID); \
		exit 1; \
	fi
	@echo "VM started (PID $$(cat $(VM_PID)))"
	@echo "Log: $(VM_LOG)"
	@echo "SSH: ssh -p $(VM_SSH_PORT) $(VM_USER)@$(VM_HOST)"


## Stop the background VM
vm-down:
	@if [ ! -f "$(VM_PID)" ]; then \
		echo "VM is not running"; \
		exit 0; \
	fi
	@PID="$$(cat $(VM_PID))"; \
	if kill -0 "$$PID" 2>/dev/null; then \
		echo "Stopping VM (PID $$PID)..."; \
		kill "$$PID"; \
		for _ in $$(seq 1 10); do \
			if ! kill -0 "$$PID" 2>/dev/null; then \
				break; \
			fi; \
			sleep 1; \
		done; \
		if kill -0 "$$PID" 2>/dev/null; then \
			echo "VM did not stop gracefully; forcing shutdown..."; \
			kill -9 "$$PID"; \
		fi; \
	else \
		echo "Stale PID file found"; \
	fi
	@rm -f $(VM_PID)
	@echo "VM stopped"


## Restart background VM
vm-restart: vm-down vm-up


## Show VM status
vm-status:
	@if [ -f "$(VM_PID)" ] && kill -0 "$$(cat $(VM_PID))" 2>/dev/null; then \
		echo "VM is running (PID $$(cat $(VM_PID)))"; \
	else \
		echo "VM is not running"; \
	fi


## Follow VM output
vm-log:
	@if [ ! -f "$(VM_LOG)" ]; then \
		echo "No VM log found"; \
		exit 1; \
	fi
	tail -f $(VM_LOG)


## SSH into the VM
ssh:
	ssh \
		-o IdentitiesOnly=yes \
		-o PubkeyAuthentication=no \
		-o PreferredAuthentications=password \
		-p $(VM_SSH_PORT) \
		$(VM_USER)@$(VM_HOST)


## Remove generated build/runtime files
clean:
	-$(MAKE) vm-down
	rm -f result
	rm -f $(VM_PID)
	rm -f $(VM_LOG)


## Show available commands
help:
	@echo "NixOS VM"
	@echo
	@echo "  make build        Build the NixOS VM"
	@echo "  make rebuild      Force a new evaluation/build"
	@echo
	@echo "  make vm-console   Start VM attached to the terminal"
	@echo "  make vm-up        Start VM in background"
	@echo "  make vm-down      Stop background VM"
	@echo "  make vm-restart   Restart background VM"
	@echo "  make vm-status    Show VM status"
	@echo "  make vm-log       Follow VM log"
	@echo
	@echo "  make ssh          SSH into the VM"
	@echo "  make clean        Remove generated files"
