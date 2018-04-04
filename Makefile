VERSION=$(shell git log --format="%H" -n 1)
ARCHIVE=distrobuilder-$(VERSION).tar

.PHONY: default check

default:
	gofmt -s -w .
	go get -t -v -d ./...
	go install -v ./...
	@echo "distrobuilder built successfully"

check: default
	go get -v -x github.com/remyoudompheng/go-misc/deadcode
	go get -v -x github.com/golang/lint/golint
	go test -v ./...
	golint -set_exit_status ./...
	deadcode ./
	go vet ./...

.PHONY: dist
dist:
	# Cleanup
	rm -Rf $(ARCHIVE).gz

	# Create build dir
	$(eval TMP := $(shell mktemp -d))
	git archive --prefix=distrobuilder-$(VERSION)/ HEAD | tar -x -C $(TMP)
	mkdir -p $(TMP)/dist/src/github.com/lxc
	ln -s ../../../../distrobuilder-$(VERSION) $(TMP)/dist/src/github.com/lxc/distrobuilder

	# Download dependencies
	cd $(TMP)/distrobuilder-$(VERSION) && GOPATH=$(TMP)/dist go get -t -v -d ./...

	# Assemble tarball
	rm $(TMP)/dist/src/github.com/lxc/distrobuilder
	ln -s ../../../../ $(TMP)/dist/src/github.com/lxc/distrobuilder
	mv $(TMP)/dist $(TMP)/distrobuilder-$(VERSION)/
	tar --exclude-vcs -C $(TMP) -zcf $(ARCHIVE).gz distrobuilder-$(VERSION)/

	# Cleanup
	rm -Rf $(TMP)
