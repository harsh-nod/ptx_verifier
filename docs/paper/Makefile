BUILD_DIR ?= /tmp/volta-amd-paper
PDFLATEX ?= pdflatex

.PHONY: all
all: amd-volta.pdf

amd-volta.pdf: amd-volta.tex
	mkdir -p "$(BUILD_DIR)"
	$(PDFLATEX) -interaction=nonstopmode -halt-on-error -file-line-error -output-directory="$(BUILD_DIR)" amd-volta.tex
	$(PDFLATEX) -interaction=nonstopmode -halt-on-error -file-line-error -output-directory="$(BUILD_DIR)" amd-volta.tex
	cp "$(BUILD_DIR)/amd-volta.pdf" "$@"
