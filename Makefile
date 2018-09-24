.PHONY: test install-dev

test: test/vim-themis
	test/vim-themis/bin/themis --reporter dot test


test/vim-themis:
	git clone git://github.com/thinca/vim-themis test/vim-themis
