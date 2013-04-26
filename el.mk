SRC_DIR=src
BUILD_DIR=lib
TMP_DIR=tmp

TAG=${shell git describe --abbrev=0}
REV=${shell git describe --long | sed -E 's/([^\-]*)\-([0-9]+).*/\2/'}
VERSION=${TAG}.${REV}
YEAR=${shell date +"%Y"}
VERSIONED_FILES=${shell cd src && ls *.el}
COMMENTARY_FILE=README.md
TEST_FILE=test/${PROJECT_LCNAME}-test-main.el

all: build-cleanup

.PHONY : setup clean version carton rename-package commentary test build release

release: test
	@echo "Committing"
	@git add . && git commit -a -m "${VERSION}"

setup:
	@echo "Copying src to tmp"
	@`cp -R ${SRC_DIR} ${TMP_DIR}`

clean:
	@`rm -Rf tmp`
	@`rm lib/commentary`
	@`rm lib/Carton`	

build-cleanup: build
	@echo "Removing tmp and unused build files"
	@`rm -Rf tmp`
	@`rm lib/commentary`
	@`rm lib/Carton`

version: setup carton
	@for FILE in ${VERSIONED_FILES}; do \
	echo "Setting version number ${VERSION} and year ${YEAR} in ${SRC_DIR}/$$FILE"; \
	sed -e 's/@VERSION/${VERSION}/g' -e 's/@YEAR/${YEAR}/g' ${SRC_DIR}/$$FILE > ${TMP_DIR}/$$FILE; \
	done

carton:
	@echo "Creating pkg file"
	@`cd src && carton package`

rename-package: setup carton version
	@echo "Renaming tmp/src-pkg.el to tmp/${PROJECT_LCNAME}-pkg.el"
	@`mv -f ${TMP_DIR}/src-pkg.el ${TMP_DIR}/${PROJECT_LCNAME}-pkg.el`

commentary: setup
	@echo "Inserting commentary"
	@sed 's/^/;; /' ${COMMENTARY_FILE} > ${TMP_DIR}/commentary
	@sed -e '/@COMMENTARY/r ${TMP_DIR}/commentary' -e '//d' ${TMP_DIR}/${PROJECT_LCNAME}.el > ${TMP_DIR}/${PROJECT_LCNAME}_commented.el
	@mv ${TMP_DIR}/${PROJECT_LCNAME}_commented.el ${TMP_DIR}/${PROJECT_LCNAME}.el

test: build-cleanup
	@`emacs -batch -l ert -l ${TEST_FILE} -f ert-run-tests-batch-and-exit`

build: setup rename-package commentary
	@`cp tmp/* lib/`
