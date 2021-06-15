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
libs += boot2 misc2 core dupli core2 core3 spl-core3
libs += core4 misc3

installed := $(bins:%=$(bin)/%) $(libs:%=$(lib)/%.sh)

$(bin)/%: %.sh; install $< $@
$(lib)/%: % | $(lib); install $< $@
$(lib):; mkdir -p $@

install: phony $(installed)

ifeq ($(and $(filter diff/%,$(MAKECMDGOALS)),T),T)
date != date +%s
date.first := 0000000000
date.pat := [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]
endif
diff/%: phony | .diff/%; @try $(@F) > $|/$(date); ls $| | tail -2 | (cd $|; xargs diff || ls | tail -1 | xargs rm)
diff/%/clear: phony; @rm -f .$(@D)/$(date.pat); test -d .$(@D) && rmdir .$(@D) || true
.diff/%:; @test -f $(@F).sh && (mkdir -p $@; try $(@F) > $@/$(date.first))
.PRECIOUS: .diff/%

once: phony; grep -q .diff .git/info/exclude || echo .diff >> .git/info/exclude

main: phony install
