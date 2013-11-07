.PHONY: all
all: bundles/bashLib

.PHONY: test
test: bundles/bashTest
	@prove -v tests/test-dotploy.sh

.PHONY: dev-test
dev-test:
	@prove -v tests/test-dotploy.sh

.PHONY: clean
clean:
	@rm -f dotploy && rm -rf bundles

.PHONY: standalone
standalone: dotploy

dotploy: bundles/bashLib
	@sed -e '1,/# @@BASHLIB BEGIN@@/d' -e '/# @@BASHLIB END@@/,$$d' bundles/bashLib/src/bashLib > bashLib; \
	 awk ' \
	     /# @@BASHLIB BEGIN@@/ {system("cat bashLib"); bashlib=1; next} \
	     /# @@BASHLIB END@@/ {bashlib=0; next} \
	     bashlib {next} \
	     {print} \
	 ' dotploy.sh > dotploy && rm bashLib; \
	 sed -i 's/# \(export STANDALONE=1\)/\1/g' dotploy; \
	 sed -i 's/dotploy\.sh/dotploy/g' dotploy; \
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
