.PHONY: all
all: bundles/bashLib

.PHONY: test
test: bundles/bashTest
	@prove -v tests/test-dotploy.sh

.PHONY: clean
clean:
	@rm -f dotploy && rm -rf bundles

bundles:
	@mkdir -p bundles

bundles/bashLib: bundles
	@if [ -d bundles/bashLib ]; \
	 then \
	    ( cd bundles/bashLib; git pull ); \
	 else \
	     git clone https://github.com/techlivezheng/bashLib.git bundles/bashLib; \
	 fi

bundles/bashTest: bundles/bashLib
	@if [ -d bundles/bashTest ]; \
	 then \
	    ( cd bundles/bashTest; git pull ); \
	 else \
	     git clone https://github.com/techlivezheng/bashTest.git bundles/bashTest; \
	 fi
