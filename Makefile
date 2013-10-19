.PHONY: all
all: bundles/bashLib

.PHONY: test
test: bundles/bashTest
	@prove -v tests/test-dotploy.sh

.PHONY: clean
clean:
	@rm -f dotploy && rm -rf bundles

.PHONY: standalone
standalone: dotploy

dotploy: bundles/bashLib
	@cat dotploy.sh bundles/bashLib/src/bashLib > dotploy; \
	 sed -i 's/# \(export STANDALONE=1\)/\1/g' dotploy; \
	 chmod a+x dotploy

bundles:
	@mkdir -p bundles

bundles/bashLib: bundles FORCE
	@if [ -d bundles/bashLib ]; \
	 then \
	    ( cd bundles/bashLib; git checkout master; git fetch --all --prune; git reset --hard origin/master ); \
	 else \
	     git clone https://github.com/techlivezheng/bashLib.git bundles/bashLib; \
	 fi

bundles/bashTest: bundles/bashLib FORCE
	@if [ -d bundles/bashTest ]; \
	 then \
	    ( cd bundles/bashTest; git checkout master; git fetch --all --prune; git reset --hard origin/master ); \
	 else \
	     git clone https://github.com/techlivezheng/bashTest.git bundles/bashTest; \
	 fi

FORCE:
