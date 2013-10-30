BUILD_DIR=lib
TMP_DIR=tmp
SRC_FILES=${shell ls *.el}

TAG=${shell git fetch --tags && git describe --abbrev=0}
REV=${shell git rev-list ${TAG}..HEAD --count --merges}
VERSION=${TAG}.${REV}
YEAR=${shell date +"%Y"}
COMMENTARY_FILE=README.md
TEST_FILE=test/${PROJECT_LCNAME}-test-main.el

all: build-clean

.PHONY : setup clean version cask commentary test build release

setup:
	@echo "Creating ${TMP_DIR}"
	@mkdir ${TMP_DIR}
	@echo "Copying src files to tmp"
	@cp ${SRC_FILES} ${TMP_DIR}/

clean:
	@rm -Rf tmp

build-clean: build clean

version: setup cask
	@for FILE in ${SRC_FILES}; do \
	echo "Setting version number ${VERSION} and year ${YEAR} in $$FILE"; \
	sed -e 's/@VERSION/${VERSION}/g' -e 's/@YEAR/${YEAR}/g' $$FILE > ${TMP_DIR}/$$FILE; \
	done

cask:
	@echo "Creating pkg file"
	@cask package

commentary: setup
	@echo "Inserting commentary"
	@sed 's/^/;; /' ${COMMENTARY_FILE} > ${TMP_DIR}/commentary
	@sed -e '/@COMMENTARY/r ${TMP_DIR}/commentary' -e '//d' ${TMP_DIR}/${PROJECT_LCNAME}.el > ${TMP_DIR}/${PROJECT_LCNAME}_commented.el
	@mv ${TMP_DIR}/${PROJECT_LCNAME}_commented.el ${TMP_DIR}/${PROJECT_LCNAME}.el
	@rm ${TMP_DIR}/commentary

test: build-clean
	@emacs -batch -l ert -l ${TEST_FILE} -f ert-run-tests-batch-and-exit

build: setup cask version commentary
	@cp tmp/* lib/
