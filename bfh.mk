#!/usr/bin/make -f

MAKEFLAGS += -Rr --warn-undefined-variables
SHELL != which bash
.SHELLFLAGS := -euo pipefail -c

.ONESHELL:
.DELETE_ON_ERROR:
.PHONY: phony
_WS := $(or) $(or)
_comma := ,
.RECIPEPREFIX := $(_WS)
.DEFAULT_GOAL := main

self := $(lastword $(MAKEFILE_LIST))
$(self):;

name != source <(./try misc use real-file-name); real-file-name $(self) | xargs -i basename {} .mk

base := /usr/local
bin := $(base)/bin
lib := $(base)/lib/$(name)

bins := $(name)
libs := boot git-to-md misc upgrade-jessie
libs += boot2 misc2 core

installed := $(bins:%=$(bin)/%) $(libs:%=$(lib)/%.sh)

$(bin)/%: %.sh; install $< $@
$(lib)/%: % | $(lib); install $< $@
$(lib):; mkdir -p $@

install: phony $(installed)

main: phony install
